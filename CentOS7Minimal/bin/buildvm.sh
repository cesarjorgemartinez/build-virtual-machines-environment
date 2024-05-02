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
source ${HOME_BASEDIR}/conf/vm.conf

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
env | egrep '^PACKER_|^SO_|^PATH=' | sort

if [ "${PACKER_MACHINEREADABLEOUTPUT,,}" == "true" ]
then
  echo "INFO: Enable Packer machine readable output"
  MACHINEREADABLEPARAMETER="-machine-readable"
fi

echo "INFO: Remove previous directories to prevent fails"
rm -rf ${HOME_BASEDIR}/output-virtualbox-iso ${HOME_BASEDIR}/packer_cache ${HOME_BASEDIR}/logs

echo "INFO: Always be verbose"
export PACKER_LOG=1
mkdir -p ${HOME_BASEDIR}/logs
export PACKER_LOG_PATH="logs/packerlog.txt"

echo "INFO: Obtain SO_ISOCHECKSUMIMAGE from ${SO_ISOURLSHA256SUM}"
export SO_ISOCHECKSUMIMAGE="$(grep -s "${SO_ISOIMAGENAME}" ${SO_ARTIFACT_DIR}/isos/${SO_ISOSHA256SUMNAME} | awk '{print $1}')"

echo "INFO: Validate JSON with Packer"
./packer.exe ${MACHINEREADABLEPARAMETER} validate json/vm.json

if [ "${PACKER_DEBUG,,}" == "true" ]
then
  echo "INFO: Enable Packer debug mode"
  export PACKERDEBUG="-debug"
fi

echo "INFO: Run the build with Packer"
./packer.exe build ${PACKERDEBUG} ${MACHINEREADABLEPARAMETER} -force \
-var so_adminuser=${SO_ADMINUSER} \
-var so_adminpass=${SO_ADMINPASS} \
-var so_defaultclouduser=${SO_DEFAULTCLOUDUSER} \
json/vm.json

echo "INFO: Remove references of -disk001 in generated packer files in <${HOME_BASEDIR}/output-virtualbox-iso>"
if [ -f ${HOME_BASEDIR}/output-virtualbox-iso/${SO_VMFULLNAME}-disk001.vmdk ]
then
  mv ${HOME_BASEDIR}/output-virtualbox-iso/${SO_VMFULLNAME}-disk001.vmdk ${HOME_BASEDIR}/output-virtualbox-iso/${SO_VMFULLNAME}.vmdk
fi
if [ -f ${HOME_BASEDIR}/output-virtualbox-iso/${SO_VMFULLNAME}.ovf ]
then
  sed -i -e 's/-disk001//g' ${HOME_BASEDIR}/output-virtualbox-iso/${SO_VMFULLNAME}.ovf ${HOME_BASEDIR}/output-virtualbox-iso/${SO_VMFULLNAME}.mf
fi

echo "INFO: Remove all images named as <${SO_ARTIFACT_DIR}/images/${SO_DISTRIBUTION}${SO_MAJORVERSION}.*${SO_IMAGETYPE}*>"
mkdir -p ${SO_ARTIFACT_DIR}/images
rm -rf ${SO_ARTIFACT_DIR}/images/${SO_DISTRIBUTION}${SO_MAJORVERSION}.*${SO_IMAGETYPE}*
echo "INFO: Move vmdk and ovf files from <${HOME_BASEDIR}/output-virtualbox-iso> to <${SO_ARTIFACT_DIR}/images>"
find ${HOME_BASEDIR}/output-virtualbox-iso -maxdepth 1 -type f | xargs -r -I '{}' mv {} ${SO_ARTIFACT_DIR}/images

if [ -f ${SO_ARTIFACT_DIR}/images/${SO_VMFULLNAME}.vmdk ]
then
  echo "INFO: Convert vmdk format <${SO_ARTIFACT_DIR}/images/${SO_VMFULLNAME}.vmdk> to qcow2 format <${SO_ARTIFACT_DIR}/images/${SO_VMFULLNAME}.qcow2>"
  qemu-img.exe convert -c -f vmdk -O qcow2 $(cygpath -w ${SO_ARTIFACT_DIR}/images/${SO_VMFULLNAME}.vmdk) $(cygpath -w ${SO_ARTIFACT_DIR}/images/${SO_VMFULLNAME}.qcow2)
else
  echo "ERROR: Disk file <${SO_ARTIFACT_DIR}/images/${SO_VMFULLNAME}.vmdk> not found"
fi

