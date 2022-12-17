#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh

api_open "portainer.${DOMAIN}"

echo -e "Logging in as '${USERNAME}' ..." | tee -a $log_file
api_call 'POST' '/api/auth' '{"username": "'${USERNAME}'","password": "'${PASSWORD}'"}'
if [ $(api_status) == 200 ]; then
  echo -e "Creating access token ..." | tee -a $log_file
  api_token "Authorization: Bearer $(echo $(api_data) | jq -j '.jwt')"
  api_call 'POST' '/api/users/1/tokens' '{"description": "homepage"}'
  if [ $(api_status) == 201 ]; then
    token=$(echo $(api_data) | jq -j '.rawAPIKey')
    set_env 'PORTAINER_ACCESS_TOKEN' "$token"
    echo 'Success.' | tee -a $log_file
    api_clean
    return 0
  fi
fi
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
