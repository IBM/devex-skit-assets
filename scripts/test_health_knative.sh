export PATH="downloads:$PATH"

echo "Listing all Knative services..."
kubectl get ksvc

export KUBE_SERVICE_NAME=$(yq read $SERVICE_FILE metadata.name)

kubectl get ksvc/${KUBE_SERVICE_NAME} -o json | jq '.status.url'
TEMP_URL=$( kubectl get ksvc/${KUBE_SERVICE_NAME} -o json | jq '.status.url' )
TEMP_URL=${TEMP_URL%\"} # remove end quote
TEMP_URL=${TEMP_URL#\"} # remove beginning quote
export APPLICATION_URL=$TEMP_URL
echo "Checking app @ $APPLICATION_URL..."

if [ "$(curl -is $APPLICATION_URL --connect-timeout 3 --max-time 5 --retry 2 --retry-max-time 30 | head -n 1 | grep 200)" != "" ]; then
  echo "Successfully reached health endpoint at $APPLICATION_URL"
  echo "====================================================================="
elif [ "$(curl -is "$APPLICATION_URL/health" --connect-timeout 3 --max-time 5 --retry 2 --retry-max-time 30 | head -n 1 | grep 200)" != "" ]; then
  echo "Successfully reached health endpoint at $APPLICATION_URL/health"
  echo "====================================================================="
else
  echo "Could not reach health endpoint: $APPLICATION_URL"
  exit 1;
fi;
