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
source ${HOME_BASEDIR}/conf/CentOS7Minimal.conf

rm -rf ${HOME_BASEDIR}/software
mkdir -p ${HOME_BASEDIR}/software
cd ${HOME_BASEDIR}/software

echo "INFO: show environment variables"
env | egrep "^PACKER_|^SO_" | sort

echo "INFO: Get packer software ${PACKER_VERSION}"
curl -O https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_windows_amd64.zip

echo "INFO: Unzip packer ${PACKER_VERSION}"
for myzip in $(find . -type f -name "*.zip")
do
  unzip ${myzip}
done
chmod 755 *.exe

QEMU_URL_DOWNLOAD="$(lynx -dump -listonly -nonumbers https://qemu.weilnetz.de/w64 | grep 'qemu-w64-setup-.*.exe' | sort -r | head -1)"
echo "INFO: Get lastest QEMU Binaries for Windows (64 bit) <${QEMU_URL_DOWNLOAD}>"
[[ "${QEMU_URL_DOWNLOAD}" == "" ]] && echo "ERROR: Cannot get lastest QEMU Binaries for Windows (64 bit)" && exit 1
curl -L -O ${QEMU_URL_DOWNLOAD}
echo "INFO: Please install QEMU Binaries for Windows (64 bit) using default options except for your language:
  Please select a language: English / English
  Click in OK
  Next
  I Agree
  Next
  Install
  Finish"
cygstart  --action=runas -w $(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')

mkdir -p ${HOME_BASEDIR}/isos
cd ${HOME_BASEDIR}/isos

echo "INFO: Get ${SO_ISOURLIMAGE} if already is not downloaded"
if [ ! -f ${SO_ISOIMAGENAME} ]
then
  curl -L -O ${SO_ISOURLIMAGE}
fi

echo "INFO: Get ${SO_ISOURLSHA256SUM}"
rm -f ${HOME_BASEDIR}/isos/${SO_ISOSHA256SUMNAME}
curl -L -O ${SO_ISOURLSHA256SUM}

cd ${HOME_BASEDIR}

