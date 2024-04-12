#!/usr/bin/env bash

set -ex
set -o pipefail

## install ipcalc package - https://snapcraft.io/install/gum/debian
if [  -n "$(cat /etc/lsb-release | grep -i ubuntu)" ]; then
    sudo apt-get update -y
    sudo apt-get install -y ipcalc
fi

ipcalc --version