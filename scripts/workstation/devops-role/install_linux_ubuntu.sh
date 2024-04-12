#!/usr/bin/env bash

set -ex
set -o pipefail

## install common debian packages
if [  -n "$(cat /etc/lsb-release | grep -i ubuntu)" ]; then
  sudo apt-get update -y && \
  sudo apt-get install -y \
    wget \
    tree \
    vim \
    bash-completion \
    python3 \
    shellcheck
fi