#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${PROJECT_ROOT}/config/pihole

mkdir -p $conf
cp -rf ./config/* $conf

for service in ${SERVICES}; do
  echo $IP_ADDRESS $service.${DOMAIN} >> $conf/pihole/custom.list
done
