#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh

api_open "whisparr.${DOMAIN}"

echo -e "Retrieving API key..." | tee -a $log_file
response=$(api_call 'GET' '/initialize.js')
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi
api_root=$(echo $response | cut -d \' -f2)
api_key=$(echo $response | cut -d \' -f4)
set_env 'WHISPARR_API_KEY' "$api_key"
api_token "x-api-key: $api_key"

echo -e "Adding root folder..." | tee -a $log_file

response=$(api_call 'POST' "$api_root/rootFolder" '{"path":"/xxx"}')
if [ $? != 201 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

echo -e "Adding download client..." | tee -a $log_file

route="$api_root/downloadclient"
response=$(api_call 'GET' "$route/schema")
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi
readarray -t schemas < <(echo $response | jq -c '.[]')
for schema in "${schemas[@]}"; do
  if echo $schema | jq -j '.implementation' | grep -qi 'qbittorrent'; then
    fields=$(echo $schema | jq -j '.fields')
    fields=$(echo $fields | jq 'map(select(.name=="host").value="rdtclient")')
    fields=$(echo $fields | jq 'map(select(.name=="port").value=6500)')
    fields=$(echo $fields | jq 'map(select(.name=="username").value="'${BASICAUTH_USERNAME}'")')
    fields=$(echo $fields | jq 'map(select(.name=="password").value="'${BASICAUTH_PASSWORD}'")')
    fields=$(echo $fields | jq 'map(select(.name=="movieCategory").value="whisparr")')
    payload=$(echo $schema | jq '.enable=true|.name="RDTClient"|.fields='"$fields")
    response=$(api_call 'POST' "$route?" "$payload")
    if [ $? != 201 ]; then
      echo -e "!!! ERROR $?" | tee -a $log_file
      api_clean
      return
    fi
  fi
done

echo -e "Adding notification..." | tee -a $log_file

route="$api_root/notification"
response=$(api_call 'GET' "$route/schema")
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi
provider=$(echo ${NOTIFICATION_URL} | cut -d : -f 1)
token=$(echo ${NOTIFICATION_URL} | cut -d / -f 3)
readarray -t schemas < <(echo $response | jq -c '.[]')
for schema in "${schemas[@]}"; do
  if echo $schema | jq -j '.implementation' | grep -qi $provider; then
    fields=$(echo $schema | jq -j '.fields' | jq 'map(select(.name=="apiKey").value="'$token'")')
    payload=$(echo $schema | jq '.onGrab=true|.onDownload=true|.onUpgrade=true|.onMovieDelete=true|.onMovieFileDelete=true|.onMovieFileDeleteForUpgrade=true|.onHealthIssue=true|.onApplicationUpdate=true|.includeHealthWarnings=true|.name="Pushbullet"|.fields='"$fields")
    response=$(api_call 'POST' "$route?" "$payload")
    if [ $? != 201 ]; then
      echo -e "!!! ERROR $?" | tee -a $log_file
      api_clean
      return
    fi
  fi
done

echo -e "Setting up UI..." | tee -a $log_file

route="$api_root/config/ui"
response=$(api_call 'GET' $route)
payload=$(echo $response | jq '.firstDayOfWeek=1|.calendarWeekColumnHeader="dd D/M"|.shortDateFormat="DD MMM YYYY"|.longDateFormat="dddd, D MMMM YYYY"|.timeFormat="HH:mm"')
response=$(api_call 'PUT' $route "$payload")
if [ $? != 202 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

echo -e "Setting up credentials..." | tee -a $log_file

route="$api_root/config/host"
response=$(api_call 'GET' $route)
payload=$(echo $response | jq '.analyticsEnabled=false|.authenticationMethod="forms"|.password="'${BASICAUTH_PASSWORD}'"|.username="'${BASICAUTH_USERNAME}'"')
response=$(api_call 'PUT' $route "$payload")
if [ $? != 202 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

response=$(api_call 'POST' "$api_root/system/restart")

echo 'Success.' | tee -a $log_file

api_clean
