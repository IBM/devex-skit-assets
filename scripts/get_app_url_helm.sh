#!/bin/bash
# set -x

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
