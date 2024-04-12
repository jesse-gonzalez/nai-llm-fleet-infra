#!/usr/bin/env bash

set -ex
set -o pipefail

## install gum package
GUM=0.13.0

curl --silent --location "https://github.com/charmbracelet/gum/releases/download/v${GUM}/gum_${GUM}_Linux_x86_64.tar.gz" | sudo tar xz -C /tmp2

sudo mv /tmp2/gum /usr/local/bin
sudo chmod +x /usr/local/bin/gum

gum --help

