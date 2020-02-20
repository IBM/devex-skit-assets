#!/bin/bash

# uncomment to debug the script
# set -x

ls -al

# copy the script below into your app code repo (e.g. ./scripts/check_and_deploy_helm.sh) and 'source' it from your pipeline job
#    source ./scripts/check_and_deploy_helm.sh
# alternatively, you can source it from online script:
#    source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/check_and_deploy_helm.sh")
# ------------------
# source: https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/check_and_deploy_helm.sh

# This script checks the IBM Container Service cluster is ready, has a namespace configured with access to the private
# image registry (using an IBM Cloud API Key), perform a Helm deploy of container image and check on outcome.
source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/check_and_deploy_helm.sh")

echo "APP_URL=${APP_URL}" >> $ARCHIVE_DIR/build.properties
