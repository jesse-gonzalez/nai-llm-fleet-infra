#!/bin/bash
set -e
set -o pipefail

## install gum package - https://snapcraft.io/install/gum/debian
GUM=0.13.0

sudo curl "https://github.com/charmbracelet/gum/releases/download/v${GUM}/gum-${GUM}.tar.gz" --silent --location
sudo tar xz -C /tmp
sudo mv /tmp/gum /usr/local/bin/
sudo chmod +x /usr/local/bin/gum
