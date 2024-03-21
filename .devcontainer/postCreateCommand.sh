#!/usr/bin/env bash
set -e
set -o noglob

## install task
#[ -n "$(command -v arkade)" ] || sudo sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

task workstation:arkade
