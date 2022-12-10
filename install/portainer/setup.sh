#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${PROJECT_ROOT}/install/api.sh

api_open "portainer.${DOMAIN}"

echo -e "Logging in as '${BASICAUTH_USERNAME}'..." | tee -a $log_file
response=$(api 'POST' '/api/auth' \
  '{"username": "'${BASICAUTH_USERNAME}'","password": "'${BASICAUTH_PASSWORD}'"}')
if [ $? == 200 ]; then
  echo -e "Creating access token..." | tee -a $log_file
  api_token $(echo $response | jq -j '.jwt')
  response=$(api 'POST' '/api/users/1/tokens' \
    '{"description": "homepage"}')
  if [ $? == 201 ]; then
  token=$(echo $response | jq -j '.rawAPIKey')
  export PORTAINER_ACCESS_TOKEN=$token
  sed -i "s/^PORTAINER_ACCESS_TOKEN=.*$/PORTAINER_ACCESS_TOKEN=$(echo $token|sed -e 's/\//\\\//g')/" $env_file
#  source ${PROJECT_ROOT}/install/homepage/install.sh
  echo 'Success.' | tee -a $log_file
  else
    echo -e "!!! ERROR" | tee -a $log_file
  fi
else
  echo -e "!!! ERROR" | tee -a $log_file
fi

api_clean