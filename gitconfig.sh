#!/usr/bin/env bash

set -o pipefail
set -o errtrace

# The variable ON_ERROR only takes exit for exit inmediately or return for only inform the error presence
ON_ERROR=return
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

function help ()
{
  echo "==========================================================================="
  echo "Configure Git client using global scope"
  echo "==========================================================================="
  if [ "$*" != "" ]; then echo -e "$*\n" >&2; fi
  echo "Usage: ./${PROGNAME} --git-username \"User name\" --git-useremail useremail@domain"
  echo "  --git-username The user name for Git client. Use double or single quotes to enclose"
  echo "  --git-useremail The user email for Git client"
  echo "Common options: ./${PROGNAME} [--help [all]] | <program_options_see_usage> [--debug] [--no-interactive] [--] [--options_for_wrapper_content...]"
  echo "  --help Shows this help"
  echo "  --help all Print also detailed information and examples if provided"
  echo "  --debug Sets the DEBUG environment variable to debug the program itself (not the wrapper) if used"
  echo "  --no-interactive Disable interactive questions"
  echo "  -- End of options and arguments of the program. Then all others are transferred to the wrapper content if used (\"\$@\")"
  echo "  --options_for_wrapper_content... If used a wrapper one example is --debug"
  if [[ "${HELPALL}" == "true" ]]
  then
    echo "Examples:"
    echo "  ./${PROGNAME} --git-username \"Mrs. Alice\" --git-useremail alice@yourdomain.org"
  fi
  exit 10
}

# Execute with required arguments
if [ "$#" == "0" ]; then help; fi

while [ $# -gt 0 ] ; do
  case "${1}" in
    --git-username)
      [[ "${GITMYUSERNAME}" != "" ]] && help "ERROR: Repeated parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --git-username"
      GITMYUSERNAME="${2}"
      shift
      ;;
    --git-useremail)
      [[ "${GITMYEMAIL}" != "" ]] && help "ERROR: Repeated parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --git-useremail"
      GITMYEMAIL="${2}"
      shift
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

# Default options
GITCONFIGURE=false

# Required arguments if any provided
[[ -z "${GITMYUSERNAME}" ]] && [[ ! -z "${GITMYEMAIL}" ]] && help "ERROR: Missing argument --gitusername"
[[ ! -z "${GITMYUSERNAME}" ]] && [[ -z "${GITMYEMAIL}" ]] && help "ERROR: Missing argument --gituseremail"
[[ ! -z "${GITMYUSERNAME}" ]] && [[ ! -z "${GITMYEMAIL}" ]] && GITCONFIGURE=true

# Basic verification of parameter values
echo "${GITMYUSERNAME}" | grep -Pxq '\w+|\w+((\.|,|-|_|\s)?(\w+|\.))+' || help "ERROR: The --gitusername value must be a valid value"
echo "${GITMYEMAIL}" | grep -Pxq '([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' || help "ERROR: The --gituseremail value must be a valid value"


[[ "$(type -p git)" != "/usr/bin/git" ]] && help "ERROR: Git is not installed in Cygwin"

if [[ "${GITCONFIGURE}" == "true" ]]
then
  echo "INFO: Configure Git client using global scope"
  echo "INFO: Git user name <${GITMYUSERNAME}>"
  echo "INFO: Git user email <${GITMYEMAIL}>"
  git config --global user.name "${GITMYUSERNAME}"
  git config --global user.email "${GITMYEMAIL}"
  git config --global http.sslVerify false
fi

echo "INFO: Show Git client config global scope"
git config -l --global


[[ "${RESULT}" != "0" ]] && echo "ERROR: Some errors exists. Error code ${RESULT}"
exit ${RESULT}

