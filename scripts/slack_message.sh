#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

export SLACK_MSG=$1
export INCLUDE_LOGS=${2:-"true"}
export IBM_CLOUD_REGION="${IBM_CLOUD_REGION:-us-south}"
export LOGS_URL="https://cloud.ibm.com/devops/pipelines/$PIPELINE_ID/$PIPELINE_STAGE_ID/$IDS_JOB_ID?env_id=ibm:yp:$IBM_CLOUD_REGION"
export TEXT="$IDS_JOB_NAME - $SLACK_MSG - Project: $IDS_PROJECT_NAME. Deployment Target: '"$DEPLOY_TARGET"'"

if [ "${INCLUDE_LOGS}" == "true" ]; then
    curl -v POST --data-urlencode 'payload={"channel": "#'"$OWNER_SLACK_CHANNEL"'", 
                                    "username": "DevX Skit Monitor", 
                                    "text": "'"$TEXT"'", 
                                    "attachments": [
                                        {
                                            "pretext": "Visit the URL below to see the logs for this run.",
                                            "author_name": "DevOps Pipelines",
                                            "fallback": "Visit the pipeline to see logs for this run.",
                                            "title": "LOGS",
                                            "title_link": "'"$LOGS_URL"'"
                                        }
                                    ], "icon_emoji": ":police_car:"}' \
    $SLACK_WEBHOOK
else
    curl -v POST --data-urlencode 'payload={"channel": "#'"$OWNER_SLACK_CHANNEL"'", 
                                    "username": "DevX Skit Monitor", 
                                    "text": "'"$TEXT"'", 
                                    "attachments": [], "icon_emoji": ":police_car:"}' \
    $SLACK_WEBHOOK 
fi
