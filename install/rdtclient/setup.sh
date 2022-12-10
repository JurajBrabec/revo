#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

source ${PROJECT_ROOT}/install/api.sh

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

response=$(api 'GET' '/Api/Authentication/IsLoggedIn')
if  echo $response | grep "Setup required" > /dev/null; then
  echo -e "Setting up '${BASICAUTH_USERNAME}' user..." | tee -a $log_file
  response=$(api 'POST' '/Api/Authentication/Create' \
    '{"userName": "'${BASICAUTH_USERNAME}'","password": "'${BASICAUTH_PASSWORD}'"}')
  if [ $? != 200 ]; then
    echo -e "!!! ERROR" | tee -a $log_file
  fi

  if [ -n "$RDTCLIENT_PROVIDER" ]; then
    echo -e "Setting up '${name}' provider..." | tee -a $log_file
    response=$(api 'POST' '/Api/Authentication/SetupProvider' \
      '{"provider": "'${RDTCLIENT_PROVIDER}'","token": "'${RDTCLIENT_TOKEN}'"}')
    if [ $? != 200 ]; then
      echo -e "!!! ERROR" | tee -a $log_file
    fi
  else
    echo -e "No provider selected." | tee -a $log_file
  fi
else
  echo -e "No user set up required." | tee -a $log_file
fi

echo -e "Logging in as '${BASICAUTH_USERNAME}'..." | tee -a $log_file
response=$(api 'POST' '/Api/Authentication/Login' \
  '{"userName": "'${BASICAUTH_USERNAME}'","password": "'${BASICAUTH_PASSWORD}'"}')
if [ $? != 200 ]; then
  echo -e "!!! ERROR" | tee -a $log_file
fi

echo -e "Setting up settings..." | tee -a $log_file
response=$(api 'PUT' '/Api/Settings' \
  '[{"key": "DownloadClient:MappedPath","value": "/downloads","type": "String"}]')
if [ $? != 200 ]; then
  echo -e "!!! ERROR" | tee -a $log_file
fi
echo -e "Success." | tee -a $log_file

api_clean
