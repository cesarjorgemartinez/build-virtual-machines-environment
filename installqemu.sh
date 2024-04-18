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


# Global variables
TOOL_CHECKS_LIST=(qemu-img)
QEMU_CYGWINHOMEPATH="$(cygpath "${PROGRAMFILES}")/qemu"


function help ()
{
  echo "==========================================================================="
  echo "Install or uninstall the QEMU Binaries for Windows (64 bit)"
  echo "==========================================================================="
  if [ "$*" != "" ]; then echo -e "$*\n" >&2; fi
  echo "Usage: ./${PROGNAME} [--uninstall]"
  echo "  Without parameters install the QEMU Binaries for Windows (64 bit)"
  echo "  --uninstall Using this optional parameter uninstall this software if installed"
  echo "Common options: ./${PROGNAME} [--help [all]] | <program_options_see_usage> [--debug] [--no-interactive] [--] [--options_for_wrapper_content...]"
  echo "  --help Shows this help"
  echo "  --help all Print also detailed information and examples if provided"
  echo "  --debug Sets the DEBUG environment variable to debug the program itself (not the wrapper) if used"
  echo "  --no-interactive Disable interactive questions"
  echo "  -- End of options and arguments of the program. Then all others are transferred to the wrapper content if used (\"\$@\")"
  echo "  --options_for_wrapper_content... If used a wrapper one example is --debug"
  if [[ "${HELPALL}" == "true" ]]
  then
    echo "Description:"
    echo "  Download the last version of the QEMU Binaries for Windows (64 bit) from https://qemu.weilnetz.de"
    echo "  The Cygwin home PATH is <${QEMU_CYGWINHOMEPATH}>"
    echo "Examples:"
    echo "  For install:"
    echo "  ./${PROGNAME}"
    echo "  For uninstall:"
    echo "  ./${PROGNAME} --uninstall"
  fi
  exit 10
}

# Execute without required arguments
# if [ "$#" == "0" ]; then help; fi

while [ $# -gt 0 ] ; do
  case "${1}" in
    --uninstall)
      [[ "${QEMU_INSTALL}" != "" ]] && help "ERROR: Repeated parameters"
      QEMU_INSTALL=false
      ;;
    --help)
      [[ $# -eq 2 && "${2}" == "all" ]] && HELPALL=true
      help
      ;;
    --debug)
      [[ "${DEBUG}" != "" ]] && help "ERROR: Repeated parameters"
      DEBUG=true
      ;;
    --no-interactive)
      [[ "${NO_INTERACTIVE}" != "" ]] && help "ERROR: Repeated parameters"
      NO_INTERACTIVE=true
      ;;
    --)
      # End of options and arguments of the program. Then all others are transferred to the wrapper content if used ("$@")
      shift
      break
      ;;
    -*)
      help "ERROR: Unknown option <${1}>"
      ;;
    *)
      help "ERROR: Unknown argument <${1}>"
      ;;
  esac
  shift
done


# Default parameters
[[ "${QEMU_INSTALL}" != "false" ]] && QEMU_INSTALL=true


if [[ "${QEMU_INSTALL}" == "true" ]]
then
  echo "INFO: Install QEMU Binaries for Windows (64 bit)"
  QEMU_URL_DOWNLOAD="$(lynx -dump -listonly -nonumbers https://qemu.weilnetz.de/w64 | grep 'qemu-w64-setup-.*.exe' | sort -r | head -1)"
  echo "INFO: Get lastest QEMU Binaries for Windows (64 bit) <${QEMU_URL_DOWNLOAD}>"
  [[ "${QEMU_URL_DOWNLOAD}" == "" ]] && echo "ERROR: Cannot get lastest QEMU Binaries for Windows (64 bit)" && exit 1
  echo "INFO: Download from <${QEMU_URL_DOWNLOAD}>"
  curl -L -O ${QEMU_URL_DOWNLOAD}
  echo "INFO: Install <$(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')>"
  chmod 755 $(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')
  cygstart --wait --action=runas "$(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')" /S
  rm -f $(echo "${QEMU_URL_DOWNLOAD}" | sed 's#.*/##g')
  ON_ERROR=return
  for mytool in "${TOOL_CHECKS_LIST[@]}"
  do
    case ${mytool} in
      qemu-img)
        echo "--- CHECK version ${mytool}"
        ${mytool} --version
        echo "--- CHECK paths ${mytool}"
        if type -ap ${mytool}
        then
          [[ "$(type -p ${mytool})" != "${QEMU_CYGWINHOMEPATH}/qemu-img" ]] && echo "WARN: ${mytool} on the first match PATH correspond to other software"
        else
          echo "WARN: ${mytool} not found on the path"
        fi
      ;;
    esac
  done
  echo "INFO: Done"
else
  echo "INFO: Uninstall QEMU Binaries for Windows (64 bit)"
  [[ -f "${QEMU_CYGWINHOMEPATH}/qemu-uninstall.exe" ]] && cygstart --wait --action=runas "${QEMU_CYGWINHOMEPATH}/qemu-uninstall.exe" /S
  echo "INFO: Done"
fi


[[ "${RESULT}" != "0" ]] && echo "ERROR: Some errors exists. Error code ${RESULT}"
exit ${RESULT}

