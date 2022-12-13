#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

src=./config

envsubst < $src/docker.yaml > $conf/docker.yaml
envsubst < $src/settings.yaml > $conf/settings.yaml
envsubst < $src/widgets.yaml > $conf/widgets.yaml
envsubst < $src/services.yaml > $conf/services.yaml

for service in ${OPTIONAL_SERVICES}; do
  if ! echo ${SERVICES} | grep -qi $service; then
    sed -i '/#'$service'/, /#/ {//!d}' $conf/services.yaml
  fi
done
sed -i '/#/d' $conf/services.yaml

echo -e "Success." | tee -a $log_file
