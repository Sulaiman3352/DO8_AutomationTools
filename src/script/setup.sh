#!/bin/bash

#mkdir -p /etc/docker
#cat > /etc/docker/daemon.json <<EOF
#{
#  "min-api-version": "1.24"
#}
#EOF
#systemctl restart docker

#echo "[info] Created daemon file"
apt update
apt install ansible -y

echo "[info] ansible installed"
