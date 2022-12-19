arr_open () {
  ARR_APPLICATION=$1
  api_open "$ARR_APPLICATION.${DOMAIN}"
  api_content_type 'application/x-www-form-urlencoded'

  echo -e "Logging in ..." | tee -a $log_file
  api_call 'POST' '/login' "username=${USERNAME} password=${PASSWORD} rememberMe=on"
  if [ $(api_status) == 302 ] || [ $(api_status) == 303 ]; then
    echo -e "Retrieving API key ..." | tee -a $log_file
    api_content_type 'application/json'
    api_call 'GET' '/initialize.js'
    if [ $(api_status) == 200 ]; then
      local data=$(api_data)
      API_ROOT=$(echo $data | cut -d \' -f2)
      API_KEY=$(echo $data | cut -d \' -f4)
      api_token "x-api-key: $API_KEY"
      return 0
    fi
  fi
  return -1
}

arr_close () {
  echo -e "Logging out ..." | tee -a $log_file
  api_call 'GET' "$API_ROOT/logout"

  return 0
}

arr_rootfolder () {
  echo -e "Adding root folder ..." | tee -a $log_file
  api_call 'POST' "$API_ROOT/rootFolder" '{"path":"'$1'"}'
  if [ $(api_status) == 201 ]; then
    return 0
  fi
  return -1
}

arr_downloadclient () {
  local category=$1
  echo -e "Adding download client ..." | tee -a $log_file

  local route="$API_ROOT/downloadclient"
  api_call 'GET' "$route/schema"
  if [ $(api_status) == 200 ]; then
    readarray -t schemas < <(echo $(api_data) | jq -c '.[]')
    for schema in "${schemas[@]}"; do
      if echo $schema | jq -j '.implementation' | grep -qi 'qbittorrent'; then
        local fields=$(echo $schema | jq -j '.fields')
        fields=$(echo $fields | jq 'map(select(.name=="host").value="rdtclient")')
        fields=$(echo $fields | jq 'map(select(.name=="port").value=6500)')
        fields=$(echo $fields | jq 'map(select(.name=="username").value="'${USERNAME}'")')
        fields=$(echo $fields | jq 'map(select(.name=="password").value="'${PASSWORD}'")')
        fields=$(echo $fields | jq 'map(select(.name=="'$category'").value="'$ARR_APPLICATION'")')
        local payload=$(echo $schema | jq '.enable=true|.name="RDTClient"|.fields='"$fields")
        api_call 'POST' "$route?" "$payload"
        if [ $(api_status) == 201 ]; then
          return 0
        fi
      fi
    done
  fi
  return -1
}

arr_notification () {
  local conditions=$1
  local route="$API_ROOT/notification"

  if echo "${NOTIFICATION_URL}" | grep -qi 'discord'; then
    local implementation='discord'
    local details='map(select(.name=="username").value="'${ARR_APPLICATION^}'")|
      map(select(.name=="webHookUrl").value="'${NOTIFICATION_URL}'")'
  fi
  if echo "${NOTIFICATION_URL}" | grep -qi 'pushbullet'; then
    local implementation='pushbullet'
    local token=$(echo ${NOTIFICATION_URL} | cut -d / -f 3)
    local details='map(select(.name=="apiKey").value="'$token'")'
  fi

  if [ -z "$implementation" ]; then
    return 0
  fi

  echo -e "Adding notification ..." | tee -a $log_file

  api_call 'GET' "$route/schema"
  if [ $(api_status) == 200 ]; then
    readarray -t schemas < <(echo $(api_data) | jq -c '.[]')
    for schema in "${schemas[@]}"; do
      if echo $schema | jq -j '.implementation' | grep -qi $implementation; then
        local fields=$(echo $schema | jq -j '.fields' | jq "$details")
        local payload=$(echo $schema | jq "$conditions"'|.name="'${implementation^}'"|.fields='"$fields")
        api_call 'POST' "$route?" "$payload"
        if [ $(api_status) == 201 ]; then
          return 0
        fi
      fi
    done
  fi
  return -1
}

arr_ui () {
  echo -e "Setting up UI ..." | tee -a $log_file

  local route="$API_ROOT/config/ui"
  api_call 'GET' $route
  if [ $(api_status) == 200 ]; then
    local payload=$(echo $(api_data) | jq '.firstDayOfWeek=1|.calendarWeekColumnHeader="ddd D/M"|.shortDateFormat="DD MMM YYYY"|.longDateFormat="dddd, D MMMM YYYY"|.timeFormat="HH:mm"')
    api_call 'PUT' $route "$payload"
    if [ $(api_status) == 202 ]; then
      return 0
    fi
  fi
  return -1
}

arr_credentials () {
  echo -e "Setting up credentials ..." | tee -a $log_file

  local route="$API_ROOT/config/host"
  api_call 'GET' $route
  if [ $(api_status) == 200 ]; then
    local payload=$(echo $(api_data) | jq '.analyticsEnabled=false|.authenticationMethod="forms"|.password="'${PASSWORD}'"|.username="'${USERNAME}'"')
    api_call 'PUT' $route "$payload"
    if [ $(api_status) == 202 ]; then
      return 0
    fi
  fi
  return -1
}

arr_restart () {
  echo -e "Restarting ..." | tee -a $log_file
  api_call 'POST' "$API_ROOT/system/shutdown"
  return $?
}
