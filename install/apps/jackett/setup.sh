#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh

add_indexer () {
  echo -e "Adding indexer '$1' ..." | tee -a $log_file
  response=$(api_call 'GET' '/api/v2.0/indexers/'$1'/config')
  if [ $? != 200 ]; then
    echo -e "!!! ERROR $?" | tee -a $log_file
    return
  fi
  response=$(api_call 'POST' '/api/v2.0/indexers/'$1'/config' "$response")
  if [ $? != 204 ]; then
    echo -e "!!! ERROR $?" | tee -a $log_file
    return
  fi
}

api_open "jackett.${DOMAIN}"

api_content_type 'application/x-www-form-urlencoded'
echo -e "Logging in ..." | tee -a $log_file
response=$(api_call 'POST' '/UI/Dashboard' 'password='${BASICAUTH_PASSWORD})
if [ $? != 46 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi
api_content_type 'application/json'

echo -e "Retrieving API key ..." | tee -a $log_file
response=$(api_call 'GET' '/api/v2.0/server/config')
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi
api_key=$(echo $response | jq -j '.api_key')
set_env 'JACKETT_API_KEY' "$api_key"

echo -e "Modifying configuration ..." | tee -a $log_file
config=$(echo $response | jq '.blackholedir="/downloads"|.updatedisabled=true')
response=$(api_call 'POST' '/api/v2.0/server/config' "$config")
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

for indexer in ${JACKETT_INDEXERS}; do
  add_indexer "$indexer"
done

echo -e "Changing admin password ..." | tee -a $log_file
response=$(api_call 'POST' '/api/v2.0/server/adminpassword' '"'${BASICAUTH_PASSWORD}'"')
if [ $? != 204 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

echo 'Success.' | tee -a $log_file

api_clean
