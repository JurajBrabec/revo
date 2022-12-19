#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh
source ${SCRIPT_DIR}/arr_api.sh

whisparr_rootfolder () {
  arr_rootfolder '/xxx'
  return $?
}

whisparr_downloadclient () {
  arr_downloadclient 'movieCategory'
  return $?
}

whisparr_notification () {
  arr_notification '.onGrab=true|.onDownload=true|.onUpgrade=true|.onMovieDelete=true|.onMovieFileDelete=true|.onMovieFileDeleteForUpgrade=true|.onHealthIssue=true|.onApplicationUpdate=true|.includeHealthWarnings=true'
  return $?
}

arr_open "whisparr"
set_env 'WHISPARR_API_KEY' "$API_KEY"

whisparr_rootfolder && lidarr_downloadclient && lidarr_notification && arr_ui && arr_credentials && {
  arr_restart
  echo 'Success.' | tee -a $log_file
  api_clean
  return 0
}
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
