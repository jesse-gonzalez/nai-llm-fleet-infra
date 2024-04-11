#!/bin/bash
set -e
set -o pipefail

KUBIE_VERSION=v0.22.0

wget https://github.com/sbstp/kubie/releases/download/${KUBIE_VERSION}/kubie-linux-amd64 -O /usr/local/bin/kubie
chmod +x /usr/local/bin/kubie

kubie -h