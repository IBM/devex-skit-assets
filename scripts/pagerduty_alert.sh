#!/bin/bash
# set -x

export ALERT_MSG="$1"
export EVT_ACTION=$2
export CLASS="$3"
export PD_SVC_NAME="$4"
export SEVERITY=$5

export IBM_CLOUD_REGION="${IBM_CLOUD_REGION:-us-south}"
export LOGS_URL="https://cloud.ibm.com/devops/pipelines/$PIPELINE_ID/$PIPELINE_STAGE_ID/$IDS_JOB_ID?env_id=ibm:yp:$IBM_CLOUD_REGION"

if [ "$ENABLE_PD_ALERTS" == "true" ]; then
    curl -X POST -H 'Content-Type: application/json' \
        -H "Authorization: Token token=$PAGERDUTY_API_TOKEN" \
        -H "Accept: application/vnd.pagerduty+json;version=2" \
        --data '{"routing_key": "'"$PAGERDUTY_API_TOKEN"'", "event_action": "'"$EVT_ACTION"'", "payload": {"summary": "'"$ALERT_MSG"'", "severity": "'"$SEVERITY"'", "component": "'"$IDS_JOB_NAME"'", "source": "'"$LOGS_URL"'", "group": "'"$IDS_PROJECT_NAME"'", "class": "'"$CLASS"'"}}' \
        $PAGERDUTY_EVENTS_API_URL
else
    echo "PD alerting has been disabled"
fi
