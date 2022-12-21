#!/bin/bash

if [ ! -d ${INSTALL_DIR}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${INSTALL_DIR}/config/homepage

mkdir -p $conf
cp -rf ./config/* $conf
