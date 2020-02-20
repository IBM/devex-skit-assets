#!/bin/bash

source build.properties

cd scripts/
if [ -f "experience_test.sh" ]; then
  ./experience_test.sh
  if [ $? == 0 ]; then
    pass_msg="Experience Test Passed"
    echo $pass_msg
    ./slack_message.sh $pass_msg
    exit 0
  else
    fail_msg="Experience Test Failed"
    echo $fail_msg
    ./slack_message.sh $fail_msg
    ./pagerduty_alert $fail_msg
    exit 1
  fi
else
  msg="The 'experience_test.sh' script was not found."
  echo $msg
  ./slack_message.sh $msg
  ./pagerduty_alert.sh $msg 
  exit 1
fi
