#!/bin/bash
set -e
set -o pipefail

## install age key-gen - https://github.com/FiloSottile/age
AGE=v1.1.1

sudo curl "https://github.com/FiloSottile/age/releases/download/${AGE}/age-${AGE}-linux-amd64.tar.gz" --silent --location
sudo tar xz -C /tmp
sudo mv /tmp/age /usr/local/bin/
sudo chmod +x /usr/local/bin/age
