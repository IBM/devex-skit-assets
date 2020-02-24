#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

export SLACK_MSG=$1
export IBM_CLOUD_REGION="${IBM_CLOUD_REGION:-us-south}"
export LOGS_URL="https://cloud.ibm.com/devops/pipelines/$PIPELINE_ID/$PIPELINE_STAGE_ID/$IDS_JOB_ID?env_id=ibm:yp:$IBM_CLOUD_REGION"
export TEXT="$IDS_JOB_NAME - $SLACK_MSG - Project: $IDS_PROJECT_NAME. Deployment Target: '"$DEPLOY_TARGET"'"

curl -v POST --data-urlencode 'payload={"channel": "#'"$OWNER_SLACK_CHANNEL"'", "username": "DevX Skit Monitor", "text": "'"$TEXT"'", "actions": [{"name": "game","text": "LOGS","type": "button","url": "'"$LOGS_URL"'"}], "icon_emoji": ":terminator:"}' \
$SLACK_WEBHOOK
