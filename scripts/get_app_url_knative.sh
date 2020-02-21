#!/bin/bash
# set -x

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

TEMP_URL=$( kubectl get ksvc/${KUBE_SERVICE_NAME} -o json | jq '.status.url' )
echo "Application status URL: $TEMP_URL"
TEMP_URL=${TEMP_URL%\"} # remove end quote
TEMP_URL=${TEMP_URL#\"} # remove beginning quote
export APP_URL=$TEMP_URL

