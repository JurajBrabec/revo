#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo -e "Not running as root."
    exit
fi

su -c "mkdir -p ${SCRIPT_DIR}/log" $SUDO_USER
log_file=${SCRIPT_DIR}/log/install.log

echo -e "\nSystem Installation" | tee $log_file

chmod +x ${SCRIPT_DIR}/*.sh

echo -e "\nUpdating system ..." | tee -a $log_file
apt update >>$log_file 2>&1
echo -e "Upgrading system ..." | tee -a $log_file
apt upgrade -y >>$log_file 2>&1

echo -e "Installing dependencies ..." | tee -a $log_file
apt install -y apache2-utils apt-transport-https ca-certificates curl software-properties-common >>$log_file 2>&1

latest_version="$(curl -s https://api.github.com/repos/docker/cli/tags | grep "name" | grep -v -m 1 "beta" | cut -d \" -f 4)"

echo -e "Installing 'docker' ${latest_version} ..." | tee -a $log_file
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - >>$log_file 2>&1
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" >>$log_file 2>&1
apt install -y docker-ce >>$log_file 2>&1

latest_version="$(curl -s https://api.github.com/repos/docker/compose/releases | grep -m 1 "html_url" | cut -d\" -f4 | cut -d/ -f8)"

echo -e "Installing 'docker compose' ${latest_version} ..." | tee -a $log_file
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose >>$log_file 2>&1
chmod +x ~/.docker/cli-plugins/docker-compose

usermod -aG docker ${USER}

echo -e "Disabling resolved ..." | tee -a $log_file
lsof -i :53 >>$log_file 2>&1
sed -i 's/^#DNS=.*/DNS=127.0.0.1/' /etc/systemd/resolved.conf
sed -i  's/^#DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
mv /etc/resolv.conf /etc/resolv.conf.backup
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl reload-or-restart systemd-resolved  | tee -a $log_file
lsof -i :53 >>$log_file 2>&1

echo -e "\nIP address:" $(hostname -I | cut -d \  -f 1) | tee -a $log_file
echo -e "UID / GID :" $(su -c "id" $SUDO_USER | cut -d " "  -f 1,2) | tee -a $log_file

echo -e "\nDone." | tee -a $log_file
echo -e "\nReboot now and run '$( dirname -- "${BASH_SOURCE[0]}" )/setup.sh' to continue.\n" | tee -a $log_file

reboot --no-wall now