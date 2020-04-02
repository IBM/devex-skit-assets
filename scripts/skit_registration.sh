#!/bin/bash
# uncomment to debug the script wherever it is used
set -x

function register_skit {
    OUT_FILE_RUN=run-pipeline-output.txt

    echo "Triggering starter kit registration..."
    curl -s -X POST \
    ${SKIT_REG_ENDPOINT} \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -H 'x-auth-token: '${SKIT_REG_AUTH_TOKEN}'' \
    -d '{
    "ref": "refs/heads/'${GIT_BRANCH}'",
    "after": "'${GIT_COMMIT}'",
    "repository": {
        "name": "'${APP_NAME}'",
        "full_name": "IBM/'${APP_NAME}'",
        "url": "https://github.com/IBM/'${APP_NAME}'",
        "html_url": "https://github.com/IBM/'${APP_NAME}'",
        "statuses_url": "https://api.github.com/repos/IBM/'${APP_NAME}'/statuses/{sha}"
    },
    "skit_verified": "true"
    }' >> $OUT_FILE_RUN

    echo ""
    echo "Registration pipeline response:"
    cat $OUT_FILE_RUN
    echo ""
    echo ""

    PIPELINE_INFO_URL=$(cat $OUT_FILE_RUN | jq '.url')
    TEMP="${PIPELINE_INFO_URL%\"}"
    TEMP="${TEMP#\"}"
    PIPELINE_INFO_URL=${TEMP}
    echo "Pipeline info URL: $PIPELINE_INFO_URL"

    IAM_TOKEN=$(ibmcloud iam oauth-tokens --output json | jq '.iam_token')
    TEMP="${IAM_TOKEN%\"}"
    TEMP="${TEMP#\"}"
    IAM_TOKEN=${TEMP}

    echo ""
    echo "Checking pipeline run status..."
    SUCCESS="false"
    for ITERATION in {1..30}
    do
        sleep 10

        STATUS=$(curl -s -X GET -H "Authorization: $IAM_TOKEN" $PIPELINE_INFO_URL | jq '.status.state')
        TEMP="${STATUS%\"}"
        TEMP="${TEMP#\"}"
        STATUS=${TEMP}
        echo "Pipeline run status: $STATUS"

        if [ "$STATUS" == "failed" ]; then
            echo "Pipeline run failed!"
            break
        elif [ "$STATUS" == "succeeded" ]; then
            echo "Pipeline run is finished!"
            SUCCESS="true"
            break
        else
            echo "Pipeline run is not finished, retrying after waiting..."
        fi
    done

    rm $OUT_FILE_RUN

    if [ "$SUCCESS" == "false" ]; then
        echo "Registration failed. Check the registration pipeline logs for details."
        export REG_EXIT=1
    else
        echo "Skit registration succeeded!"
        export REG_EXIT=0
    fi
}
