#!/bin/bash
set -e
set -o pipefail

## install ipcalc package - https://snapcraft.io/install/gum/debian
if [  -n "$(uname -a | grep -i ubuntu)" ]; then
    sudo apt-get update -y && sudo apt-get install -y ipcalc
fi  
