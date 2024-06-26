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

[[ "${OSTYPE}" == 'cygwin' ]] && export TERM=xterm-256color


# Global variables
MINTTY_SETTINGS='Term=xterm-256color
# Best fonts are no ambiguous width as Cascadia Mono. For check launch echo "!=" and must be the output equal to !=
Font=Cascadia Mono
FontHeight=10
FontSmoothing=full
# Best confortable themes: luminous rosipov windows10
ThemeFile=luminous
CopyOnSelect=no
ScrollbackLines=10000000
CursorType=block
CursorBlinks=no
BoldAsColour=no
BoldAsFont=yes
AllowBlinking=yes
Columns=110
Rows=30
'
# The result of apply this PS1_SETTINGS is the following:
# PS1='\[\e]0;\w\a\]\[\e[32m\]\u@\h:\[\e[33m\]\w\[\e[0m\]\$ '
PS1_SETTINGS=$(cat << 'ENDPS1'
'\\[\\e]0;\\w\\a\\]\\[\\e[32m\\]\\u@\\h:\\[\\e[33m\\]\\w\\[\\e[0m\\]\\$ '
ENDPS1
)
CYGWIN_BASIC_PACKAGES=(
cygwin cygport
bash bash-completion dbus
util-linux coreutils binutils diffutils diffstat colordiff kdiff3 dos2unix procps-ng
openssl openssh sshpass keychain ca-certificates ca-certificates-letsencrypt
gnutls gnupg gnupg2
curl wget lynx jq rsync nc nc6 whois
avahi avahi-tools
vim vim-minimal vim-common nano
tmux expect konsole git ncdu
gcc-core gcc-g++ autoconf automake make cmake pkg-config pkgconf
gawk pcre2 gettext dialog figlet btop
python3 python3-devel python3-pip python3-setuptools python3-distlib
tar zip unzip gzip xz pigz
)
TOOL_CHECKS_LIST=(curl wget git python python3 pip3 jq yq openssl openssh sshpass keychain)
SSHCONFBASE='StrictHostKeyChecking no
UserKnownHostsFile /dev/null
ControlMaster yes
ControlPersist 600s
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 5
Include config.auto'
SSHCONF_HEADER='# Please do not modify this file because it is managed automatically'
VIM_SETTINGS='" Disable visual mode
set mouse-=a
" No autoindent but allow tabs with size 2
set noautoindent noexpandtab tabstop=2 shiftwidth=2
" Set in terminal title the edited file
set title
'
QEMU_CYGWINHOMEPATH="$(cygpath "${PROGRAMFILES}")/qemu"
YQ_URL_DOWNLOAD='https://github.com/mikefarah/yq/releases/latest/download/yq_windows_amd64.exe'
CONSOLE_FORMAT=$(cat << 'ENDCONSOLEFORMAT'
# Variables for text formatting of the form _C_<name>. _C_DEF reset to default effect and color
# Prefixes F foreground B background (F|B)L light foreground or background
_C_DEF='\e[0m'
_C_BOLD='\e[1m'
_C_DARK='\e[2m'
_C_CURSIVE='\e[3m'
_C_UNDERLINE='\e[4m'
_C_BLINK='\e[5m'
_C_BLINKFAST='\e[6m'
_C_INVERT='\e[7m'
_C_HIDDEN='\e[8m'
_C_STRIKE='\e[9m'
_C_FBLACK='\e[30m'   _C_FLBLACK='\e[90m'   _C_BBLACK='\e[40m'   _C_BLBLACK='\e[100m'
_C_FRED='\e[31m'     _C_FLRED='\e[91m'     _C_BRED='\e[41m'     _C_BLRED='\e[101m'
_C_FGREEN='\e[32m'   _C_FLGREEN='\e[92m'   _C_BGREEN='\e[42m'   _C_BLGREEN='\e[102m'
_C_FYELLOW='\e[33m'  _C_FLYELLOW='\e[93m'  _C_BYELLOW='\e[43m'  _C_BLYELLOW='\e[103m'
_C_FBLUE='\e[34m'    _C_FLBLUE='\e[94m'    _C_BBLUE='\e[44m'    _C_BLBLUE='\e[104m'
_C_FMAGENTA='\e[35m' _C_FLMAGENTA='\e[95m' _C_BMAGENTA='\e[45m' _C_BLMAGENTA='\e[105m'
_C_FCYAN='\e[36m'    _C_FLCYAN='\e[96m'    _C_BCYAN='\e[46m'    _C_BCYAN='\e[106m'
_C_FWHITE='\e[37m'   _C_FLWHITE='\e[97m'   _C_BWHITE='\e[47m'   _C_BLWHITE='\e[107m'
ENDCONSOLEFORMAT
)
BASHRC_SETTINGS=$(cat << 'ENDBASHRC1'
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
ENDBASHRC1
)
BASHRC_SETTINGS+=$'\n'$(cat << ENDBASHRC2
set -o allexport
${CONSOLE_FORMAT}
set +o allexport
ENDBASHRC2
)
BASHRC_SETTINGS+=$'\n'$(cat << 'ENDBASHRC3'
# Text positioning function. Use example: XY 10 10 'Test'
XY()
{
  printf "\e[${2};${1}H$3"
}
export -f XY
# Disable Windows Python installations
PATH=$(echo $PATH | tr ':' '\n' | grep -v "/cygdrive/.*/Python[23]" | paste -sd:)
# Disable Windows Git installations
PATH=$(echo $PATH | tr ':' '\n' | grep -v "/cygdrive/.*/Git/cmd" | paste -sd:)
# Disable Windows Curl installations
PATH=$(echo $PATH | tr ':' '\n' | grep -v "/cygdrive/.*/curl" | paste -sd:)
addpath /usr/sbin
ENDBASHRC3
)
BASHRC_SETTINGS+=$'\n'$(cat << ENDBASHRC4
addpath "${QEMU_CYGWINHOMEPATH}"
addpath "\${VBOX_MSI_INSTALL_PATH}"
ENDBASHRC4
)
BASHRC_SETTINGS+=$'\n'$(cat << 'ENDBASHRC5'
export PATH
# Start and configure SSH and GPG agents
(ps -efa | fgrep -q -e /usr/bin/ssh-agent && ps -efa | fgrep -q -e /usr/bin/gpg-agent) || keychain -q --quick --gpg2 --agents ssh,gpg
source $HOME/.keychain/$(hostname)-sh
source $HOME/.keychain/$(hostname)-sh-gpg
export DISPLAY=:0
ENDBASHRC5
)


function help()
{
  cat << ENDHELP1
===========================================================================
Install and configure a basic environment for Cygwin
===========================================================================
ENDHELP1
  if [ "$*" != "" ]; then echo -e "$*\n" >&2; fi
  cat << ENDHELP2
Usage: ./${PROGNAME}
Common options: ./${PROGNAME} [--help] | <program_options_see_usage> [--debug] [--no-interactive] [--] [--options_for_wrapper_content...]
  --help Shows this help
  --help all Print also detailed information and examples if provided
  --debug Sets the DEBUG environment variable to debug the program itself (not the wrapper) if used
  --no-interactive Disable interactive questions
  -- End of options and arguments of the program. Then all others are transferred to the wrapper content if used "\$@"
  --options_for_wrapper_content... If used a wrapper one example is --debug
ENDHELP2
  if [[ "${HELPALL}" == "true" ]]
  then
    cat << ENDHELP3
Tasks:
  - Download and execute the Cygwin setup tool
  - Install or update the packages defined with CYGWIN_BASIC_PACKAGES variable
  - Apply settings for Mintty terminal for better use of terminals defined by MINTTY_SETTINGS variable
  - Apply a workaround to update keychain package from 2.7.1 to 2.8.5 for SSH and GPG2 fix issues and support
  - Apply settings for PS1 for better visualization of command line terminal defined by PS1_SETTINGS variable
  - Install or update the yq tool
  - Apply settings for bashrc to get advantage for common tasks using the file \$HOME/custombashrc.sh:
    - Function addpath to PATH variable and add the paths /usr/sbin and "${QEMU_CYGWINHOMEPATH}"
    - Function confirmquestion to use interactive questions
    - Disable PATHs for some Windows software that can interfere with Cygwin software at present Python, Git and Curl
    - Define termcap functions and variables using xterm-256color to use in scripts:
      - Text positioning function. Use example: XY 10 10 'Test'
      - Variables for text formatting of the form _C_<name>. Variable _C_DEF reset to default effect and color
        Prefixes F foreground B background (F|B)L light foreground or background
ENDHELP3
  for item in $(env | grep "^_C_" | cut -d'=' -f1 | sort)
  do
    printf "${item} = ${!item}Colors and effects${_C_DEF}\n"
  done | pr -T -o 8
    cat << ENDHELP4
    - Start keychain tool to manage SSH and GPG2 keys in a convenient secure manner
  - Apply basic SSH client settings defined by SSHCONFBASE and SSHCONF_HEADER variables
  - Apply basic vim tool settings for better use and visualization defined by VIM_SETTINGS
  - Execute tests for common and basic commands getting its versions and PATH lookups defined by TOOL_CHECKS_LIST variable
ENDHELP4
  fi
  exit 10
}

function set_sshclient()
{
  echo "INFO: Apply SSH client settings"
  mkdir -p $HOME/.ssh
  chmod 700 $HOME/.ssh
  echo "${SSHCONFBASE}" > $HOME/.ssh/config.generic
  truncate -s 0 $HOME/.ssh/known_hosts
  touch $HOME/.ssh/authorized_keys
  touch $HOME/.ssh/config.auto
  sed -r -i '/\s*#/d' $HOME/.ssh/config.auto
  sed -i 's/\t/  /g' $HOME/.ssh/config.auto
  if [[ -s "$HOME/.ssh/config.auto" ]]
  then
    sed -i "1 i${SSHCONF_HEADER}" $HOME/.ssh/config.auto
  else
    echo "${SSHCONF_HEADER}" > $HOME/.ssh/config.auto
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
printf '%s\n' "${CYGWIN_BASIC_PACKAGES[@]}" | pr -tT -a -S$'\t\t' --columns 3
echo "INFO: Comma separated list of packages to install or update"
LIST_CYGWIN_BASIC_PACKAGES="$(IFS=,; echo "${CYGWIN_BASIC_PACKAGES[*]}")"
echo "${LIST_CYGWIN_BASIC_PACKAGES}"
$HOME/setup-x86_64.exe --quiet-mode --wait --upgrade-also --packages=${LIST_CYGWIN_BASIC_PACKAGES}


echo "INFO: Configure Mintty terminal and PS1 variable and a workaround to use keychain 2.8.5 version"
if [[ "${OSTYPE}" == 'cygwin' ]]
then
  echo "${MINTTY_SETTINGS}" > /etc/minttyrc
  sed -i 's/^PS1=.*$/PS1='"${PS1_SETTINGS}"'/g' /etc/bash.bashrc
  grep -xq 'version=2.8.5' /usr/bin/keychain || curl -o /usr/bin/keychain https://raw.githubusercontent.com/funtoo/keychain/2.8.5/keychain
else
  :
fi


echo "INFO: Install yq tool"
/usr/bin/curl -L -o /usr/bin/yq ${YQ_URL_DOWNLOAD} && chmod +x /usr/bin/yq


echo "INFO: Manage settings \$HOME/.bashrc and PATH"
echo "INFO: The file \$HOME/custombashrc.sh must be idempotent"
grep -qxF '# User settings bashrc' $HOME/.bashrc || echo '# User settings bashrc' >> $HOME/.bashrc
grep -qxF 'source $HOME/custombashrc.sh' $HOME/.bashrc || echo 'source $HOME/custombashrc.sh' >> $HOME/.bashrc
echo "${BASHRC_SETTINGS}" > $HOME/custombashrc.sh

echo "INFO: Load \$HOME/custombashrc.sh file"
source $HOME/custombashrc.sh

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
echo "INFO: Or manually load the settings file: source \$HOME/custombashrc.sh"


[[ "${RESULT}" != "0" ]] && echo "ERROR: Some errors exists. Error code ${RESULT}"
exit ${RESULT}
