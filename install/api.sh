api_open () {
  API_HOST=$1
  API_C_FILE='/tmp/cookies.txt'
  API_D_FILE='/tmp/data.txt'
  API_H_FILE='/tmp/headers.txt'
  API_O_FILE='/tmp/output.txt'
  API_T_FILE='/tmp/token.txt'
  api_clean
}

api_clean () {
  API_EXITCODE=
  API_STATUS=
  API_TOKEN=
  if [ -f "$API_C_FILE" ]; then
    rm $API_C_FILE
  fi
  if [ -f "$API_D_FILE" ]; then
    rm $API_D_FILE
  fi
  if [ -f "$API_H_FILE" ]; then
    rm $API_H_FILE
  fi
  if [ -f "$API_O_FILE" ]; then
    rm $API_O_FILE
  fi
  if [ -f "$API_T_FILE" ]; then
    rm $API_T_FILE
  fi
}

api_token () {
    API_TOKEN=$1
    echo "Authorization: Bearer $1">$API_T_FILE
}
api_call () {
  local method="$1"
  local path="$2"
  local data="$3"

  local command='curl -kLs \
    -b '$API_C_FILE' -c '$API_C_FILE' -D '$API_H_FILE' \
    --resolve '$API_HOST':443:'${IP_ADDRESS}' -X '$method' https://'$API_HOST$path

  if [ -n "$API_TOKEN" ]; then
    local command="$command -H @$API_T_FILE"
  fi
  if [ "$method" != "GET" ]; then
    echo $data>$API_D_FILE
    local command="$command --json @$API_D_FILE"
  fi
  echo C: $command >> $log_file

  while true; do
    $command 2>&1 > $API_O_FILE
    API_EXITCODE=$?
    API_STATUS=$(cat $API_H_FILE | grep "^HTTP/. " | tail -n 1 | cut -d \  -f 2)
    if [ "$API_EXITCODE" == "0" ] && [ "$API_STATUS" != "404" ] && [ "$API_STATUS" != "502" ]; then
      break
    fi
    echo "+:$API_EXITCODE/$API_STATUS" >> $log_file
    sleep 1
  done

  echo E: $API_EXITCODE >> $log_file
  echo S: $API_STATUS >> $log_file
  echo O: >> $log_file
  cat $API_O_FILE >> $log_file

#  echo -e "\nH:" >> $log_file
#  cat $API_H_FILE >> $log_file
#  echo C: >> $log_file
#  cat $API_C_FILE >> $log_file
#  if [ "$method" != "GET" ]; then
#    echo D:>> $log_file
#    cat $API_D_FILE >> $log_file
#  fi

  echo -e "---\n" >> $log_file
  cat $API_O_FILE
  return $(($API_STATUS))
}
