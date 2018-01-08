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
env | egrep "^PACKER_|^QEMUIMG_|^SO_" | sort

echo "INFO: Get packer software ${PACKER_VERSION}"
curl -O https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_windows_amd64.zip

echo "INFO: Get qemu-img software ${QEMUIMG_VERSION}"
curl -O https://cloudbase.it/downloads/qemu-img-win-x64-$(echo ${QEMUIMG_VERSION} | tr '.' '_').zip

echo "INFO: Unzip packer and qemu-img zips"
for myzip in $(find . -type f -name "*.zip")
do
  unzip ${myzip}
done

mkdir -p ${HOME_BASEDIR}/isos
cd ${HOME_BASEDIR}/isos

echo "INFO: Get ${SO_ISOURLIMAGE} if already is not downloaded"
if [[ ! -f ${SO_ISONAME} ]]
then
  curl -L -O ${SO_ISOURLIMAGE}
fi

echo "INFO: Get ${SO_ISOURLSHA256SUM}"
rm -f ${HOME_BASEDIR}/isos/${SO_ISOSHA256SUMNAME}
curl -L -O ${SO_ISOURLSHA256SUM}

cd ${HOME_BASEDIR}

