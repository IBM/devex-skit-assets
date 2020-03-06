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
# remove the v from the release version
DEVX_SKIT_ASSETS_GIT_RELEASE=(${DEVX_SKIT_ASSETS_GIT_RELEASE#v})

echo "Fetching deployment assets for skit ${SKIT_NAME} using skit assets release ${DEVX_SKIT_ASSETS_GIT_RELEASE}"
# directory structure: REPO/deployment-assets/<skit-name>/<deploy-target>
# can't seem to find an easy way to d/l a specific folder, so need to get the whole repo
curl $DEVX_SKIT_ASSETS_GIT_URL_CODE | tar -xz
ls -al
ls -al ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}

case "$DEPLOY_TARGET" in
    helm) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET} ./chart
    ;;
    cf) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/manifest.yaml ./
    ;;
    knative) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/service.yaml ./
    ;;
    *) echo "FAILED TO PLACE helm chart, manifest.yaml, or service.yaml"
       exit 1
esac

# If we have a mappings json, we need to make sure it goes to the right place for the respective language
if [ -f "${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json" ]; then

    platform=$(curl --silent "https://cloud.ibm.com/developer/api/applications/v1/starters" | jq --unbuffered -r --arg skit_url "$SKIT_URL" '.starters[] | select(.repo_url ==$skit_url) | .platforms.server[0] ')
    case "$platform" in
      python | django | node) mkdir -p ./server/config && mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ./server/config/
      ;;
      swift) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ./config/;
      ;;
      spring | java) mv ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ./src/main/resources/;
      ;;
      *) echo "FAILED TO PLACE mappings.json"
         exit 1
    esac
fi

rm -r ${DEVX_GIT_REPO_NAME}-${DEVX_SKIT_ASSETS_GIT_RELEASE}
ls -al

echo "APP_NAME=${APP_NAME}" >> $ARCHIVE_DIR/build.properties
echo "DEVX_GIT_REPO_NAME=${DEVX_GIT_REPO_NAME}" >> $ARCHIVE_DIR/build.properties
