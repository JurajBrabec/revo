#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh
source ${SCRIPT_DIR}/arr_api.sh

add_jackett_indexer () {
  echo -e "Adding indexer '$1' ..." | tee -a $log_file
  local url="http://jackett:9117/api/v2.0/indexers/$1/results/torznab/"
  local fields=$(echo $2 | jq -j '.fields')
  fields=$(echo $fields | jq 'map(select(.name=="baseUrl").value="'$url'")')
  fields=$(echo $fields | jq 'map(select(.name=="apiKey").value="'${JACKETT_API_KEY}'")')
  local payload=$(echo $2 | jq -c '.appProfileId=1|.enable=true|.name="'$1'"|.fields='"$fields")
  api_call 'POST' "$API_ROOT/indexer?" "$payload"
  if [ $(api_status) == 201 ]; then
    return 0
  fi
  echo -e "!!! ERROR $(api_status)" | tee -a $log_file
  return -1
}

prowlarr_indexer () {
  api_call 'GET' "$API_ROOT/indexer/schema"
  if [ $(api_status) == 200 ]; then
    local schema=$(echo $(api_data) | jq '.[] | select(.name=="Generic Torznab")')
    for indexer in ${JACKETT_INDEXERS}; do
      add_jackett_indexer "$indexer" "$schema"
    done
    return 0
  fi
  return -1
}

add_arr_app () {
  for schema in "${schemas[@]}"; do
    if echo $schema | jq -j '.implementation' | grep -qi "$1"; then
      echo -e "Adding application '${1,,}' ..." | tee -a $log_file
      local fields=$(echo $schema | jq -j '.fields')
      fields=$(echo $fields | jq 'map(select(.name=="prowlarrUrl").value="http://prowlarr:9696")')
      fields=$(echo $fields | jq 'map(select(.name=="baseUrl").value="'$2'")')
      fields=$(echo $fields | jq 'map(select(.name=="apiKey").value="'$3'")')
      local payload=$(echo $schema | jq '.enable=true|.name="'$1'"|.fields='"$fields")
      api_call 'POST' "$API_ROOT/applications?" "$payload"
      if [ $(api_status) == 201 ]; then
        return 0
      fi
      return -1
    fi
  done
}

prowlarr_apps () {
  api_call 'GET' "$API_ROOT/applications/schema"
  if [ $(api_status) == 200 ]; then
    readarray -t schemas < <(echo $(api_data) | jq -c '.[]')
    echo ${SERVICES} | grep -qi "lidarr" && add_arr_app "Lidarr" "http://lidarr:8686" "${LIDARR_API_KEY}" || return -1
    echo ${SERVICES} | grep -qi "radarr" && add_arr_app "Radarr" "http://radarr:7878" "${RADARR_API_KEY}" || return -1
    echo ${SERVICES} | grep -qi "sonarr" && add_arr_app "Sonarr" "http://sonarr:8989" "${SONARR_API_KEY}" || return -1
    echo ${SERVICES} | grep -qi "whisparr" && add_arr_app "Whisparr" "http://whisparr:6969" "${WHISPARR_API_KEY}" || return -1
    return 0
  fi
  return -1
}

prowlarr_downloadclient () {
  arr_downloadclient 'movieCategory'
  return $?
}

prowlarr_notification () {
  arr_notification '.onHealthIssue=true|.onApplicationUpdate=true|.includeHealthWarnings=true'
  return $?
}

arr_open "prowlarr"
set_env 'PROWLARR_API_KEY' "$API_KEY"

prowlarr_indexer && prowlarr_apps && prowlarr_downloadclient && prowlarr_notification && arr_ui && arr_credentials && {
  arr_restart
  echo 'Success.' | tee -a $log_file
  api_clean
  return 0
}
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
