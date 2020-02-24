#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

# Record git info
echo "GIT_URL=${GIT_URL}" >> ./build.properties
echo "GIT_BRANCH=${GIT_BRANCH}" >> ./build.properties
echo "GIT_COMMIT=${GIT_COMMIT}" >> ./build.properties
echo "SOURCE_BUILD_NUMBER=${BUILD_NUMBER}" >> ./build.properties

echo "DEVX_SKIT_ASSETS_GIT=${DEVX_SKIT_ASSETS_GIT}" >> ./build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL=${DEVX_SKIT_ASSETS_GIT_URL}" >> ./build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL_RAW=${DEVX_SKIT_ASSETS_GIT_URL_RAW}" >> ./build.properties
echo "DEVX_SKIT_ASSETS_GIT_URL_CODE=${DEVX_SKIT_ASSETS_GIT_URL_CODE}" >> ./build.properties
echo "DEPLOY_TARGET=${DEPLOY_TARGET}" >> ./build.properties

echo "SLACK_WEBHOOK=${SLACK_WEBHOOK}" >> ./build.properties
echo "OWNER_SLACK_CHANNEL=${OWNER_SLACK_CHANNEL}" >> ./build.properties
echo "PAGERDUTY_API_URL=${PAGERDUTY_API_URL}" >> ./build.properties
echo "PAGERDUTY_EVENTS_API_URL=${PAGERDUTY_EVENTS_API_URL}" >> ./build.properties
echo "PAGERDUTY_API_TOKEN=${PAGERDUTY_API_TOKEN}" >> ./build.properties
echo "PAGERDUTY_SVC_NAME=${PAGERDUTY_SVC_NAME}" >> ./build.properties
echo "ENABLE_PD_ALERTS=${ENABLE_PD_ALERTS}" >> ./build.properties

if [ "$DEPLOY_TARGET" == "cf" ]; then
    echo "ENABLED_CF=${ENABLED_CF}" >> ./build.properties
fi
if [ "$DEPLOY_TARGET" == "helm" ]; then
    echo "ENABLED_HELM=${ENABLED_HELM}" >> ./build.properties
fi
if [ "$DEPLOY_TARGET" == "knative" ]; then
    echo "ENABLED_KNATIVE=${ENABLED_KNATIVE}" >> ./build.properties
fi

echo "File 'build.properties' created for passing env variables to subsequent pipeline jobs:"
cat ./build.properties
