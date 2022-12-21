#!/bin/bash

if [ ! -d ${INSTALL_DIR}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh
source ${SCRIPT_DIR}/arr_api.sh

radarr_rootfolder () {
  arr_rootfolder '/movies'
  return $?
}

radarr_downloadclient () {
  arr_downloadclient 'movieCategory'
  return $?
}

radarr_notification () {
  arr_notification '.onGrab=true|.onDownload=true|.onUpgrade=true|.onRename=true|.onMovieAdded=true|.onMovieDelete=true|.onMovieFileDelete=true|.onMovieFileDeleteForUpgrade=true|.onHealthIssue=true|.onApplicationUpdate=true|.includeHealthWarnings=true'
  return $?
}

arr_open "radarr"
set_env 'RADARR_API_KEY' "$API_KEY"

radarr_rootfolder && radarr_downloadclient && radarr_notification && arr_ui && arr_credentials && {
  arr_restart
  echo 'Success.' | tee -a $log_file
  api_clean
  return 0
}
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
