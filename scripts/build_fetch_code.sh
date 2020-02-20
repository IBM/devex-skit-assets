#!/bin/bash
set -x

# Git repo cloned at $WORKING_DIR, copy into $ARCHIVE_DIR
mkdir -p $ARCHIVE_DIR
cp -R -n ./ $ARCHIVE_DIR/ || true

# Record git info
echo "GIT_URL=${GIT_URL}" >> $ARCHIVE_DIR/build.properties
echo "GIT_BRANCH=${GIT_BRANCH}" >> $ARCHIVE_DIR/build.properties
echo "GIT_COMMIT=${GIT_COMMIT}" >> $ARCHIVE_DIR/build.properties
echo "SOURCE_BUILD_NUMBER=${BUILD_NUMBER}" >> $ARCHIVE_DIR/build.properties
# these are defined as environment properties in the stage configuration
echo "DEVX_SKIT_ASSETS_GIT=${DEVX_SKIT_ASSETS_GIT}" >> $ARCHIVE_DIR/build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL=${DEVX_SKIT_ASSETS_GIT_URL}" >> $ARCHIVE_DIR/build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL_RAW=${DEVX_SKIT_ASSETS_GIT_URL_RAW}" >> $ARCHIVE_DIR/build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL_CODE=${DEVX_SKIT_ASSETS_GIT_URL_CODE}" >> $ARCHIVE_DIR/build.properties
echo "DEPLOY_TARGET=${DEPLOY_TARGET}" >> $ARCHIVE_DIR/build.properties

echo "File 'build.properties' created for passing env variables to subsequent pipeline jobs:"
cat $ARCHIVE_DIR/build.properties

# check if doi is integrated in this toolchain
if jq -e '.services[] | select(.service_id=="draservicebroker")' _toolchain.json; then
  # Record build information
  ibmcloud login --apikey ${IBM_CLOUD_API_KEY} --no-region
  ibmcloud doi publishbuildrecord --branch ${GIT_BRANCH} --repositoryurl ${GIT_URL} --commitid ${GIT_COMMIT} \
    --buildnumber ${BUILD_NUMBER} --logicalappname ${IMAGE_NAME} --status pass
fi

source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/asset_download.sh")
