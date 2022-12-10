#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${PROJECT_ROOT}/config/homepage
src=${PROJECT_ROOT}/install/homepage/config

mkdir -p $conf
cp -rf ${PROJECT_ROOT}/install/homepage/config/* $conf
