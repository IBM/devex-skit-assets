#!/bin/bash
# uncomment to debug the script wherever it is used
set -x

# Push app
export CF_APP=chuckc-$APP_NAME-monitored-cf
if ! cf app "$CF_APP"; then  
  cf push "$CF_APP" -f ./manifest.yaml
else
  OLD_CF_APP="${CF_APP}-OLD-$(date +"%s")"
  rollback() {
    set +e  
    if cf app "$OLD_CF_APP"; then
      cf logs "$CF_APP" --recent
      cf delete "$CF_APP" -f
      cf rename "$OLD_CF_APP" "$CF_APP"
    fi
    exit 1
  }
  set -e
  trap rollback ERR
  cf rename "$CF_APP" "$OLD_CF_APP"
  cf push "$CF_APP" -f ./manifest.yaml
  cf delete "$OLD_CF_APP" -f
fi
# Export app name and URL for use in later Pipeline jobs
export CF_APP_NAME="$CF_APP"
export APP_URL=http://$(cf app $CF_APP_NAME | grep -e urls: -e routes: | awk '{print $2}')
echo "APP_URL=${APP_URL}" >> $ARCHIVE_DIR/build.properties

# copy build props to root dir build props
cat $ARCHIVE_DIR/build.properties >> ./build.properties

# View logs
cf logs "${CF_APP}" --recent
