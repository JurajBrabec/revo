#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh

bazarr_languages () {

  local payload=
  declare -i id=1
  for language in ${BAZARR_LANGUAGES,,}; do
    echo -e "Adding '$language' language..." | tee -a $log_file
    payload="$payload languages-enabled=$language"
    local items="$items"'{"id":'$id',"language":"'$language'","audio_exclude":"False","hi":"False","forced":"False"},'
    id+=1
  done
  local profile='{"profileId":1,"name":"Default","items":['${items::-1}'],"cutoff":65535,"mustContain":[],"mustNotContain":[],"originalFormat":false}'
  payload="$payload languages-profiles=[$profile] \
    settings-general-serie_default_enabled=true \
    settings-general-serie_default_profile=1 \
    settings-general-movie_default_enabled=true \
    settings-general-movie_default_profile=1 \
    settings-general-adaptive_searching=true \
    settings-general-multithreading=false"

  api_call 'POST' $api_root "$payload"
  if [ $(api_status) == 204 ]; then
    return 0
  fi
  return -1
}

bazarr_apps () {
  echo -e "Adding applications..." | tee -a $log_file

  local payload="settings-general-use_sonarr=true \
    settings-sonarr-ip=sonarr \
    settings-sonarr-only_monitored=true \
    settings-sonarr-apikey=${SONARR_API_KEY} \
    settings-general-use_radarr=true \
    settings-radarr-ip=radarr \
    settings-radarr-only_monitored=true \
    settings-radarr-apikey=${RADARR_API_KEY}"

  api_call 'POST' $api_root "$payload"
  if [ $(api_status) == 204 ]; then
    return 0
  fi
  return -1
}

bazarr_providers () {
  local payload=
  for provider in ${BAZARR_PROVIDERS,,}; do
    echo -e "Adding '$provider' provider..." | tee -a $log_file
    payload="$payload settings-general-enabled_providers=$provider"
  done
  api_call 'POST' $api_root "$payload"
  if [ $(api_status) == 204 ]; then
    return 0
  fi
  return -1
}

bazarr_notifications () {
  if echo "${NOTIFICATION_URL}" | grep -qi 'discord'; then
    local provider='discord'
    local url="${NOTIFICATION_URL}"
  fi
  if echo "${NOTIFICATION_URL}" | grep -qi 'pushbullet'; then
    local provider='pushbullet'
    local url=$(echo ${NOTIFICATION_URL/pushbullet/pbul})
  fi
  if [ -n "$provider" ]; then
    echo -e "Adding notification..." | tee -a $log_file
    api_call 'GET' $api_root
    if [ $(api_status) == 200 ]; then
      readarray -t schemas < <(echo $(api_data) | jq -j '.notifications' | jq -j '.providers' | jq -c '.[]')
      for schema in "${schemas[@]}"; do
        if echo $schema | jq -j '.name' | grep -qi $provider; then
          local payload="notifications-providers=$(echo $schema | jq -c '.enabled=true' | jq -c '.url="'$url'"')"
          api_call 'POST' $api_root "$payload"
          if [ $(api_status) == 204 ]; then
            return 0
          fi
        fi
      done
    fi
    return -1
  fi
}

bazarr_credentials () {
  echo -e "Setting up credentials ..." | tee -a $log_file

  local payload="settings-auth-type=form \
    settings-auth-username=${USERNAME} \
    settings-auth-password=${PASSWORD} \
    settings-analytics-enabled=false"
  api_call 'POST' $api_root "$payload"
  if [ $(api_status) == 204 ]; then
    return 0
  fi
  return -1
}

api_open "bazarr.${DOMAIN}"

echo -e "Retrieving API key ..." | tee -a $log_file

api_call 'GET' '/'
if [ $(api_status) == 200 ]; then
  api_key=$(echo $(api_data) | grep apiKey | cut -d \` -f 2 | cut -d \" -f 4)
  set_env 'BAZARR_API_KEY' "$api_key"

  api_token "x-api-key: $api_key"
  api_content_type 'multipart/form-data'
  api_root='/api/system/settings'

  bazarr_languages && bazarr_apps && bazarr_providers && bazarr_notifications && bazarr_credentials && {
    echo 'Success.' | tee -a $log_file
    api_clean
    return 0
  }
fi
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
