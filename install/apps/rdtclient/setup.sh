#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${SCRIPT_DIR}/api.sh

if [ -n "${RDTCLIENT_REALDEBRID_TOKEN}" ]; then
  name=RealDebrid
  RDTCLIENT_PROVIDER=0
  RDTCLIENT_TOKEN=${RDTCLIENT_REALDEBRID_TOKEN}
fi

if [ -n "${RDTCLIENT_ALLDEBRID_TOKEN}" ]; then
  name=AllDebrid
  RDTCLIENT_PROVIDER=1
  RDTCLIENT_TOKEN=${RDTCLIENT_ALLDEBRID_TOKEN}
fi

api_open "rdtclient.${DOMAIN}"

response=$(api_call 'GET' '/Api/Authentication/IsLoggedIn')
if echo $response | grep -qi "Setup required"; then
  echo -e "Setting up '${USERNAME}' user ..." | tee -a $log_file
  response=$(api_call 'POST' '/Api/Authentication/Create' \
    '{"userName": "'${USERNAME}'","password": "'${PASSWORD}'"}')
  if [ $? != 200 ]; then
    echo -e "!!! ERROR $?" | tee -a $log_file
    api_clean
    return
  fi
  if [ -n "$RDTCLIENT_PROVIDER" ]; then
    echo -e "Setting up '${name}' provider ..." | tee -a $log_file
    response=$(api_call 'POST' '/Api/Authentication/SetupProvider' \
      '{"provider": "'${RDTCLIENT_PROVIDER}'","token": "'${RDTCLIENT_TOKEN}'"}')
    if [ $? != 200 ]; then
      echo -e "!!! ERROR $?" | tee -a $log_file
      api_clean
      return
    fi
  else
    echo -e "No provider selected." | tee -a $log_file
  fi
else
  echo -e "No user set up required." | tee -a $log_file
fi

echo -e "Logging in as '${USERNAME}' ..." | tee -a $log_file
response=$(api_call 'POST' '/Api/Authentication/Login' \
  '{"userName": "'${USERNAME}'","password": "'${PASSWORD}'"}')
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

echo -e "Modifying configuration ..." | tee -a $log_file
response=$(api_call 'PUT' '/Api/Settings' \
  '[{"key": "DownloadClient:MappedPath","value": "/downloads","type": "String"}]')
if [ $? != 200 ]; then
  echo -e "!!! ERROR $?" | tee -a $log_file
  api_clean
  return
fi

echo -e "Success." | tee -a $log_file

api_clean
