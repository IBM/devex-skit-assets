#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

mkdir downloads
PATH="downloads:$PATH"
echo "kubectl version"
kubectl version --client

# setup common env variables
source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/$DEVX_SKIT_ASSETS_VERSION/set_skit_env.sh")

source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/$DEVX_SKIT_ASSETS_VERSION/asset_download.sh")

# Record git info
export IMAGE_NAME=${APP_NAME}-monitored-knative
echo "Build environment variables:"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "ARCHIVE_DIR=${ARCHIVE_DIR}"
echo "APP_PORT=${APP_PORT}"

# also run 'env' command to find all available env variables
# or learn more about the available environment variables at:
# https://cloud.ibm.com/docs/services/ContinuousDelivery/pipeline_deploy_var.html#deliverypipeline_environment

# To review or change build options use:
# ibmcloud cr build --help

echo "Checking registry namespace: ${REGISTRY_NAMESPACE}"
NS=$( ibmcloud cr namespaces | grep ${REGISTRY_NAMESPACE} ||: )
if [ -z "${NS}" ]; then
    echo -e "Registry namespace ${REGISTRY_NAMESPACE} not found, creating it."
    ibmcloud cr namespace-add ${REGISTRY_NAMESPACE}
    echo -e "Registry namespace ${REGISTRY_NAMESPACE} created."
else
    echo -e "Registry namespace ${REGISTRY_NAMESPACE} found."
fi

echo -e "Existing images in registry"

echo "=========================================================="
echo -e "BUILDING CONTAINER IMAGE: ${IMAGE_NAME}:${BUILD_NUMBER}"
set -x
ibmcloud cr build -t ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${BUILD_NUMBER} .
ibmcloud cr image-tag ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${BUILD_NUMBER} \
    ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:latest

set +x
ibmcloud cr image-inspect ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${BUILD_NUMBER}

export PIPELINE_IMAGE_URL="$REGISTRY_URL/$REGISTRY_NAMESPACE/$IMAGE_NAME:$BUILD_NUMBER"

echo "=========================================================="
echo "COPYING ARTIFACTS needed for deployment and testing (in particular build.properties)"

# Persist env variables into a properties file (build.properties) so that all pipeline stages consuming this
# build as input and configured with an environment properties file valued 'build.properties'
# will be able to reuse the env variables in their job shell scripts.

# IMAGE information from build.properties is used in Helm Chart deployment to set the release name
echo "SOURCE_BUILD_NUMBER=${BUILD_NUMBER}" >> $ARCHIVE_DIR/build.properties
echo "IMAGE_NAME=${IMAGE_NAME}" >> $ARCHIVE_DIR/build.properties
echo "BUILD_NUMBER=${BUILD_NUMBER}" >> $ARCHIVE_DIR/build.properties
# REGISTRY information from build.properties is used in Helm Chart deployment to generate cluster secret
echo "REGISTRY_URL=${REGISTRY_URL}" >> $ARCHIVE_DIR/build.properties
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}" >> $ARCHIVE_DIR/build.properties
echo "APP_PORT=${APP_PORT}" >> $ARCHIVE_DIR/build.properties
# these are defined as environment properties in the stage configuration
echo "DEVX_SKIT_ASSETS_GIT=${DEVX_SKIT_ASSETS_GIT}" >> $ARCHIVE_DIR/build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL=${DEVX_SKIT_ASSETS_GIT_URL}" >> $ARCHIVE_DIR/build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL_RAW=${DEVX_SKIT_ASSETS_GIT_URL_RAW}" >> $ARCHIVE_DIR/build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL_CODE=${DEVX_SKIT_ASSETS_GIT_URL_CODE}" >> $ARCHIVE_DIR/build.properties

echo "File 'build.properties' created for passing env variables to subsequent pipeline jobs:"
cat $ARCHIVE_DIR/build.properties | grep -v -i password

echo "Copy pipeline scripts along with the build"
# Copy scripts (incl. deploy scripts)
if [ -d ./scripts/ ]; then
  if [ ! -d $ARCHIVE_DIR/scripts/ ]; then # no need to copy if working in ./ already
    cp -r ./scripts/ $ARCHIVE_DIR/
  fi
fi

if  [[ -f post_build.sh ]]; then
  chmod +x post_build.sh;
  echo "executing the post_build script";
  sh post_build.sh;
else
  echo "the post_build script does not exist";
fi
