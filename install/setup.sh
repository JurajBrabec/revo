#!/bin/bash
OPTIONAL_SERVICES='bazarr jackett lidarr lldap pihole portainer prowlarr radarr rdtclient sonarr syncthing uptime watchtower whisparr homepage'
SERVICES="traefik"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
env_file=${SCRIPT_DIR}/.env
log_file=${SCRIPT_DIR}/log/setup.log

mkdir -p ${SCRIPT_DIR}/log

if ! id -Gn | grep '\bdocker\b' > /dev/null; then
    echo -e "\nNot installed corectly. Exiting." | tee $log_file
    exit
fi

echo -e "\nService Setup\n" | tee $log_file

set -a; source $env_file; set +a

IP_ADDRESS=$(hostname -I | cut -d \  -f 1)

for service in ${OPTIONAL_SERVICES}; do
  IS_ENABLED=${service^^}_ENABLED
  if [ ! -z ${!IS_ENABLED} ]; then
    SERVICES="${SERVICES} $service"
  fi
done

mkdir -p ${PROJECT_ROOT}/config
mkdir -p ${PROJECT_ROOT}/data/downloads
mkdir -p ${PROJECT_ROOT}/data/share/movies
mkdir -p ${PROJECT_ROOT}/data/share/music
mkdir -p ${PROJECT_ROOT}/data/share/tv
mkdir -p ${PROJECT_ROOT}/data/share/xxx
mkdir -p ${PROJECT_ROOT}/data/tmp

#create-docker-compose

docker_compose=${PROJECT_ROOT}/docker-compose.yml

cat > $docker_compose << EOF
name: ${PROJECT_NAME}
services:
EOF

for service in ${SERVICES}; do
  if [ -f ${PROJECT_ROOT}/install/$service/install.sh ]; then
    echo -e "Installing service '$service' ..." | tee -a $log_file
    cd ${PROJECT_ROOT}/install/$service
    . ${PROJECT_ROOT}/install/$service/install.sh
    docker compose --env-file $env_file convert | grep "^services:" -A 999 | grep "networks:" -B 999 | grep -Ev "^(networks|services):" >> $docker_compose
  fi
done

cat >> $docker_compose << EOF
networks:
  default:
    external: true
    name: ${DOCKER_NETWORK}
EOF

cd ${PROJECT_ROOT}

#start-docker

echo -e "\nPulling images ..." | tee -a $log_file
docker compose pull

if ! docker network ls | grep ${DOCKER_NETWORK} >/dev/null; then
  echo -e "\nCreating network '${DOCKER_NETWORK}'..." | tee -a $log_file
  docker network create ${DOCKER_NETWORK} >>$log_file 2>&1
  echo -e "\nStarting containers ..." | tee -a $log_file
  docker compose up -d
else
  echo -e "\nRestarting containers ..." | tee -a $log_file
  docker compose restart
fi

#post configuration
echo -e "\nChecking accessibility ..." | tee -a $log_file
sleep 10

for service in ${SERVICES}; do
  if [ -f ${PROJECT_ROOT}/install/$service/setup.sh ]; then
    echo -e "\nSetting up service '$service' ..." | tee -a $log_file
    . ${PROJECT_ROOT}/install/$service/setup.sh
  fi
done

cd ${PROJECT_ROOT}

echo -e "\nDone." | tee -a $log_file
echo -e "\nOpen https://homepage.${DOMAIN} page.\n" | tee -a $log_file
