#!/usr/bin/env bash

set -ex
set -o pipefail

TEMPDIR="$(mktemp -d)"
cd $TEMPDIR

CLI_TOOL_NAME="dkp"
VERSION="v2.7.1"

## easier for handling darwin vs linux use cases
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/')"
BINARY="${CLI_TOOL_NAME}_${VERSION}_${OS}_${ARCH}"
BIN_URL="https://downloads.d2iq.com/dkp/${VERSION}/${BINARY}.tar.gz"

### Example urls for Darwin and Linux
## https://downloads.d2iq.com/dkp/v2.7.1/dkp_darwin_amd64_v2.7.1.tar.gz
## https://downloads.d2iq.com/dkp/v2.7.1/dkp_v2.7.1_linux_amd64.tar.gz

echo "Downloading ${CLI_TOOL_NAME} cli from $BIN_URL"

curl -fsSLO "${BIN_URL}"
tar zxvf "${BINARY}.tar.gz"
sudo mv $TEMPDIR/${CLI_TOOL_NAME} /usr/local/bin
chmod +x /usr/local/bin/${CLI_TOOL_NAME}

## cleanup
rm $TEMPDIR/${BINARY}.tar.gz

# validate
dkp version