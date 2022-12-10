api_open () {
  API_HOST=$1
  API_C_FILE='/tmp/cookies.txt'
  API_D_FILE='/tmp/data.txt'
  API_H_FILE='/tmp/headers.txt'
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
  if [ -f "$API_T_FILE" ]; then
    rm $API_T_FILE
  fi
}

api_token () {
    API_TOKEN=$1
    echo "Authorization: Bearer $1">$API_T_FILE
}
api () {
  local method="$1"
  local path="$2"
  local data="$3"

  local command='curl -kLs -D '$API_H_FILE' -b '$API_C_FILE' -c '$API_C_FILE' \
    --resolve '$API_HOST':443:'${IP_ADDRESS}' -X '$method' https://'$API_HOST$path

  if [ -n "$API_TOKEN" ]; then
    local command="$command -H @$API_T_FILE"
  fi
  if [ "$method" != "GET" ]; then
    echo $data>$API_D_FILE
    local command="$command --json @$API_D_FILE"
  fi
  echo C: $command >> $log_file
  local response=$($command 2>&1)
  API_EXITCODE=$?
  API_STATUS=$(cat $API_H_FILE | head -n 1 | cut -d \  -f 2)
  echo E: $API_EXITCODE >> $log_file
  echo S: $API_STATUS >> $log_file
  echo R: $response >> $log_file
  echo H: >> $log_file
  cat $API_H_FILE >> $log_file
  echo C: >> $log_file
  cat $API_C_FILE >> $log_file

  echo $response
  return $(($API_STATUS))
}
