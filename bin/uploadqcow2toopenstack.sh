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
env | egrep '^PACKER_|^SO_|^VBOXPATH=|^QEMUPATH=|^PATH=' | sort

mkdir -p ${HOME_BASEDIR}/images
cd ${HOME_BASEDIR}/images

echo "INFO: Get qcow2 file inside ${HOME_BASEDIR}/images"
QCOW2_FILENAME="$(find *.qcow2 2>/dev/null || true)"

if [ "${QCOW2_FILENAME}" == "" ]
then
  echo "ERROR: Cannot find any qcow2 file"
  exit 1
fi
ONLYNAME_IMAGE="$(basename -s .qcow2 ${QCOW2_FILENAME})"

echo "INFO: Check availability of openstack command"
openstack --version > /dev/null 2>&1 || { echo "ERROR: The openstack command not found"; exit 1; }

echo "INFO: Remember to export these OpenStack variables to upload the image correcty"
echo "export OS_TENANT_NAME=<tenant_name>"
echo "export OS_PROJECT_NAME=<project_name>"
echo "export OS_TENANT_ID=<tenant_id>"
echo "export OS_PROJECT_ID=<project_id>"
echo "export OS_AUTH_URL=<openstack_auth_url>"
echo "export OS_USERNAME=<openstack_username>"
echo "export OS_PASSWORD=<openstack_userpass>"

echo "INFO: Upload qcow2 image ${ONLYNAME_IMAGE} to OpenStack"
for qcow2image in $(openstack --insecure image list -f value -c Name --name "${ONLYNAME_IMAGE}")
do
  openstack --insecure image delete ${qcow2image}
done

openstack --insecure image create ${ONLYNAME_IMAGE} --disk-format qcow2 --file ${QCOW2_FILENAME}

cd ${HOME_BASEDIR}

