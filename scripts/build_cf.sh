#!/bin/bash
# set -x

# get manifest
source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/asset_download.sh")
ls -al
export CF_APP=${APP_NAME}-monitored-cf
