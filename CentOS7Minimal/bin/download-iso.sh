#!/usr/bin/env bash

set -o pipefail

RESULT=0
trap catch_errors ERR
function catch_errors() {
  RESULT=$?
}

SCRIPT_BASEDIR="$(dirname $(readlink -f "${BASH_SOURCE[0]}"))"
HOME_BASEDIR="$(dirname $(readlink -f "${SCRIPT_BASEDIR}"))"
PARENT_HOME_BASEDIR="$(dirname $(readlink -f "${HOME_BASEDIR}"))"
cd ${HOME_BASEDIR}
set -e
source ${HOME_BASEDIR}/conf/settings.conf

echo "INFO: show environment variables"
env | egrep '^PACKER_|^SO_|^VBOXPATH=|^QEMUPATH=|^PATH=' | sort

mkdir -p ${PARENT_HOME_BASEDIR}/isos
cd ${PARENT_HOME_BASEDIR}/isos

echo "INFO: Get <${SO_ISOURLIMAGE}> into <${PARENT_HOME_BASEDIR}/isos> if already is not downloaded"
if [ ! -f ${SO_ISOIMAGENAME} ]
then
  curl -L -O ${SO_ISOURLIMAGE}
fi

echo "INFO: Get <${SO_ISOURLSHA256SUM}> into  <${PARENT_HOME_BASEDIR}/isos> if already is not downloaded"
if [ ! -f ${SO_ISOSHA256SUMNAME} ]
then
  curl -L -o ${SO_ISOSHA256SUMNAME} ${SO_ISOURLSHA256SUM}
fi

cd ${HOME_BASEDIR}

