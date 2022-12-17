#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh
source ${SCRIPT_DIR}/arr_api.sh

lidarr_rootfolder () {
  echo -e "Adding root folder ..." | tee -a $log_file

  api_call 'POST' "$API_ROOT/rootFolder" '{
    "name": "music",
    "path": "/music",
    "defaultMetadataProfileId": 1,
    "defaultQualityProfileId": 1,
    "defaultMonitorOption": "all",
    "defaultNewItemMonitorOption": "all",
    "defaultTags": [],
    "accessible": true
  }'
  if [ $(api_status) == 201 ]; then
    return 0
  fi
  return -1
}

lidarr_downloadclient () {
  echo -e "Adding download client ..." | tee -a $log_file

  route="$API_ROOT/downloadclient"
  api_call 'GET' "$route/schema"
  if [ $(api_status) == 200 ]; then
    readarray -t schemas < <(echo $(api_data) | jq -c '.[]')
    for schema in "${schemas[@]}"; do
      if echo $schema | jq -j '.implementation' | grep -qi 'qbittorrent'; then
        fields=$(echo $schema | jq -j '.fields')
        fields=$(echo $fields | jq 'map(select(.name=="host").value="rdtclient")')
        fields=$(echo $fields | jq 'map(select(.name=="port").value=6500)')
        fields=$(echo $fields | jq 'map(select(.name=="username").value="'${USERNAME}'")')
        fields=$(echo $fields | jq 'map(select(.name=="password").value="'${PASSWORD}'")')
        fields=$(echo $fields | jq 'map(select(.name=="musicCategory").value="lidarr")')
        payload=$(echo $schema | jq '.enable=true|.name="RDTClient"|.fields='"$fields")
        api_call 'POST' "$route?" "$payload"
        if [ $(api_status) == 201 ]; then
          return 0
        fi
      fi
    done
  fi
  return -1
}

lidarr_notification () {
  arr_notification '.onGrab=true|.onDownloadFailure=true|.onUpgrade=true|.onRename=true|.onReleaseImport=true|.onImportFailure=true|.onTrackRetag=true'
  return $?
}

arr_open "lidarr"
set_env 'LIDARR_API_KEY' "$API_KEY"

lidarr_rootfolder && lidarr_downloadclient && lidarr_notification && arr_ui && arr_credentials && arr_restart && {
  echo 'Success.' | tee -a $log_file
  api_clean
  return 0
}
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
