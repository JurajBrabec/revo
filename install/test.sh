#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${SCRIPT_DIR}/env.sh
source ${SCRIPT_DIR}/api.sh

IP_ADDRESS=$(hostname -I | cut -d \  -f 1)

src=${PROJECT_ROOT}/install/portainer
log_file=${PROJECT_ROOT}/install/test.log

echo START > $log_file

api_open 'portainer'
response=$(api_call 'POST' '/api/auth' \
  '{"username": "'${BASICAUTH_USERNAME}'","password": "'${BASICAUTH_PASSWORD}'"}')
echo "$?:$response"
