#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
env_file=${SCRIPT_DIR}/.env
log_file=${SCRIPT_DIR}/log/install.log

#if [[ $(/usr/bin/id -u) -ne 0 ]]; then
#    echo -e "Not running as root." | tee -a $log_file
#    exit
#fi

mkdir -p ${SCRIPT_DIR}/log

echo -e "\nSystem Installation\n" | tee $log_file

set -a; source $env_file; set +a

chmod +x ${SCRIPT_DIR}/*.sh

sudo echo -e "\nUpdating system ..." | tee -a $log_file
sudo apt update >>$log_file 2>&1
echo -e "Upgrading system ..." | tee -a $log_file
sudo apt upgrade -y >>$log_file 2>&1

echo -e "Installing dependencies..." | tee -a $log_file
sudo apt install -y apache2-utils apt-transport-https ca-certificates curl software-properties-common >>$log_file 2>&1

echo -e "Installing 'docker'..." | tee -a $log_file
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - >>$log_file 2>&1
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" >>$log_file 2>&1
sudo apt install -y docker-ce >>$log_file 2>&1

latest_version="$(curl -s https://api.github.com/repos/docker/compose/releases | grep -m 1 "html_url" | cut -d\" -f4 | cut -d/ -f8)"

echo -e "Installing 'docker compose' ${latest_version}..." | tee -a $log_file
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose >>$log_file 2>&1
chmod +x ~/.docker/cli-plugins/docker-compose

sudo usermod -aG docker ${USER}

echo -e "Disabling resolved..." | tee -a $log_file
sudo lsof -i :53 >>$log_file 2>&1
sudo sed -i 's/^#DNS=.*/DNS=127.0.0.1/' /etc/systemd/resolved.conf
sudo sed -i  's/^#DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo mv /etc/resolv.conf /etc/resolv.conf.backup
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl reload-or-restart systemd-resolved  | tee -a $log_file
sudo lsof -i :53 >>$log_file 2>&1

echo -e "\nIP address:" $(hostname -I | cut -d \  -f 1) | tee -a $log_file
echo -e "UID / GID :" $(id | cut -d " "  -f 1,2) | tee -a $log_file

echo -e "\nDone." | tee -a $log_file
echo -e "\nReboot now and continue with setup.\n" | tee -a $log_file