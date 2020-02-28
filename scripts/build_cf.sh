#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

# setup common env variables
source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/set_skit_env.sh")

# get manifest
source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/asset_download.sh")

# spring projects require a maven build for CF
if [ "${DEPLOY_TARGET}" == "cf" ]; then
    platform=$(curl --silent "https://cloud.ibm.com/developer/api/applications/v1/starters" | jq --unbuffered -r --arg skit_url "$SKIT_URL" '.starters[] | select(.repo_url ==$skit_url) | .platforms.server[0] ')
    case "$platform" in
    spring) echo "Building with Maven" && mvn -B package
    ;;
    *) echo "Not a Java Spring project, no need for Maven build"
    esac
fi
