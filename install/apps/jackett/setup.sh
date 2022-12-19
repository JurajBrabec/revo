#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh


jackett_configuration () {
  echo -e "Modifying configuration ..." | tee -a $log_file
  local payload=$(echo $(api_data) | jq '.blackholedir="/downloads"|.updatedisabled=true')
  api_call 'POST' "$api_root/server/config" "$payload"
  if [ $(api_status) == 200 ]; then
    return 0
  fi
  return -1
}

add_indexer () {
  echo -e "Adding indexer '$1' ..." | tee -a $log_file
  api_call 'GET' "$api_root/indexers/$1/config"
  if [ $(api_status) == 200 ]; then
    api_call 'POST' "$api_root/indexers/$1/config" "$(api_data)"
    if [ $(api_status) == 204 ]; then
      return 0
    fi
  fi
  return -1
}

jackett_indexers () {
  for indexer in ${JACKETT_INDEXERS}; do
    add_indexer "$indexer"
  done
  return $?
}

jackett_credentials () {
  echo -e "Changing admin password ..." | tee -a $log_file
  api_call 'POST' "$api_root/server/adminpassword" '"'${PASSWORD}'"'
  if [ $(api_status) == 204 ]; then
    return 0
  fi
  return -1
}

api_open "jackett.${DOMAIN}"
api_root='/api/v2.0'

echo -e "Logging in ..." | tee -a $log_file
api_call 'GET' '/UI/Login'
if [ "$(api_cookie)" == "" ]; then
  api_content_type 'application/x-www-form-urlencoded'
  api_call 'POST' '/UI/Dashboard' "password=${PASSWORD}"
fi
if [ "$(api_cookie)" != "" ]; then
  echo -e "Retrieving API key ..." | tee -a $log_file
  api_call 'GET' "$api_root/server/config"
  if [ $(api_status) == 200 ]; then
    api_content_type 'application/json'
    api_key=$(echo $(api_data) | jq -j '.api_key')
    set_env 'JACKETT_API_KEY' "$api_key"
    jackett_configuration && jackett_indexers && jackett_credentials && {
      echo 'Success.' | tee -a $log_file
      api_clean
      return 0
    }
  fi
fi
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
