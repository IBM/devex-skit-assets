#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

export GIT_URL="https://github.com/IBM/${APP_NAME%"-monitored-cf"}"
export SKIT_NAME=${GIT_URL##*/}
export SKIT_URL=${GIT_URL%%.git} # strips .git off the end
export SKIT_NAME=${SKIT_NAME%%.*}

case "$DEPLOY_TARGET" in
    helm) mv ${DEVX_SKIT_ASSETS_GIT_REPO_DIR}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET} ${SKIT_DIR}/chart
    ;;
    cf) mv ${DEVX_SKIT_ASSETS_GIT_REPO_DIR}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/manifest.yaml ${SKIT_DIR}
    ;;
    *) echo "FAILED TO PLACE helm chart, manifest.yaml, or service.yaml"
       exit 1
esac

# If we have a mappings json, we need to make sure it goes to the right place for the respective language
if [ -f "${DEVX_SKIT_ASSETS_GIT_REPO_DIR}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json" ]; then

    platform=$(curl --silent "https://global.devx.cloud.ibm.com/appmanager/v1/starters" | jq --unbuffered -r --arg skit_url "$SKIT_URL" '.starters[] | select(.repo_url ==$skit_url) | .platforms.server[0] ')
    case "$platform" in
      python | django | node) mkdir -p ${SKIT_DIR}/server/config && mv ${DEVX_SKIT_ASSETS_GIT_REPO_DIR}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ${SKIT_DIR}/server/config
      ;;
      swift) mv ${DEVX_SKIT_ASSETS_GIT_REPO_DIR}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ${SKIT_DIR}/config/;
      ;;
      spring | java) mv ${DEVX_SKIT_ASSETS_GIT_REPO_DIR}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ${SKIT_DIR}/src/main/resources;
      ;;
      *) echo "FAILED TO PLACE mappings.json"
         exit 1
    esac
fi