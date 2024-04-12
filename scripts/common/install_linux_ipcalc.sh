#!/usr/bin/env bash

set -ex
set -o pipefail

## install ipcalc package - https://snapcraft.io/install/gum/debian
if grep -q -i ubuntu /etc/os-release; then
    sudo apt-get update -y
    sudo apt-get install -y ipcalc
fi

ipcalc --version