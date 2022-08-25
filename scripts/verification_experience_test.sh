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
  exit 1
fi

set -e
EXIT_CODE=0

if [ "$PASSED" == "false" ]; then
  fail_msg="Skit Experience Test Failed after multiple"
  echo $fail_msg
  exit 1
fi
