#!/bin/bash
# uncomment to debug the script wherever it is used
set -x

export SLACK_MSG=$1
export NOTIFY=${2:-"true"}
export IBM_CLOUD_REGION="${IBM_CLOUD_REGION:-us-south}"
export LOGS_URL="https://cloud.ibm.com/devops/pipelines/$PIPELINE_ID/$PIPELINE_STAGE_ID/$IDS_JOB_ID?env_id=ibm:yp:$IBM_CLOUD_REGION"
export TEXT="$IDS_JOB_NAME - $SLACK_MSG - Project: $IDS_PROJECT_NAME. Deployment: "$DEPLOY_TARGET" || <"$LOGS_URL"|LOGS> || <"$GIT_URL"|REPO>"

if [[ -n $APP_URL ]]; then
    export TEXT="$TEXT || <"$APP_URL"|APP>"
fi

if [ "${NOTIFY}" == "true" ]; then
    export TEXT="$TEXT @here"
fi

curl -s -X POST --data-urlencode 'payload={"username": "DevX Skit Monitor", 
                                "text": "'"$TEXT"'", 
                                "link_names": "true",
                                "attachments": [], "icon_emoji": ":police_car:"}' \
    $OWNER_SLACK_CHANNEL_WEBHOOK

# also send to the DevX slack channel if not already
if [ "${OWNER_SLACK_CHANNEL_WEBHOOK}" != "${DEVX_SLACK_CHANNEL_WEBHOOK}" ]; then
    curl -s -X POST --data-urlencode 'payload={"username": "DevX Skit Monitor", 
                                    "text": "'"$TEXT"'", 
                                    "link_names": "true",
                                    "attachments": [], "icon_emoji": ":police_car:"}' \
    $DEVX_SLACK_CHANNEL_WEBHOOK
fi
