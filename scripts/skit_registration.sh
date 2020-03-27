#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

echo "Registering starter kit..."
curl -X POST \
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
  }
}'
