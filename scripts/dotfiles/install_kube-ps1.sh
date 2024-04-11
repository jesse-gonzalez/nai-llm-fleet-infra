#!/bin/bash
set -e
set -o pipefail

[[ -d /opt/kube-ps1 ]] || mkdir -p /opt/kube-ps1
curl -o /opt/kube-ps1/kube-ps1.sh https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh