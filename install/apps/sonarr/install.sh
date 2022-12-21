#!/bin/bash

if [ ! -d ${INSTALL_DIR}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

mkdir -p ${INSTALL_DIR}/config/sonarr
mkdir -p ${DOWNLOADS_DIR}/sonarr
mkdir -p ${SHARE_DIR}/tv
