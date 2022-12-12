#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${SCRIPT_DIR}/env.sh
source ${SCRIPT_DIR}/api.sh

IP_ADDRESS=$(hostname -I | cut -d \  -f 1)

src=${PROJECT_ROOT}/install/sonarr

log_file=${PROJECT_ROOT}/install/test.log
echo START > $log_file

main () {
api_open "lidarr.${DOMAIN}"

#response=$(api_call 'GET' '/logout/ReturnUrl=/')
#api_content_type 'application/x-www-form-urlencoded'
#echo -e "Logging in..." | tee -a $log_file
#payload="username=${BASICAUTH_USERNAME}&password=${BASICAUTH_PASSWORD}&rememberMe=on"
#response=$(api_call 'POST' '/login/ReturnUrl=/' "$payload")
#if [ $? != 46 ]; then
#  echo -e "!!! ERROR $?" | tee -a $log_file
#  api_clean
#  return
#fi
#api_content_type 'application/json'

echo -e "Retrieving API key..." | tee -a $log_file
response=$(api_call 'GET' '/initialize.js')
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi
api_root=$(echo $response | cut -d \' -f2)
api_key=$(echo $response | cut -d \' -f4)
set_env 'LIDARR_API_KEY' "$api_key"
api_token "x-api-key: $api_key"
echo API KEY: $api_key

echo -e "Adding notification..." | tee -a $log_file

route="$api_root/notification"
response=$(api_call 'GET' "$route/schema")
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

# {"onGrab":true,"onReleaseImport":true,"onUpgrade":true,"onRename":false,"onHealthIssue":true,"onDownloadFailure":true,"onImportFailure":true,"onTrackRetag":false,"onApplicationUpdate":true,"supportsOnGrab":true,"supportsOnReleaseImport":true,"supportsOnUpgrade":true,"supportsOnRename":false,"supportsOnHealthIssue":true,"includeHealthWarnings":false,"supportsOnDownloadFailure":true,"supportsOnImportFailure":true,"supportsOnTrackRetag":false,"supportsOnApplicationUpdate":true,"name":"Pushbullet","fields":[{"name":"apiKey"},{"name":"deviceIds","value":[]},{"name":"channelTags","value":[]},{"name":"senderId"}],"implementationName":"Pushbullet","implementation":"PushBullet","configContract":"PushBulletSettings","infoLink":"https://wiki.servarr.com/lidarr/supported#pushbullet","tags":[]}

}

main