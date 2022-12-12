#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh

api_open "portainer.${DOMAIN}"

echo -e "Logging in as '${BASICAUTH_USERNAME}'..." | tee -a $log_file
response=$(api_call 'POST' '/api/auth' \
  '{"username": "'${BASICAUTH_USERNAME}'","password": "'${BASICAUTH_PASSWORD}'"}')
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

echo -e "Creating access token..." | tee -a $log_file
api_token "Authorization: Bearer $(echo $response | jq -j '.jwt')"
response=$(api_call 'POST' '/api/users/1/tokens' '{"description": "homepage"}')
if [ $? != 201 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

token=$(echo $response | jq -j '.rawAPIKey')
set_env 'PORTAINER_ACCESS_TOKEN' "$token"

echo 'Success.' | tee -a $log_file

api_clean