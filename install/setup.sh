#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
log_file=${SCRIPT_DIR}/log/setup.log

mkdir -p ${SCRIPT_DIR}/log

if ! id -Gn | grep '\bdocker\b' > /dev/null; then
    echo -e "\nNot installed corectly. Exiting." | tee $log_file
    exit
fi

source ${SCRIPT_DIR}/env.sh

echo -e "\nService Setup\n" | tee $log_file

mkdir -p ${PROJECT_ROOT}/config
mkdir -p ${PROJECT_ROOT}/data/downloads
mkdir -p ${PROJECT_ROOT}/data/tmp

#create-docker-compose

docker_compose=${PROJECT_ROOT}/docker-compose.yml

cat > $docker_compose << EOF
name: ${PROJECT_NAME}
services:
EOF

for service in ${SERVICES}; do
  echo -e "Installing service '$service' ..." | tee -a $log_file
  cd ${PROJECT_ROOT}/install/apps/$service && source install.sh
  docker compose --env-file $ENV_FILE convert | grep "^services:" -A 999 | grep "networks:" -B 999 | grep -Ev "^(networks|services):" >> $docker_compose
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
docker compose pull -q

if ! docker network ls | grep -q ${DOCKER_NETWORK}; then
  echo -e "\nCreating network '${DOCKER_NETWORK}' ..." | tee -a $log_file
  docker network create ${DOCKER_NETWORK} >>$log_file 2>&1
  echo -e "\nStarting containers ..." | tee -a $log_file
  docker compose up --no-color -d
else
  echo -e "\nRestarting containers ..." | tee -a $log_file
  docker compose up --force-recreate --no-color -d
fi

#post configuration
echo -e "\nSetting up services ..." | tee -a $log_file

for service in ${SERVICES}; do
  if [ -f ${PROJECT_ROOT}/install/apps/$service/setup.sh ]; then
    echo -e "\nSetting up service '$service' ..." | tee -a $log_file
    cd ${PROJECT_ROOT}/install/apps/$service && source setup.sh
  fi
done

cd ${PROJECT_ROOT}

echo -e "\nDone." | tee -a $log_file
echo -e "\nOpen https://homepage.${DOMAIN} page.\n" | tee -a $log_file
