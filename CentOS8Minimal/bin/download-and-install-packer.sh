#!/usr/bin/env bash

set -o pipefail

RESULT=0
trap catch_errors ERR
function catch_errors() {
  RESULT=$?
}

SCRIPT_BASEDIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
HOME_BASEDIR="$(dirname $(readlink -f "${SCRIPT_BASEDIR}"))"
cd ${HOME_BASEDIR}
set -e
source ${HOME_BASEDIR}/conf/virtual-machine.conf

echo "INFO: show environment variables"
env | egrep '^PACKER_|^SO_|^PATH=' | sort

echo "INFO: Get packer software <${PACKER_VERSION}> into <${HOME_BASEDIR}/packer.zip>"
if [ "${PACKER_VERSION}" == "nightly" ]
then
  curl -L -o ${HOME_BASEDIR}/packer.zip $(curl -L -s 'https://api.github.com/repos/hashicorp/packer/releases/tags/nightly' | jq -r '.assets[] | select(.browser_download_url | endswith("windows_amd64.zip")) | .browser_download_url')
else
  curl -L -o ${HOME_BASEDIR}/packer.zip  https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_windows_amd64.zip
fi

echo "INFO: Unzip packer ${PACKER_VERSION}"
unzip -L -o packer.zip 'packer*'
chmod 755 *.exe
echo "INFO: Show packer version from the executable: $(${HOME_BASEDIR}/packer --version)"

cd ${HOME_BASEDIR}

