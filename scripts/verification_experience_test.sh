#!/bin/bash

exp_test_script=experience_test.sh
exp_test_path=./scripts/$exp_test_script
pd_evt_action=trigger
pd_class="Skit Experience Test"
pd_svc_name="DevX Skit Monitor"
pd_severity=error

# app URL isnt getting propagated from previous stages for some reason, so have to figure it out here
if [ "$DEPLOY_TARGET" == "cf" ]; then
  export CF_APP_NAME=$APP_NAME-monitored-cf
  export APP_URL=http://$(cf app $CF_APP_NAME | grep -e urls: -e routes: | awk '{print $2}')
fi
if [ "$DEPLOY_TARGET" == "helm" ]; then
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/get_app_url_helm.sh")
fi
if [ "$DEPLOY_TARGET" == "knative" ]; then
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/get_app_url_knative.sh")
fi
echo "The APP_URL is: $APP_URL"

set -e
EXIT_CODE=0

if [ -f "$exp_test_path" ]; then
  cd ./scripts
  source "./$exp_test_script" || EXIT_CODE=$?
  if [ $EXIT_CODE == 0 ]; then
    pass_msg="Skit Experience Test Passed :white_check_mark:"
    echo $pass_msg
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/slack_message.sh") "$pass_msg"
    exit 0
  else
    fail_msg="Skit Experience Test Failed"
    echo $fail_msg
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/pagerduty_alert.sh") "$fail_msg" "$pd_evt_action" "$pd_class" "$pd_svc_name" "$pd_severity"
    fail_msg="$fail_msg :spinning-siren:"
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/slack_message.sh") "$fail_msg"
    exit 1
  fi
else
  msg="Skit Experience Test script not found for skit $APP_NAME."
  echo $msg
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/pagerduty_alert.sh") "$msg" "$pd_evt_action" "$pd_class" "$pd_svc_name" "$pd_severity"
  msg="$msg :spinning-siren:"
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/slack_message.sh") "$msg"
  exit 1
fi
