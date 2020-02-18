#!/bin/bash
# set -x

printenv

# get manifest
source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/asset_download.sh")
ls -al