#!/bin/bash
# set -x

# Input env variables (can be received via a pipeline environment properties.file.
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "IMAGE_TAG=${IMAGE_TAG}"
echo "CHART_ROOT=${CHART_ROOT}"
echo "CHART_NAME=${CHART_NAME}"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "DEPLOYMENT_FILE=${DEPLOYMENT_FILE}"
echo "USE_ISTIO_GATEWAY=${USE_ISTIO_GATEWAY}"
echo "HELM_VERSION=${HELM_VERSION}"
echo "KUBERNETES_SERVICE_ACCOUNT_NAME=${KUBERNETES_SERVICE_ACCOUNT_NAME}"

echo "Use for custom Kubernetes cluster target:"
echo "KUBERNETES_MASTER_ADDRESS=${KUBERNETES_MASTER_ADDRESS}"
echo "KUBERNETES_MASTER_PORT=${KUBERNETES_MASTER_PORT}"
echo "KUBERNETES_SERVICE_ACCOUNT_TOKEN=${KUBERNETES_SERVICE_ACCOUNT_TOKEN}"

# Input env variables from pipeline job
echo "PIPELINE_KUBERNETES_CLUSTER_NAME=${PIPELINE_KUBERNETES_CLUSTER_NAME}"
echo "CLUSTER_NAMESPACE=${CLUSTER_NAMESPACE}

echo "=========================================================="
echo "FINDING HELM CHART"
if [ -z "${CHART_ROOT}" ]; then CHART_ROOT="chart" ; fi
if [ -d ${CHART_ROOT} ]; then
  echo -e "Looking for chart under /${CHART_ROOT}/<CHART_NAME>"
  CHART_NAME=$(find ${CHART_ROOT}/. -maxdepth 2 -type d -name '[^.]?*' -printf %f -quit)
  CHART_PATH=${CHART_ROOT}/${CHART_NAME}
fi
if [ -z "${CHART_PATH}" ]; then
    echo -e "No Helm chart found for Kubernetes deployment under ${CHART_ROOT}/<CHART_NAME>."
    exit 1
else
    echo -e "Helm chart found for Kubernetes deployment : ${CHART_PATH}"
fi

#Check cluster availability
echo "=========================================================="
echo "CHECKING CLUSTER readiness and namespace existence"
if [ -z "${KUBERNETES_MASTER_ADDRESS}" ]; then
  IP_ADDR=$( ibmcloud cs workers ${PIPELINE_KUBERNETES_CLUSTER_NAME} | grep normal | head -n 1 | awk '{ print $2 }' )
  if [ -z "${IP_ADDR}" ]; then
    echo -e "${PIPELINE_KUBERNETES_CLUSTER_NAME} not created or workers not ready"
    exit 1
  fi
fi

echo "=========================================================="
if [ -z "$RELEASE_NAME" ]; then
  echo "DEFINE RELEASE by prefixing image (app) name with namespace if not 'default' as Helm needs unique release names across namespaces"
  if [[ "${CLUSTER_NAMESPACE}" != "default" ]]; then
    RELEASE_NAME="${CLUSTER_NAMESPACE}-${IMAGE_NAME}"
  else
    RELEASE_NAME=${IMAGE_NAME}
  fi
fi
echo -e "Release name: ${RELEASE_NAME}"

# Extract app name from helm release
echo "=========================================================="
APP_NAME=$( helm get ${HELM_TLS_OPTION} ${RELEASE_NAME} | yq read -d'*' --tojson - | jq -r | jq -r --arg image "$IMAGE_REPOSITORY:$IMAGE_TAG" '.[] | select (.kind=="Deployment") | . as $adeployment | .spec?.template?.spec?.containers[]? | select (.image==$image) | $adeployment.metadata.labels.app' )
echo -e "APP: ${APP_NAME}"
echo "DEPLOYED PODS:"
kubectl describe pods --selector app=${APP_NAME} --namespace ${CLUSTER_NAMESPACE}

# lookup service for current release
APP_SERVICE=$(kubectl get services --namespace ${CLUSTER_NAMESPACE} -o json | jq -r ' .items[] | select (.spec.selector.release=="'"${RELEASE_NAME}"'") | .metadata.name ')
if [ -z "${APP_SERVICE}" ]; then
  # lookup service for current app
  APP_SERVICE=$(kubectl get services --namespace ${CLUSTER_NAMESPACE} -o json | jq -r ' .items[] | select (.spec.selector.app=="'"${APP_NAME}"'") | .metadata.name ')
fi
if [ ! -z "${APP_SERVICE}" ]; then
  echo -e "SERVICE: ${APP_SERVICE}"
  echo "DEPLOYED SERVICES:"
  kubectl describe services ${APP_SERVICE} --namespace ${CLUSTER_NAMESPACE}
fi

if [ ! -z "${APP_SERVICE}" ]; then
  echo ""
  if [ "${USE_ISTIO_GATEWAY}" = true ]; then
    PORT=$( kubectl get svc istio-ingressgateway -n istio-system -o json | jq -r '.spec.ports[] | select (.name=="http2") | .nodePort ' )
    echo -e "*** istio gateway enabled ***"
  else
    PORT=$( kubectl get services --namespace ${CLUSTER_NAMESPACE} | grep ${APP_SERVICE} | sed 's/.*:\([0-9]*\).*/\1/g' )
  fi
  if [ -z "${KUBERNETES_MASTER_ADDRESS}" ]; then
    echo "Using first worker node ip address as NodeIP: ${IP_ADDR}"
  else 
    # check if a route resource exists in the this kubernetes cluster
    if kubectl explain route > /dev/null 2>&1; then
      # Assuming the kubernetes target cluster is an openshift cluster
      # Check if a route exists for exposing the service ${APP_SERVICE}
      if  kubectl get routes --namespace ${CLUSTER_NAMESPACE} -o json | jq --arg service "$APP_SERVICE" -e '.items[] | select(.spec.to.name==$service)'; then
        echo "Existing route to expose service $APP_SERVICE"
      else
        # create OpenShift route
cat > test-route.json << EOF
{"apiVersion":"route.openshift.io/v1","kind":"Route","metadata":{"name":"${APP_SERVICE}"},"spec":{"to":{"kind":"Service","name":"${APP_SERVICE}"}}}
EOF
        echo ""
        cat test-route.json
        kubectl apply -f test-route.json --validate=false --namespace ${CLUSTER_NAMESPACE}
        kubectl get routes --namespace ${CLUSTER_NAMESPACE}
      fi
      echo "LOOKING for host in route exposing service $APP_SERVICE"
      IP_ADDR=$(kubectl get routes --namespace ${CLUSTER_NAMESPACE} -o json | jq --arg service "$APP_SERVICE" -r '.items[] | select(.spec.to.name==$service) | .status.ingress[0].host')
      PORT=80
    else
      # Use the KUBERNETES_MASTER_ADRESS
      IP_ADDR=${KUBERNETES_MASTER_ADDRESS}
    fi
  fi  
  export APP_URL=http://${IP_ADDR}:${PORT}
fi
