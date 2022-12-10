#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${PROJECT_ROOT}/config/pihole
src=${PROJECT_ROOT}/install/pihole/config

mkdir -p $conf
cp -rf $src/* $conf

#sed -i 's/${IP_ADDRESS}/'${IP_ADDRESS}'/g' $conf/pihole/custom.list
#export IP_ADDRESS
#envsubst < $src/pihole/custom.list > $conf/pihole/custom.list

for service in ${SERVICES}; do
  echo $IP_ADDRESS $service.${DOMAIN} >> $conf/pihole/custom.list
done
