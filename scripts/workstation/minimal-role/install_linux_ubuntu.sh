#!/usr/bin/env bash

set -ex
set -o pipefail

## install common debian packages
if grep -q -i ubuntu /etc/os-release; then
  sudo apt-get update -y && \
  sudo apt-get install -y \
    wget \
    apache2-utils
fi