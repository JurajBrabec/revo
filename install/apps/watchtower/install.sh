#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${PROJECT_ROOT}/config/watchtower

mkdir -p $conf

# https://containrrr.dev/shoutrrr/v0.6/services/overview/

if echo "${NOTIFICATION_URL}" | grep -qi 'discord'; then
  token=$(echo $NOTIFICATION_URL | cut -d / -f 7)
  webhookid=$(echo $NOTIFICATION_URL | cut -d / -f 6)
  WATCHTOWER_NOTIFICATION_URL="discord://$token@$webhookid"
fi

if echo "${NOTIFICATION_URL}" | grep -qi 'pushbullet'; then
  WATCHTOWER_NOTIFICATION_URL="${NOTIFICATION_URL}"
fi

export WATCHTOWER_NOTIFICATION_URL