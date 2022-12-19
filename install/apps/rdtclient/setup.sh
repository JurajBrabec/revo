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
api_root='/Api/Authentication'

rdtclient_setup () {
  api_call 'GET' "$api_root/IsLoggedIn"
  if ! echo $(api_data) | grep -qi "Setup required"; then
    echo -e "No user set up required." | tee -a $log_file
    return 0
  fi
  echo -e "Setting up '${USERNAME}' user ..." | tee -a $log_file
  api_call 'POST' "$api_root/Create" '{"userName": "'${USERNAME}'","password": "'${PASSWORD}'"}'
  if [ $(api_status) == 200 ]; then
    if [ "$RDTCLIENT_PROVIDER" == "" ]; then
      echo -e "No provider selected." | tee -a $log_file
      return 0
    fi
    echo -e "Setting up '${name}' provider ..." | tee -a $log_file
    api_call 'POST' "$api_root/SetupProvider" '{"provider": "'${RDTCLIENT_PROVIDER}'","token": "'${RDTCLIENT_TOKEN}'"}'
    if [ $(api_status) == 200 ]; then
      return 0
    fi
  fi
  return -1
}

rdtclient_login () {
  echo -e "Logging in as '${USERNAME}' ..." | tee -a $log_file
  api_call 'POST' "$api_root/Login" '{"userName": "'${USERNAME}'","password": "'${PASSWORD}'"}'
  if [ $(api_status) == 200 ]; then
    return 0
  fi
  return -1
}

rdtclient_config () {
  echo -e "Modifying configuration ..." | tee -a $log_file
  api_call 'PUT' '/Api/Settings' '[{"key": "General:DownloadLimit","value": 5,"type": "Int32"},{"key": "DownloadClient:MappedPath","value": "/downloads","type": "String"},{"key": "Watch:Path","value": "/data/downloads","type": "String"}]'
  if [ $(api_status) == 200 ]; then
    return 0
  fi
  return -1
}

rdtclient_setup && rdtclient_login && rdtclient_config && {
  docker restart portainer > /dev/null
  echo 'Success.' | tee -a $log_file
  api_clean
  return 0
}
echo -e "!!! ERROR $(api_status)" | tee -a $log_file
api_clean
return -1
