api_open () {
  API_DEBUG=0
  API_HOST=$1
  API_C_FILE='/tmp/cookies.txt'
  API_P_FILE='/tmp/payload.txt'
  API_H_FILE='/tmp/headers.txt'
  API_D_FILE='/tmp/data.txt'
  API_T_FILE='/tmp/token.txt'
  api_clean
}

api_clean () {
  API_CONTENT_TYPE='application/json'
  API_ERROR=
  API_STATUS=
  API_TOKEN=
  if [ -f "$API_C_FILE" ]; then
    rm $API_C_FILE
  fi
  if [ -f "$API_P_FILE" ]; then
    rm $API_P_FILE
  fi
  if [ -f "$API_H_FILE" ]; then
    rm $API_H_FILE
  fi
  if [ -f "$API_D_FILE" ]; then
    rm $API_D_FILE
  fi
  if [ -f "$API_T_FILE" ]; then
    rm $API_T_FILE
  fi
}

api_content_type () {
  API_CONTENT_TYPE=$1
}
api_debug () {
  API_DEBUG=$1
}
api_token () {
  API_TOKEN=$1
  echo "$1">$API_T_FILE
}

api_call () {
  local method="$1"
  local path="$2"
  local payload="$3"

  local command='curl -ks
    -b '$API_C_FILE' -c '$API_C_FILE' -D '$API_H_FILE'
    --resolve '$API_HOST':443:'${IP_ADDRESS}' -X '$method' https://'$API_HOST$path

  if [ -n "$API_TOKEN" ]; then
    local command="$command -H @$API_T_FILE"
  fi

  if [ "$method" != "GET" ]; then
    echo $payload>$API_P_FILE
    if [ -z "$API_CONTENT_TYPE" ] || [ $API_CONTENT_TYPE == 'application/json' ]; then
      local command="$command --json @$API_P_FILE"
    elif [ $API_CONTENT_TYPE == 'application/x-www-form-urlencoded' ]; then
      for item in $(cat $API_P_FILE); do
        local command="$command --data-urlencode $item"
      done
    elif [ $API_CONTENT_TYPE == 'multipart/form-data' ]; then
      for item in $(cat $API_P_FILE); do
        local command="$command -F $item"
      done
    fi
  fi

  if [ $API_DEBUG == 1 ]; then
    echo C: $command >> $log_file
  fi

  declare -i try=1
  while [ $try -le 30 ]; do
    $command 2>&1 > $API_D_FILE
    API_ERROR=$?
    API_STATUS=$(cat $API_H_FILE | grep "^HTTP/. " | tail -n 1 | cut -d \  -f 2)
    API_COOKIE=$(cat $API_H_FILE | grep "^set-cookie: " | tail -n 1 | cut -d \  -f 2)
    if [ "$API_ERROR" == "0" ] && [ "$API_STATUS" != "404" ] && [ "$API_STATUS" != "502" ]; then
      break
    fi
    if [ "$API_ERROR" == "6" ] && [ "$method" == "POST" ]; then
      if [ "$API_STATUS" == "302" ] || [ "$API_STATUS" == "401" ]; then
        break
      fi
    fi
    if [ $API_DEBUG == 1 ]; then
      echo "$try:$API_ERROR/$API_STATUS" >> $log_file
    fi
    sleep 1
    try+=1
  done

  if [ $API_DEBUG == 1 ]; then
    echo "M:$method" >> $log_file
    echo "P:$path" >> $log_file
    echo "E:$API_ERROR" >> $log_file
    echo "S:$API_STATUS" >> $log_file
    echo "P:$payload" >> $log_file
    echo "C:$API_COOKIE" >> $log_file
    echo "D:$(cat $API_D_FILE)" >> $log_file
    echo -e "---\n" >> $log_file
  fi

  return 0
}

api_cookie () {
  echo $API_COOKIE
}
api_data () {
  cat $API_D_FILE
}
api_error () {
  echo $API_ERROR
}
api_status () {
  echo $API_STATUS
}
