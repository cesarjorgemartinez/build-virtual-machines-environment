#!/usr/bin/env bash

set -o pipefail

RESULT=0
trap catch_errors ERR
function catch_errors() {
  RESULT=$?
}

SCRIPT_BASEDIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
cd ${SCRIPT_BASEDIR}
set -e

rm -rf ${SCRIPT_BASEDIR}/qemuinstaller
mkdir -p ${SCRIPT_BASEDIR}/qemuinstaller
cd ${SCRIPT_BASEDIR}/qemuinstaller

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

