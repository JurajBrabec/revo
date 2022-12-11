#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

src=${PROJECT_ROOT}/install/homepage/config

#sed -i 's/${DOCKER_SOCKET}/'${DOCKER_SOCKET}'/' $conf/docker.yaml

envsubst < $src/docker.yaml > $conf/docker.yaml
envsubst < $src/settings.yaml > $conf/settings.yaml
envsubst < $src/widgets.yaml > $conf/widgets.yaml
envsubst < $src/services.yaml > $conf/services.yaml

for service in ${OPTIONAL_SERVICES}; do
  IS_ENABLED=${service^^}_ENABLED
  if [ -z ${!IS_ENABLED} ]; then
    sed -i '/#'$service'/, /#/ {//!d}' $conf/services.yaml
  fi
done
sed -i '/#/d' $conf/services.yaml

echo -e "Success." | tee -a $log_file
