#!/bin/bash
set -x

# This script expects the GIT_URL env var to contain the URL to the skit git repo,
# from which the deployment assets folder will be extracted.

echo "Directory * "
pwd
echo "ls -al *"
ls -al

# expected URL structure: https://github.com/<org>/<skit-name>.git
export SKIT_NAME=(${GIT_URL##*/})
export SKIT_NAME=(${SKIT_NAME%%.*})
export APP_NAME=${SKIT_NAME}
export DEVX_GIT_REPO_NAME=devex-skit-assets

echo "Fetching deployment assets for skit ${SKIT_NAME}"
# directory structure: REPO/deployment-assets/<skit-name>/<deploy-target>
# can't seem to find an easy way to d/l a specific folder, so need to get the whole repo
curl $DEVX_SKIT_ASSETS_GIT_URL_CODE/tar.gz/master | tar -xz
ls -al
ls -al ${DEVX_GIT_REPO_NAME}-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}

if [ "${DEPLOY_TARGET}" == "helm" ]; then mv ${DEVX_GIT_REPO_NAME}-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET} ./chart; fi
if [ "${DEPLOY_TARGET}" == "knative" ]; then mv ${DEVX_GIT_REPO_NAME}-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/service.yaml ./; fi
if [ "${DEPLOY_TARGET}" == "cf" ]; then 
    mv ${DEVX_GIT_REPO_NAME}-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/manifest.yaml ./;
    mv ${DEVX_GIT_REPO_NAME}-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ./server/config/;
fi

rm -r ${DEVX_GIT_REPO_NAME}-master
ls -al
