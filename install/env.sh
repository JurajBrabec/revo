SERVICES='traefik'
OPTIONAL_SERVICES='pihole portainer rdtclient jackett radarr sonarr lidarr whisparr bazarr prowlarr watchtower homepage'

ENV_FILE=${SCRIPT_DIR}/.env

set_env () {
  if [ -n "$1" ]; then
    export $1=$2
    sed -i "s/^$1=.*$/$1=$(echo $2|sed -e 's/\//\\\//g')/" $ENV_FILE
  fi
  set -a; source $ENV_FILE; set +a
}

set_env

export BASICAUTH_HASH=$(htpasswd -nbB "${BASICAUTH_USERNAME}" "${BASICAUTH_PASSWORD}" | cut -d : -f 2)
export IP_ADDRESS=$(hostname -I | cut -d \  -f 1)

for service in ${OPTIONAL_SERVICES}; do
  IS_ENABLED=${service^^}_ENABLED
  if [ ! -z ${!IS_ENABLED} ]; then
    SERVICES="${SERVICES} $service"
  fi
done
