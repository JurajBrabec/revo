#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh

api_open "bazarr.${DOMAIN}"

echo -e "Retrieving API key ..." | tee -a $log_file

response=$(api_call 'GET' '/')
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

api_root='/api/system/settings'
api_key=$(echo $response | grep apiKey | cut -d \` -f 2 | cut -d \" -f 4)
set_env 'BAZARR_API_KEY' "$api_key"
api_token "x-api-key: $api_key"

api_content_type 'multipart/form-data'

payload=
declare -i id=1
for language in ${BAZARR_LANGUAGES,,}; do
  echo -e "Adding '$language' language..." | tee -a $log_file
  payload="$payload languages-enabled=$language"
  items="$items"'{"id":'$id',"language":"'$language'","audio_exclude":"False","hi":"False","forced":"False"},'
  id+=1
done
profile='{"profileId":1,"name":"Default","items":['${items::-1}'],"cutoff":65535,"mustContain":[],"mustNotContain":[],"originalFormat":false}'
payload="$payload languages-profiles=[$profile] \
  settings-general-serie_default_enabled=true \
  settings-general-serie_default_profile=1 \
  settings-general-movie_default_enabled=true \
  settings-general-movie_default_profile=1 \
  settings-general-adaptive_searching=true \
  settings-general-multithreading=false"

response=$(api_call 'POST' $api_root "$payload")
if [ $? != 204 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

echo -e "Adding applications..." | tee -a $log_file

payload="settings-general-use_sonarr=true \
  settings-sonarr-ip=sonarr \
  settings-sonarr-only_monitored=true \
  settings-sonarr-apikey=${SONARR_API_KEY} \
  settings-general-use_radarr=true \
  settings-radarr-ip=radarr \
  settings-radarr-only_monitored=true \
  settings-radarr-apikey=${RADARR_API_KEY}"

response=$(api_call 'POST' $api_root "$payload")
if [ $? != 204 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi


payload=
for provider in ${BAZARR_PROVIDERS,,}; do
  echo -e "Adding '$provider' provider..." | tee -a $log_file
  payload="$payload settings-general-enabled_providers=$provider"
done
response=$(api_call 'POST' $api_root "$payload")
if [ $? != 204 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

echo -e "Adding notification..." | tee -a $log_file
response=$(api_call 'GET' $api_root)
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi
provider=$(echo ${NOTIFICATION_URL} | cut -d : -f 1)
#token=$(echo ${NOTIFICATION_URL} | cut -d / -f 3)
token=$(echo ${NOTIFICATION_URL/pushbullet/pbul})
readarray -t schemas < <(echo $response | jq -j '.notifications' | jq -j '.providers' | jq -c '.[]')
for schema in "${schemas[@]}"; do
  if echo $schema | jq -j '.name' | grep -qi $provider; then
    payload="notifications-providers=$(echo $schema | jq -c '.url="'$token'"')"
    response=$(api_call 'POST' $api_root "$payload")
    if [ $? != 204 ]; then
      echo -e "!!! ERROR $?" | tee -a $log_file
      api_clean
      return
    fi
  fi
done

echo -e "Setting up credentials ..." | tee -a $log_file

payload="settings-auth-type=form \
  settings-auth-username=${BASICAUTH_USERNAME} \
  settings-auth-password=${BASICAUTH_PASSWORD} \
  settings-analytics-enabled=false"
response=$(api_call 'POST' $api_root "$payload")
if [ $? != 204 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

response=$(api_call 'POST' "/api/system?action=restart")

echo 'Success.' | tee -a $log_file

api_clean
