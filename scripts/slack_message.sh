#!/bin/bash
# set -x

export SLACK_MSG=$1
export IBM_CLOUD_REGION="${IBM_CLOUD_REGION:-us-south}"
export LOGS_URL="https://cloud.ibm.com/devops/pipelines/$PIPELINE_ID/$PIPELINE_STAGE_ID/$IDS_JOB_ID?env_id=ibm:yp:$IBM_CLOUD_REGION"

curl -X POST -H 'Content-type: application/json' \
--data '{"attachments": [{"text": "'"$IDS_JOB_NAME"' - '"$SLACK_MSG"': Project: '"$IDS_PROJECT_NAME"'.","color": "#3AA3E3","actions": [{"name": "game","text": "LOGS","type": "button","url": "'"$LOGS_URL"'"}]}]}' \
$SLACK_WEBHOOK
