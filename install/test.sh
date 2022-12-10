#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
env_file=${SCRIPT_DIR}/.env

set -a; source $env_file; set +a
source ${PROJECT_ROOT}/install/api.sh

IP_ADDRESS=$(hostname -I | cut -d \  -f 1)

src=${PROJECT_ROOT}/install/portainer
log_file=${PROJECT_ROOT}/install/test.log

echo START > $log_file

api_open 'portainer'
response=$(api 'POST' '/api/auth' \
  '{"username": "'${BASICAUTH_USERNAME}'","password": "'${BASICAUTH_PASSWORD}'"}')
echo "$?:$response"
