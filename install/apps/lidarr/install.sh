#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

mkdir -p ${PROJECT_ROOT}/config/lidarr
mkdir -p ${PROJECT_ROOT}/data/downloads/lidarr
mkdir -p ${PROJECT_ROOT}/data/share/music
