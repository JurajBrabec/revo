#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

data=${PROJECT_ROOT}/data/homepage

mkdir -p $data
