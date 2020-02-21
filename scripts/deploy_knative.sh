#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

export PATH="downloads:$PATH"

echo "Check cluster availability"
IP_ADDR=$(ibmcloud cs workers ${PIPELINE_KUBERNETES_CLUSTER_NAME} | grep normal | head -n 1 | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
    echo "$PIPELINE_KUBERNETES_CLUSTER_NAME not created or workers not ready"
    exit 1
fi

# Check for installation of Knative addon
echo "Check Knative availability"
KNATIVE_INSTALLED=$(ibmcloud cs cluster addons --cluster ${PIPELINE_KUBERNETES_CLUSTER_NAME} --json | jq '.[].name?|select(. == "knative")')
if [ -z $KNATIVE_INSTALLED ]; then
    echo "Knative is required but is not installed in this cluster. Install the Knative add-on and retry. Note that the Knative add-on is not supported on lite clusters."
    exit 1
fi

KNATIVE_RUNNING=$(kubectl get pods --namespace knative-serving -o json | jq '.items|length')
if [ "0" == "$KNATIVE_RUNNING" ]; then
    echo "Knative is required but is not running in this cluster. Ensure that the cluster's workers meet the minimum requirements for Istio. Install the Knative add-on and retry. Note that the Knative add-on is not supported on lite clusters."
    exit 1
fi

echo "Configuring cluster namespace"
if kubectl get namespace ${CLUSTER_NAMESPACE}; then
  echo -e "Namespace ${CLUSTER_NAMESPACE} found."
else
  kubectl create namespace ${CLUSTER_NAMESPACE}
  echo -e "Namespace ${CLUSTER_NAMESPACE} created."
fi

echo "Configuring cluster role binding"
if kubectl get clusterrolebinding kube-system:default; then
  echo -e "Cluster role binding found."
else
  kubectl create clusterrolebinding kube-system:default --clusterrole=cluster-admin --serviceaccount=kube-system:default
  echo -e "Cluster role binding created."
fi

# Update service.yaml with service and image name
echo "=========================================================="
echo "CHECKING SERVICE.YAML manifest"
if [ ! -f ${SERVICE_FILE} ]; then
  echo -e "Knative service file '${SERVICE_FILE}' not found. Ensure a Knative service definition file named '${SERVICE_FILE}' is located at the project's root directory. Alternatively, change the SERVICE_FILE environment property in the Deploy stage configuration."
  exit 1
fi
# Get kube service name from metadata name in service file
export KUBE_SERVICE_NAME=$(yq read $SERVICE_FILE metadata.name)
if [ "$KUBE_SERVICE_NAME" == "null" ]; then
    echo "ERROR: no service name found in service file, $SERVICE_FILE"
    exit 1
fi

echo "UPDATING service manifest with image information"
echo "${SERVICE_FILE_UPDATE_INSTRUCTIONS}" | sed -e "s/REGISTRY_URL/${REGISTRY_URL}/g" -e "s/REGISTRY_NAMESPACE/${REGISTRY_NAMESPACE}/g" -e "s/IMAGE_NAME/${IMAGE_NAME}/g" -e "s/BUILD_NUMBER/${BUILD_NUMBER}/g" > ${SERVICE_FILE_UPDATE_INSTRUCTIONS_FILE}
echo "Service file update instructions:"
cat ${SERVICE_FILE_UPDATE_INSTRUCTIONS_FILE}
IMAGE_REPOSITORY=${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}
echo -e "Updating ${SERVICE_FILE} with image name: ${IMAGE_REPOSITORY}"
UPDATED_SERVICE_FILE=tmp.${SERVICE_FILE}
yq write --doc 0 -s ${SERVICE_FILE_UPDATE_INSTRUCTIONS_FILE} ${SERVICE_FILE} > ${UPDATED_SERVICE_FILE}

# Deploy the most recent revision of the specified image as specified in the updated service file
echo "=========================================================="
cat ${UPDATED_SERVICE_FILE}
echo "Deploying Knative service..."
kubectl apply -f ${UPDATED_SERVICE_FILE}


echo "Checking if application is ready..."
for ITERATION in {1..30}
do
  sleep 3

  kubectl get ksvc/${KUBE_SERVICE_NAME} --output=custom-columns=DOMAIN:.status.conditions[*].status
  SVC_STATUS_READY=$( kubectl get ksvc/${KUBE_SERVICE_NAME} -o json | jq '.status?.conditions[]?.status?|select(. == "True")' )
  echo SVC_STATUS_READY=$SVC_STATUS_READY

  SVC_STATUS_NOT_READY=$( kubectl get ksvc/${KUBE_SERVICE_NAME} -o json | jq '.status?.conditions[]?.status?|select(. == "False")' )
  echo SVC_STATUS_NOT_READY=$SVC_STATUS_NOT_READY

  SVC_STATUS_UNKNOWN=$( kubectl get ksvc/${KUBE_SERVICE_NAME} -o json | jq '.status?.conditions[]?.status?|select(. == "Unknown")' )
  echo SVC_STATUS_UNKNOWN=$SVC_STATUS_UNKNOWN

  if [ \( -n "$SVC_STATUS_NOT_READY" \) -o \( -n "$SVC_STATUS_UNKNOWN" \) ]; then
    echo "Application not ready, retrying"
  elif [ -n "$SVC_STATUS_READY" ]; then
    echo "Application is ready"
    break
  else
    echo "Application status unknown, retrying"
  fi
done
echo "Application service details:"
kubectl describe ksvc/${KUBE_SERVICE_NAME}
if [ \( -n "$SVC_STATUS_NOT_READY" \) -o \( -n "$SVC_STATUS_UNKNOWN" \) ]; then
  echo "Application is not ready after waiting maximum time"
  exit 1
fi

# Determine app url for polling from knative service
TEMP_URL=$( kubectl get ksvc/${KUBE_SERVICE_NAME} -o json | jq '.status.url' )
echo "Application status URL: $TEMP_URL"
TEMP_URL=${TEMP_URL%\"} # remove end quote
TEMP_URL=${TEMP_URL#\"} # remove beginning quote
export APPLICATION_URL=$TEMP_URL
echo "Checking app @ $APPLICATION_URL..."
if [ -z "$APPLICATION_URL" ]; then
  echo "Deploy failed, no URL found for knative service"
  exit 1
fi
echo "Application is available"
echo "=========================================================="
echo -e "View the application at: $APPLICATION_URL"
export APP_URL=$APPLICATION_URL
echo "APP_URL=${APP_URL}" >> $ARCHIVE_DIR/build.properties

echo "export IP_ADDR=${IP_ADDR}" >> kube_vars.sh
echo "export PORT=${PORT}" >> kube_vars.sh

# copy build props to root dir build props
cat $ARCHIVE_DIR/build.properties >> ./build.properties
