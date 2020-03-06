#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

# setup common env variables
source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/set_skit_env.sh")

# check if doi is integrated in this toolchain
if jq -e '.services[] | select(.service_id=="draservicebroker")' _toolchain.json; then
  # Record build information
  ibmcloud login --apikey ${IBM_CLOUD_API_KEY} --no-region
  ibmcloud doi publishbuildrecord --branch ${GIT_BRANCH} --repositoryurl ${GIT_URL} --commitid ${GIT_COMMIT} \
    --buildnumber ${BUILD_NUMBER} --logicalappname ${IMAGE_NAME} --status pass
fi

source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/asset_download.sh")
