#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

export SLACK_MSG=$1
export NOTIFY=${2:-"true"}
export IBM_CLOUD_REGION="${IBM_CLOUD_REGION:-us-south}"
export LOGS_URL="https://cloud.ibm.com/devops/pipelines/$PIPELINE_ID/$PIPELINE_STAGE_ID/$IDS_JOB_ID?env_id=ibm:yp:$IBM_CLOUD_REGION"
export TEXT="$IDS_JOB_NAME - $SLACK_MSG - Project: $IDS_PROJECT_NAME. Deployment: "$DEPLOY_TARGET" || <"$LOGS_URL"|LOGS> || <"$GIT_URL"|REPO>"
if [[ -n $APP_URL ]]; then
    export TEXT="$TEXT || <"$APP_URL"|APP>"
fi

if [ "${NOTIFY}" == "true" ]; then
    curl POST --data-urlencode 'payload={"channel": "#'"$OWNER_SLACK_CHANNEL"'", 
                                    "username": "DevX Skit Monitor", 
                                    "text": "'"$TEXT"' @here", 
                                    "link_names": "true",
                                    "attachments": [], "icon_emoji": ":police_car:"}' \
    $SLACK_WEBHOOK
else
    curl POST --data-urlencode 'payload={"channel": "#'"$OWNER_SLACK_CHANNEL"'", 
                                    "username": "DevX Skit Monitor", 
                                    "text": "'"$TEXT"'", 
                                    "attachments": [], "icon_emoji": ":police_car:"}' \
    $SLACK_WEBHOOK 
fi
