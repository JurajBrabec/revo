#!/bin/bash

if [ ! -d ${INSTALL_DIR}/data ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

mkdir -p =${INSTALL_DIR}/data/portainer
