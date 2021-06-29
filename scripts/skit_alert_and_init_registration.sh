pd_evt_action=trigger
pd_class="Skit Experience Test"
pd_svc_name="DevX Skit Monitor"
pd_severity=error

if [ "$PASSED" == "false" ]; then
  fail_msg="Skit Experience Test Failed"
  echo $fail_msg
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/pagerduty_alert.sh") "$fail_msg" "$pd_evt_action" "$pd_class" "$pd_svc_name" "$pd_severity"
  fail_msg=":spinning-siren: $fail_msg "
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/slack_message.sh") "$fail_msg"
  exit 1
fi

if [ "$PASSED" == "true" ] && [ "$DEPLOY_TARGET" != "cf" ]; then
  source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/skit_registration.sh")
  echo "Beginning skit registration..."
  register_skit
  if [ $REG_EXIT != 0 ]; then
    msg="Skit registration failed. Check the starter-kit-registration Tekton pipeline logs under DevOps Toolchains for details."
    fail_msg=":spinning-siren: $msg"
    source <(curl -sSL "$DEVX_SKIT_ASSETS_GIT_URL_RAW/scripts/slack_message.sh") "$fail_msg"
    exit 1
  fi
fi
