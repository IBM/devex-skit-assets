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

echo "Fetching deployment assets for skit ${SKIT_NAME}"
# directory structure: REPO/deployment-assets/<skit-name>/<deploy-target>
# can't seem to find an easy way to d/l a specific folder, so need to get the whole repo
curl $DEVX_GIT_URL_CODE/tar.gz/master | tar -xz
ls -al
ls -al devx-skit-governance-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}

if [ "${DEPLOY_TARGET}" == "helm" ]; then mv devx-skit-governance-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET} ./chart; fi
if [ "${DEPLOY_TARGET}" == "knative" ]; then mv devx-skit-governance-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/service.yaml ./; fi
if [ "${DEPLOY_TARGET}" == "cf" ]; then 
    mv devx-skit-governance-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/manifest.yaml ./;
    mv devx-skit-governance-master/deployment-assets/${SKIT_NAME}/${DEPLOY_TARGET}/mappings.json ./server/config/;
fi

rm -r devx-skit-governance-master
ls -al
