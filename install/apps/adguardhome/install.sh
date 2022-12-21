#!/bin/bash

if [ ! -d ${INSTALL_DIR}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${INSTALL_DIR}/config/adguardhome
data=${INSTALL_DIR}/data/adguardhome

mkdir -p $conf
mkdir -p $data

envsubst < ./config/AdGuardHome.yaml > $conf/AdGuardHome.yaml

#for service in ${SERVICES}; do
#  echo $IP_ADDRESS $service.${DOMAIN} >> $conf/pihole/custom.list
#done
