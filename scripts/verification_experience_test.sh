#!/bin/bash

exp_test_path=./scripts/experience_test.sh
pd_evt_action=trigger
pd_class="Skit Experience Test"
pd_svc_name="DevX Skit Monitor"
pd_severity=error

if [ -f "$exp_test_path" ]; then
  bash -c "$exp_test_path"
  if [ $? == 0 ]; then
    pass_msg="Experience Test Passed :white_check_mark:"
    echo $pass_msg
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/slack_message.sh") $pass_msg
    exit 0
  else
    fail_msg="Experience Test Failed"
    echo $fail_msg
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/pagerduty_alert.sh") "$fail_msg" $pd_evt_action $pd_class $pd_svc_name $pd_severity
    fail_msg="$fail_msg :spinning-siren:"
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/slack_message.sh") "$fail_msg"
    exit 1
  fi
else
  msg="The '$exp_test_path' script was not found in the project's root folder. This script is required to pass verification."
  echo $msg
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/pagerduty_alert.sh") "$msg" $pd_evt_action $pd_class $pd_svc_name $pd_severity
  fail_msg="$fail_msg :spinning-siren:"
  exit 1
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/master/scripts/slack_message.sh") "$msg"
fi
