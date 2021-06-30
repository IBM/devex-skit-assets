#!/bin/bash
# uncomment to debug the script wherever it is used
# set -x

exp_test_script=experience_test.sh
SKIT_DIR=${SKIT_DIR:-"."} # use . if skit_dir is an empty string
exp_test_path=$SKIT_DIR/scripts/$exp_test_script
pd_evt_action=trigger
pd_class="Skit Experience Test"
pd_svc_name="DevX Skit Monitor"
pd_severity=error

# app URL isnt getting propagated from previous stages for some reason, so have to figure it out here
if [ "$DEPLOY_TARGET" == "cf" ] && [ -z "$APP_URL" ]; then
  export APP_URL=https://$(cf app $APP_NAME | grep -e urls: -e routes: | awk '{print $2}')
fi

echo "The APP_URL is: $APP_URL"

# install python3, pip
apt-get -qq update && apt-get -qq install -y python3 python3-venv python3-pip

set -e
EXIT_CODE=0

PASSED="false"
if [ -f "$exp_test_path" ]; then
  cd $SKIT_DIR/scripts
  for i in {1..3}
  do
    echo "Beginning Skit Experience Test attempt $i"
    source "./$exp_test_script" || EXIT_CODE=$?
    if [ $EXIT_CODE == 0 ]; then
      PASSED="true"
      pass_msg=":white_check_mark: Skit Experience Test Passed"
      echo $pass_msg
      if [ $ENABLE_SLACK_ALERTS == "true" ]; then
        source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/slack_message.sh") "$pass_msg" "false"
      fi
      break
    else
      echo "Skit Experience Test attempt $i failed"
      PASSED="false"
      EXIT_CODE=0
    fi
  done
else
  msg="Skit Experience Test script not found for skit $APP_NAME."
  echo $msg
  if [ "$ENABLE_PD_ALERTS" == "true" ]; then
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/pagerduty_alert.sh") "$msg" "$pd_evt_action" "$pd_class" "$pd_svc_name" "$pd_severity"
  fi
  msg=":spinning-siren: $msg "
  if [ $ENABLE_SLACK_ALERTS == "true" ]; then
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/slack_message.sh") "$msg"
  fi
  exit 1
fi

set -e
EXIT_CODE=0

if [ "$PASSED" == "false" ]; then
  fail_msg="Skit Experience Test Failed"
  echo $fail_msg
  
  if [ "$ENABLE_PD_ALERTS" == "true" ]; then
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/pagerduty_alert.sh") "$fail_msg" "$pd_evt_action" "$pd_class" "$pd_svc_name" "$pd_severity"
  fi
  
  fail_msg=":spinning-siren: $fail_msg "

  if [ $ENABLE_SLACK_ALERTS == "true" ]; then
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/slack_message.sh") "$fail_msg"
  fi
  exit 1
fi

if [ "$PASSED" == "true" ] && [ "$DEPLOY_TARGET" != "cf" ] && [ "$REGISTER_SKIT == "true" ]; then
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/skit_registration.sh")
  echo "Beginning skit registration..."
  register_skit
  if [ $REG_EXIT != 0 ]; then
    msg="Skit registration failed. Check the starter-kit-registration Tekton pipeline logs under DevOps Toolchains for details."
    fail_msg=":spinning-siren: $msg"
    if [ $ENABLE_SLACK_ALERTS == "true" ]; then
      source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/slack_message.sh") "$fail_msg"
    fi
    exit 1
  fi
fi
