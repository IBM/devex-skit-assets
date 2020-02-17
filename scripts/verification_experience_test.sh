#!/bin/bash

source build.properties

# experience test script expected in one of the predefined locations. otherwise fail.
#Invoke tests here
var pass=true

if [[ !pass ]]; do 
  printenv
  curl -X POST -H 'Content-type: application/json' --data '{"attachments": [{"text": "'"$IDS_JOB_NAME"' FAILED for '"$IDS_PROJECT_NAME"'! :spinning-siren:","color": "#3AA3E3","actions": [{"name": "game","text": "LOGS","type": "button","url": "https://cloud.ibm.com/devops/pipelines/'"$PIPELINE_ID"'/'"$PIPELINE_STAGE_ID"'/'"$IDS_JOB_ID"'?env_id=ibm:yp:us-south"}]}]}' $SLACK_WEBHOOK
  exit 1
fi
exit 0