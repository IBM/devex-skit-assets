#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

# This script expects the GIT_URL env var to contain the URL to the skit git repo,
# from which the deployment assets folder will be extracted.

echo "Directory * "
pwd
echo "ls -al *"
ls -al

# expected URL structure: https://github.com/<org>/<skit-name>.git
export SKIT_NAME=(${GIT_URL##*/})
export SKIT_URL=(${GIT_URL%%.git}) # strips .git off the end
export SKIT_NAME=(${SKIT_NAME%%.*})
export APP_NAME=${SKIT_NAME}
export DEVX_GIT_REPO_NAME=devex-skit-assets

echo "Fetching deployment assets for skit ${SKIT_NAME}"
# directory structure: REPO/deployment-assets/<skit-name>/<deploy-target>
# can't seem to find an easy way to d/l a specific folder, so need to get the whole repo
curl $DEVX_SKIT_ASSETS_GIT_URL_CODE | tar -xz
ls -al
ls -al ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}

#if [ "${DEPLOY_TARGET}" == "helm" ]; then
#    mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET} ./chart;
#fi

#if [ "${DEPLOY_TARGET}" == "knative" ]; then
#    mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/service.yaml ./;
#fi

#if [ "${DEPLOY_TARGET}" == "cf" ]; then
#    mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/manifest.yaml ./;
#fi

case "$DEPLOY_TARGET" in
    helm) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET} ./chart
    ;;
    cf) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/manifest.yaml ./
    ;;
    knative) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/service.yaml ./
    ;;
    *) echo "FAILED TO PLACE helm chart, manifest.yaml, or service.yaml"
       exit 1
esac

if [ -f "${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json" ]; then
    # TODO determine target dir based on platform/language
    platform=$(curl --silent "https://cloud.ibm.com/developer/api/applications/v1/starters" | jq --unbuffered -r --arg skit_url "$SKIT_URL" '.starters[] | select(.repo_url ==$skit_url) | .platforms.server[0] ')
    case "$platform" in
      python | django | node) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ./server/config/
      ;;
      swift) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ./config/;
      ;;
      spring | java) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ./src/main/resources/;
      ;;
      *) echo "FAILED TO PLACE mappings.json"
         exit 1
    esac
fi

rm -r ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_BRANCH}
ls -al

echo "APP_NAME=${APP_NAME}" >> $ARCHIVE_DIR/build.properties
echo "DEVX_GIT_REPO_NAME=${DEVX_GIT_REPO_NAME}" >> $ARCHIVE_DIR/build.properties
