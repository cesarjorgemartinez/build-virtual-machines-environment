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
MINTTY_SETTINGS='Term=xterm-256color
Font=Cascadia Mono
ScrollbackLines=10000000
CursorType=block
CursorBlinks=no
ThemeFile=flat-ui
Columns=110
Rows=30
FontHeight=10
'
PS1_SETTINGS=$(cat << 'MYENDPS1'
'\\[\\e]0;\\w\\a\\]\\[\\e[32m\\]\\u@\\h:\\[\\e[33m\\]\\w\\[\\e[0m\\]\\$ '
MYENDPS1
)
CYGWIN_BASIC_PACKAGES=(
cygwin
cygport
bash
bash-completion
pcre2
dbus
util-linux
coreutils
binutils
diffutils
diffstat
colordiff
kdiff3
dos2unix
procps-ng
ca-certificates
ca-certificates-letsencrypt
gnutls
gnupg
gnupg2
keychain
curl
wget
lynx
jq
avahi
avahi-tools
vim
vim-minimal
vim-common
nano
tmux
konsole
openssl
openssh
sshpass
gcc-core
gcc-g++
autoconf
automake
make
cmake
pkg-config
pkgconf
git
gawk
whois
python3
python3-devel
python3-pip
python3-setuptools
python3-distlib
nc
nc6
dialog
figlet
ncdu
expect
rsync
gettext
tar
zip
unzip
gzip
xz
)
TOOL_CHECKS_LIST=(curl wget git python python3 pip3 jq yq openssl openssh sshpass keychain)
SSHCONFIGGENERIC='StrictHostKeyChecking no
UserKnownHostsFile /dev/null
ControlMaster yes
ControlPersist 600s
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 5
Include config.auto'
SSHCONFIGAUTO_HEADERCOMMENT='# Please do not modify this file because it is managed automatically'
VIM_SETTINGS='" Disable visual mode
set mouse-=a
" Automatically use 2 spaces instead of tab
set autoindent expandtab tabstop=2 shiftwidth=2
" Set in terminal title the edited file
set title
'
QEMU_CYGWINHOMEPATH="$(cygpath "${PROGRAMFILES}")/qemu"
YQ_URL_DOWNLOAD='https://github.com/mikefarah/yq/releases/latest/download/yq_windows_amd64.exe'
BASHRC_SETTINGS=$(cat << 'MYENDBASHRC'
# Add to the beginning of environment variable PATH one path provided as first parameter
function addpath()
{
  [[ $# -ne 1 ]] && return
  if [[ ! "$PATH" =~ "${1}" ]]
  then
    export PATH="${1}":$PATH
  fi
}
export -f addpath
# Ask one confirmation response YyNnCc. If privided the first parameter then this text is used a question
# If the variable NO_INTERACTIVE is true then it does nothing
function confirmquestion()
{
  [[ "${NO_INTERACTIVE}" == "true" ]] && return 0
  [[ "${1}" != "" ]] && textquestion="${1}. "
  while true; do
    read -p "${textquestion}Do you want to proceed? (Yy/Nn/Cc) " respquestion
    case ${respquestion} in
      [Yy]) return 0;;
      [Nn]) return 1;;
      [Cc]) exit;;
      *) echo "Please answer Yy for Yes or Nn for No or Cc for Cancel";;
    esac
  done
}
export -f confirmquestion
# Disable Windows Python installations
PATH=$(echo $PATH | tr ':' '\n' | grep -v "/cygdrive/.*/Python[23]" | paste -sd:)
# Disable Windows Git installations
PATH=$(echo $PATH | tr ':' '\n' | grep -v "/cygdrive/.*/Git/cmd" | paste -sd:)
# Disable Windows Curl installations
PATH=$(echo $PATH | tr ':' '\n' | grep -v "/cygdrive/.*/curl" | paste -sd:)
addpath /usr/sbin
addpath "/cygdrive/c/Program Files/qemu"
export PATH
# Start and configure SSH and GPG agents
keychain -q --quick --gpg2 --agents ssh,gpg
source $HOME/.keychain/$(hostname)-sh
source $HOME/.keychain/$(hostname)-sh-gpg
export DISPLAY=:0
MYENDBASHRC
)
BASHRC_SETTINGS="$(echo "${BASHRC_SETTINGS}" | sed -r 's#\$\{QEMU_CYGWINHOMEPATH\}#'"${QEMU_CYGWINHOMEPATH}"'#g')"


function help ()
{
  echo "==========================================================================="
  echo "Install and configure a basic environment for Cygwin"
  echo "==========================================================================="
  if [ "$*" != "" ]; then echo -e "$*\n" >&2; fi
  echo "Usage: ./${PROGNAME}"
  echo "Common options: ./${PROGNAME} [--help] | <program_options_see_usage> [--debug] [--no-interactive] [--] [--options_for_wrapper_content...]"
  echo "  --help Shows this help"
  echo "  --help all Print also detailed information and examples if provided"
  echo "  --debug Sets the DEBUG environment variable to debug the program itself (not the wrapper) if used"
  echo "  --no-interactive Disable interactive questions"
  echo "  -- End of options and arguments of the program. Then all others are transferred to the wrapper content if used (\"\$@\")"
  echo "  --options_for_wrapper_content... If used a wrapper one example is --debug"
  if [[ "${HELPALL}" == "true" ]]
  then
    echo "Description:"
    echo "  TODO1"
  fi
  exit 10
}

function set_sshclient ()
{
  echo "INFO: Apply SSH client settings"
  mkdir -p $HOME/.ssh
  chmod 700 $HOME/.ssh
  echo "${SSHCONFIGGENERIC}" > $HOME/.ssh/config.generic
  truncate -s 0 $HOME/.ssh/known_hosts
  touch $HOME/.ssh/authorized_keys
  touch $HOME/.ssh/config.auto
  sed -r -i '/\s*#/d' $HOME/.ssh/config.auto
  sed -i 's/\t/  /g' $HOME/.ssh/config.auto
  if [[ -s "$HOME/.ssh/config.auto" ]]
  then
    sed -i "1 i${SSHCONFIGAUTO_HEADERCOMMENT}" $HOME/.ssh/config.auto
  else
    echo "${SSHCONFIGAUTO_HEADERCOMMENT}" > $HOME/.ssh/config.auto
  fi
  if [[ -s $HOME/.ssh/config ]]
  then
    diff -u --color=auto $HOME/.ssh/config $HOME/.ssh/config.generic || confirmquestion "WARN: The file $HOME/.ssh/config will be overwritten" && cp -p $HOME/.ssh/config.generic $HOME/.ssh/config
  else
    cp -p $HOME/.ssh/config.generic $HOME/.ssh/config
  fi
  chmod 600 $HOME/.ssh/* || true
}

# Execute without required arguments
# if [ "$#" == "0" ]; then help; fi

while [ $# -gt 0 ] ; do
  case "${1}" in
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


echo "INFO: Download https://cygwin.com/setup-x86_64.exe and install basic packages"
if [[ "$(type -p curl)" == "/usr/bin/curl" ]]
then
  (cd && /usr/bin/curl -L -O https://cygwin.com/setup-x86_64.exe)
else
  (cd && curl -L -O --ssl-no-revoke https://cygwin.com/setup-x86_64.exe)
fi
chmod 755 $HOME/setup-x86_64.exe


echo "INFO: Install basic packages to install or update"
printf '%s\n' "${CYGWIN_BASIC_PACKAGES[@]}"
echo "INFO: Comma separated list of packages to install or update"
LIST_CYGWIN_BASIC_PACKAGES="$(IFS=,; echo "${CYGWIN_BASIC_PACKAGES[*]}")"
echo "${LIST_CYGWIN_BASIC_PACKAGES}"
$HOME/setup-x86_64.exe --quiet-mode --wait --upgrade-also --packages=${LIST_CYGWIN_BASIC_PACKAGES}


echo "INFO: Configure Mintty terminal and PS1 variable"
if [[ "${OSTYPE}" == 'cygwin' ]]
then
  echo "${MINTTY_SETTINGS}" > /etc/minttyrc
  sed -i 's/^PS1=.*$/PS1='"${PS1_SETTINGS}"'/g' /etc/bash.bashrc
  export TERM=xterm-256color
else
  :
fi


echo "INFO: Install yq tool"
/usr/bin/curl -L -o /usr/bin/yq ${YQ_URL_DOWNLOAD} && chmod +x /usr/bin/yq


echo "INFO: Manage settings \$HOME/.bashrc and PATH"
echo "INFO: The file \$HOME/usersettingsbashrc.sh must be idempotent"
grep -qxF '# User settings bashrc' $HOME/.bashrc || echo '# User settings bashrc' >> $HOME/.bashrc
grep -qxF 'source $HOME/usersettingsbashrc.sh' $HOME/.bashrc || echo 'source $HOME/usersettingsbashrc.sh' >> $HOME/.bashrc
echo "${BASHRC_SETTINGS}" > $HOME/usersettingsbashrc.sh

echo "INFO: Load \$HOME/usersettingsbashrc.sh file"
source $HOME/usersettingsbashrc.sh

# Apply SSH client settings
set_sshclient


echo "INFO: Settings for vim edit tool"
echo "${VIM_SETTINGS}" > ~/.vimrc


ON_ERROR=return
for mytool in "${TOOL_CHECKS_LIST[@]}"
do
  case ${mytool} in
    openssl)
      echo "--- CHECK version ${mytool}"
      ${mytool} version
      echo "--- CHECK paths ${mytool}"
      if type -ap ${mytool}
      then
        [[ "$(type -p ${mytool})" != "/usr/bin/${mytool}" ]] && echo "WARN: ${mytool} on the first match PATH correspond to other software"
      else
        echo "WARN: ${mytool} not found on the path"
      fi
    ;;
    openssh)
      othercommand=ssh
      echo "--- CHECK version ${mytool} (${othercommand})"
      ${othercommand} -V
      echo "--- CHECK paths ${mytool} (${othercommand})"
      if type -ap ${othercommand}
      then
        [[ "$(type -p ${othercommand})" != "/usr/bin/${othercommand}" ]] && echo "WARN: ${mytool} (${othercommand}) on the first match PATH correspond to other software"
      else
        echo "WARN: ${mytool} (${othercommand}) not found on the path"
      fi
    ;;
    sshpass)
      echo "--- CHECK version ${mytool}"
      ${mytool} -V
      echo "--- CHECK paths ${mytool}"
      if type -ap ${mytool}
      then
        [[ "$(type -p ${mytool})" != "/usr/bin/${mytool}" ]] && echo "WARN: ${mytool} on the first match PATH correspond to other software"
      else
        echo "WARN: ${mytool} not found on the path"
      fi
    ;;
    keychain)
      echo "--- CHECK version ${mytool}"
      ${mytool} -V
      echo "--- CHECK paths ${mytool}"
      if type -ap ${mytool}
      then
        [[ "$(type -p ${mytool})" != "/usr/bin/${mytool}" ]] && echo "WARN: ${mytool} on the first match PATH correspond to other software"
      else
        echo "WARN: ${mytool} not found on the path"
      fi
    ;;
    *)
      echo "--- CHECK version ${mytool}"
      ${mytool} --version
      echo "--- CHECK paths ${mytool}"
      if type -ap ${mytool}
      then
        [[ "$(type -p ${mytool})" != "/usr/bin/${mytool}" ]] && echo "WARN: ${mytool} on the first match PATH correspond to other software"
      else
        echo "WARN: ${mytool} not found on the path"
      fi
    ;;
  esac
done


echo "INFO: It is recommended to log out of the terminal and open a new session to update the environment variables"
echo "INFO: Or manually load the settings file: source \$HOME/usersettingsbashrc.sh"


[[ "${RESULT}" != "0" ]] && echo "ERROR: Some errors exists. Error code ${RESULT}"
exit ${RESULT}

