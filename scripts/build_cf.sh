#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

# setup common env variables
source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/set_skit_env.sh")

# get manifest
source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/asset_download.sh")
