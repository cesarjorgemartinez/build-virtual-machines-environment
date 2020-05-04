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

rm -rf ${HOME_BASEDIR}/packer-software
mkdir -p ${HOME_BASEDIR}/packer-software
cd ${HOME_BASEDIR}/packer-software

echo "INFO: show environment variables"
env | egrep '^PACKER_|^SO_|^VBOXPATH=|^QEMUPATH=|^PATH=' | sort

echo "INFO: Get packer software <${PACKER_VERSION}> into <${HOME_BASEDIR}/packer-software>"
if [ "${PACKER_VERSION}" == "nightly" ]
then
  curl -L -O https://github.com/hashicorp/packer/releases/download/nightly/packer_windows_amd64.zip
else
  curl -L -O https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_windows_amd64.zip
fi

echo "INFO: Unzip packer ${PACKER_VERSION}"
for myzip in $(find . -type f -name "*.zip")
do
  unzip ${myzip}
done
if [ "${PACKER_VERSION}" == "nightly" ]
then
  mv pkg/packer_windows_amd64 packer.exe
  rmdir pkg
fi
chmod 755 *.exe

cd ${HOME_BASEDIR}

