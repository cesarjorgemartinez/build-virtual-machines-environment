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
PROGNAME="$(basename $0)"
cd ${HOME_BASEDIR}
set -e
source ${HOME_BASEDIR}/conf/virtual-machine.conf

function help ()
{
  echo "**************************************************************************"
  echo "Build automated machine images © CJ"
  echo "**************************************************************************"
  echo
  if [ "$*" != "" ]; then echo -e "$*\n" >&2; fi
  echo "Usage: ${PROGNAME} [--help | (--adminuser adminuser --adminpass adminpass [--defaultclouduser defaultclouduser])]"
  echo "If the --defaultclouduser parameter is not provided then this user is cloud-user"
  echo
  exit 10
}

# Execute with required arguments
if [ "$#" == "0" ]; then help; fi

args=()
while [ $# -gt 0 ] ; do
  case "$1" in
    --help)
      help
      ;;
    --adminuser)
      [[ "${ADMINUSER}" != "" ]] && help "ERROR: Unique parameter"
      ADMINUSER="yes"
      SO_ADMINUSER="$2"
      shift
      ;;
    --adminpass)
      [[ "${ADMINPASS}" != "" ]] && help "ERROR: Unique parameter"
      ADMINPASS="yes"
      SO_ADMINPASS="$2"
      shift
      ;;
    --defaultclouduser)
      [[ "${DEFAULTCLOUDUSER}" != "" ]] && help "ERROR: Unique parameter"
      DEFAULTCLOUDUSER="yes"
      SO_DEFAULTCLOUDUSER="$2"
      shift
      ;;
    -*)
      help "ERROR: Unknown option <$1>"
      ;;
    *)
      args=("${args[@]}" "$1")
      ;;
  esac
  shift || true
done

if [ ${#args[@]} -ne 0 ]; then help "ERROR: Many arguments <${args[@]}>"; fi

# Required parameters
[[ "${ADMINUSER}" == "" ]] && help "ERROR: Required parameter --adminuser"
[[ "${ADMINPASS}" == "" ]] && help "ERROR: Required parameter --adminpass"

# Optional parameters
[[ "${DEFAULTCLOUDUSER}" == "" ]] && SO_DEFAULTCLOUDUSER="cloud-user"

# Required arguments
[[ "${SO_ADMINUSER}" == "" ]] && help "ERROR: Missing argument of --adminuser"
[[ "${SO_ADMINPASS}" == "" ]] && help "ERROR: Missing argument of --adminpass"
[[ "${SO_DEFAULTCLOUDUSER}" == "" ]] && help "ERROR: Missing argument of --defaultclouduser"

echo "**************************************************************************"
echo "Build automated machine images © CJ"
echo "**************************************************************************"
echo

echo "INFO: Show environment variables"
env | egrep '^PACKER_|^SO_|^VBOXPATH=|^QEMUPATH=|^PATH=' | sort

if [ "${PACKER_MACHINEREADABLEOUTPUT,,}" == "true" ]
then
  echo "INFO: Enable Packer machine readable output"
  MACHINEREADABLEPARAMETER="-machine-readable"
fi

echo "INFO: Remove previous directories to prevent fails"
rm -rf ${HOME_BASEDIR}/output-virtualbox-iso ${HOME_BASEDIR}/packer_cache

echo "INFO: Obtain SO_ISOCHECKSUMIMAGE from ${SO_ISOURLSHA256SUM}"
export SO_ISOCHECKSUMIMAGE="$(grep -s "${SO_ISOIMAGENAME}" ${PARENT_HOME_BASEDIR}/isos/${SO_ISOSHA256SUMNAME} | awk '{print $1}')"

echo "INFO: Validate JSON with Packer"
${HOME_BASEDIR}/packer-software/packer.exe ${MACHINEREADABLEPARAMETER} validate json/virtual-machine.json


if [ "${PACKER_DEBUG,,}" == "true" ]
then
  echo "INFO: Enable Packer debug mode"
  export PACKER_LOG=1
  mkdir -p ${HOME_BASEDIR}/logs
  export PACKER_LOG_PATH="${HOME_BASEDIR}/logs/packerlog.txt"
  export PACKERDEBUG="-debug"
fi

echo "INFO: Run the build with Packer"
${HOME_BASEDIR}/packer-software/packer.exe build ${PACKERDEBUG} ${MACHINEREADABLEPARAMETER} -force \
-var so_adminuser=${SO_ADMINUSER} \
-var so_adminpass=${SO_ADMINPASS} \
-var so_defaultclouduser=${SO_DEFAULTCLOUDUSER} \
json/virtual-machine.json

echo "INFO: Remove references of -disk001 in generated packer files in <${HOME_BASEDIR}/output-virtualbox-iso>"
if [ -f ${HOME_BASEDIR}/output-virtualbox-iso/${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}-disk001.vmdk ]
then
  mv ${HOME_BASEDIR}/output-virtualbox-iso/${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}-disk001.vmdk \
    ${HOME_BASEDIR}/output-virtualbox-iso/${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}.vmdk
fi
if [ -f ${HOME_BASEDIR}/output-virtualbox-iso/${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}.ovf ]
then
  sed -i -e 's/-disk001//g' ${HOME_BASEDIR}/output-virtualbox-iso/${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}.ovf
fi

echo "INFO: Remove all images named as <${PARENT_HOME_BASEDIR}/images/${SO_DISTRIBUTION}.${SO_MAJORVERSION}*>"
mkdir -p ${PARENT_HOME_BASEDIR}/images
rm -rf ${PARENT_HOME_BASEDIR}/images/${SO_DISTRIBUTION}.${SO_MAJORVERSION}*
echo "INFO: Move vmdk and ovf files from <${HOME_BASEDIR}/output-virtualbox-iso> to <${PARENT_HOME_BASEDIR}/images>"
find ${HOME_BASEDIR}/output-virtualbox-iso -maxdepth 1 -type f | xargs -r -I '{}' mv {} ${PARENT_HOME_BASEDIR}/images

cd ${PARENT_HOME_BASEDIR}/images

echo "INFO: Get vmdk file inside <${PARENT_HOME_BASEDIR}/images>"
SEARCHFILE=".*${SO_DISTRIBUTION}${SO_FULLVERSION}-${SO_IMAGETYPE}-[0-9]*.vmdk"
VMDK_FILENAME="$(find * -type f -regex "${SEARCHFILE}" 2>/dev/null || true)"

if [ "${VMDK_FILENAME}" == "" ]
then
  echo "ERROR: Can not find any vmdk file"
  exit 1
fi
ONLYNAME_IMAGE="$(basename -s .vmdk ${VMDK_FILENAME})"

echo "INFO: VMDK file to convert <${VMDK_FILENAME}>"
echo "INFO: Image name to convert <${ONLYNAME_IMAGE}>"

echo "INFO: Convert vmdk file to qcow2"
qemu-img.exe convert -c -f vmdk ${ONLYNAME_IMAGE}.vmdk -O qcow2 ${ONLYNAME_IMAGE}.qcow2

cd ${HOME_BASEDIR}

