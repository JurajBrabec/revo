#!/bin/bash

if [ ! -d ${INSTALL_DIR}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${INSTALL_DIR}/config/pihole

mkdir -p $conf
cp -rf ./config/* $conf

for service in ${SERVICES}; do
  echo $IP_ADDRESS $service.${DOMAIN} >> $conf/pihole/custom.list
done
