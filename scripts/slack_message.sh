#!/bin/bash
# set -x

export SLACK_MSG=$1
# :spinning-siren:
curl -X POST -H 'Content-type: application/json' \
--data '{"attachments": [{"text": "'"$IDS_JOB_NAME"': '"$SLACK_MSG"'. Project: '"$IDS_PROJECT_NAME"'.","color": "#3AA3E3","actions": [{"name": "game","text": "LOGS","type": "button","url": "https://cloud.ibm.com/devops/pipelines/'"$PIPELINE_ID"'/'"$PIPELINE_STAGE_ID"'/'"$IDS_JOB_ID"'?env_id=ibm:yp:'"$IBM_CLOUD_REGION"'"}]}]}' \
$SLACK_WEBHOOK
