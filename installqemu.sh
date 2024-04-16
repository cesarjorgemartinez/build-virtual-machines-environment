#!/usr/bin/env bash

set -o pipefail
set -o errtrace

# The variable ON_ERROR only takes exit for exit inmediately or return for only inform the error presence
ON_ERROR=exit
RESULT=0
trap catch_errors ERR
function catch_errors() {
  RESULT=$?
  echo "ERROR: Command ${BASH_COMMAND} line ${LINENO} failed with code ${RESULT}"
  ${ON_ERROR} ${RESULT}
}

if git status &> /dev/null
then
  SCRIPT_BASEDIR=$(git rev-parse --show-toplevel)
else
  SCRIPT_BASEDIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
fi
PROGNAME="$(basename ${0})"
cd ${SCRIPT_BASEDIR}

# TODO THE HELP AND HOWTO UNINSTALL
#
# cygstart --wait --action=runas "/cygdrive/c/Program Files/qemu/qemu-uninstall.exe /S"
# [[ -f "/cygdrive/c/Program Files/qemu/qemu-uninstall.exe" ]] && echo SI

QEMU_URL_DOWNLOAD="$(lynx -dump -listonly -nonumbers https://qemu.weilnetz.de/w64 | grep 'qemu-w64-setup-.*.exe' | sort -r | head -1)"
echo "INFO: Get lastest QEMU Binaries for Windows (64 bit) <${QEMU_URL_DOWNLOAD}>"
[[ "${QEMU_URL_DOWNLOAD}" == "" ]] && echo "ERROR: Cannot get lastest QEMU Binaries for Windows (64 bit)" && exit 1
echo "INFO: Download from <${QEMU_URL_DOWNLOAD}>"
curl -L -O ${QEMU_URL_DOWNLOAD}
if [[ "${RESULT}" == "0" ]]
then
  echo "INFO: Install <$(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')>"
  chmod 755 $(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')
  cygstart --wait --action=runas "$(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')" /S
  echo "INFO: Done"
fi
rm -f $(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')

