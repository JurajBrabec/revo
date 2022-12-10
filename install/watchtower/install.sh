#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${PROJECT_ROOT}/config/watchtower

mkdir -p $conf