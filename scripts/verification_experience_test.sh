#!/bin/bash

if [ $PIPELINE_DEBUG == 1 ]; then
    set -x
fi

exp_test_script=experience_test.sh
SKIT_DIR=${SKIT_DIR:-"."} # use . if skit_dir is an empty string
exp_test_path=$SKIT_DIR/scripts/$exp_test_script
pd_evt_action=trigger
pd_class="Skit Experience Test"
pd_svc_name="DevX Skit Monitor"
pd_severity=error

echo "The APP_URL is: $APP_URL"

# install python3, pip
apt-get -qq update && apt-get -qq install -y python3 python3-venv python3-pip

set -e
EXIT_CODE=0
export VERIFY_EXIT=0

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
      export VERIFY_EXIT=0
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

if [ "$PASSED" == "false" ]; then
  fail_msg="Skit Experience Test Failed after multiple attempts"
  echo $fail_msg
  export VERIFY_EXIT=1
fi
