#!/usr/bin/env bash

set -ex
set -o pipefail

## install docker using convenience script https://docs.docker.com/engine/install/ubuntu/
curl -fsSL https://get.docker.com | sudo bash

## https://docs.docker.com/engine/install/linux-postinstall/

sudo groupadd docker -f
sudo usermod -aG docker $USER
newgrp docker

docker version

## Configure Docker to start on boot with systemd
sudo systemctl enable docker.service
sudo systemctl enable containerd.service