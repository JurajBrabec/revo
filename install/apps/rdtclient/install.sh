#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

mkdir -p ${PROJECT_ROOT}/config/rdtclient
mkdir -p ${PROJECT_ROOT}/data/rdtclient
