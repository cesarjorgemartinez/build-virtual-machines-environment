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
source ${HOME_BASEDIR}/conf/vm.conf

echo "INFO: show environment variables"
env | egrep '^PACKER_|^SO_|^PATH=' | sort

mkdir -p ${SO_ARTIFACT_DIR}/isos
cd ${SO_ARTIFACT_DIR}/isos

echo "INFO: Get <${SO_ISOURLIMAGE}> into <${SO_ARTIFACT_DIR}/isos> if already is not downloaded"
curl -C - -L -o ${SO_ISOIMAGENAME} "${SO_ISOURLIMAGE}"

echo "INFO: Get <${SO_ISOURLSHA256SUM}> into  <${SO_ARTIFACT_DIR}/isos> if already is not downloaded"
curl -C - -L -o ${SO_ISOSHA256SUMNAME} "${SO_ISOURLSHA256SUM}"

cd ${HOME_BASEDIR}

