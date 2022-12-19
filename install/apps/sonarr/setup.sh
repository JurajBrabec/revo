#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh
source ${SCRIPT_DIR}/arr_api.sh

sonarr_rootfolder () {
  arr_rootfolder '/tv'
  return $?
}

sonarr_downloadclient () {
  arr_downloadclient 'tvCategory'
  return $?
}

sonarr_notification () {
  arr_notification '.onGrab=true|.onDownload=true|.onUpgrade=true|.onRename=true|.onSeriesDelete=true|.onEpisodeFileDelete=true|.onEpisodeFileDeleteForUpgrade=true|.onHealthIssue=true|.onApplicationUpdate=true|.includeHealthWarnings=true'
  return $?
}

arr_open "sonarr"
set_env 'SONARR_API_KEY' "$API_KEY"

sonarr_rootfolder && sonarr_downloadclient && sonarr_notification && arr_ui && arr_credentials && {
  arr_restart
  echo 'Success.' | tee -a $log_file
  api_clean
  return 0
}
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
