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

echo "INFO: show environment variables"
env | egrep "^PACKER_|^QEMUIMG_|^SO_" | sort

mkdir -p ${HOME_BASEDIR}/images
cd ${HOME_BASEDIR}/images

echo "INFO: Get vmdk file inside ${HOME_BASEDIR}/images"
VMDK_FILENAME="$(find *.vmdk 2>/dev/null || true)"

if [ "${VMDK_FILENAME}" == "" ]
then
  echo "ERROR: Can not find any vmdk file"
  exit 1
fi
ONLYNAME_IMAGE="$(basename -s .vmdk ${VMDK_FILENAME})"

echo "INFO: Convert vmdk file to qcow2"
${HOME_BASEDIR}/software/qemu-img.exe convert -c \
-f vmdk ${ONLYNAME_IMAGE}.vmdk \
-O qcow2 ${ONLYNAME_IMAGE}.qcow2

echo "INFO: Create ova file from vmdk and ovf files"
tar cf ${ONLYNAME_IMAGE}.ova \
${ONLYNAME_IMAGE}.vmdk \
${ONLYNAME_IMAGE}.ovf

echo "INFO: Convert vmdk file to vdi"
${HOME_BASEDIR}/software/qemu-img.exe convert \
-f vmdk ${ONLYNAME_IMAGE}.vmdk \
-O vdi ${ONLYNAME_IMAGE}.vdi

echo "INFO: Convert vmdk file to vhd dynamic"
${HOME_BASEDIR}/software/qemu-img.exe convert -o subformat=dynamic \
-f vmdk ${ONLYNAME_IMAGE}.vmdk \
-O vpc ${ONLYNAME_IMAGE}-dynamic.vhd

if [ "${SO_CONVERTFIXED_VHD_VHDX_IMAGES,,}" == "true" ]
then
  echo "INFO: Convert vmdk file to vhd fixed"
  ${HOME_BASEDIR}/software/qemu-img.exe convert -o subformat=fixed \
  -f vmdk ${ONLYNAME_IMAGE}.vmdk \
  -O vpc ${ONLYNAME_IMAGE}-fixed.vhd
fi

echo "INFO: Convert vmdk file to vhdx dynamic"
${HOME_BASEDIR}/software/qemu-img.exe convert -o subformat=dynamic \
-f vmdk ${ONLYNAME_IMAGE}.vmdk \
-O vhdx ${ONLYNAME_IMAGE}-dynamic.vhdx

if [ "${SO_CONVERTFIXED_VHD_VHDX_IMAGES,,}" == "true" ]
then
  echo "INFO: Convert vmdk file to vhdx fixed"
  ${HOME_BASEDIR}/software/qemu-img.exe convert -o subformat=fixed \
  -f vmdk ${ONLYNAME_IMAGE}.vmdk \
  -O vhdx ${ONLYNAME_IMAGE}-fixed.vhdx
fi

cd ${HOME_BASEDIR}

