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
TOOL_CHECKS_LIST=(openssl openssh sshpass keychain)
SSHCONFBASE='StrictHostKeyChecking no
UserKnownHostsFile /dev/null
ControlMaster yes
ControlPersist 600s
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 5
Include config.auto'
SSHCONF_HEADER='# Please do not modify this file because it is managed automatically'


# Associative array for manage the client parameters of this tool
declare -A params=()

# Array for manage SSH client settings host entries stored inside $HOME/.ssh/config.auto
sshconf_list=()

# Associative array that define all possible items of a SSH configuration block
declare -A sshconf_templateitems=(
[AddKeysToAgent]=""
[AddressFamily]=""
[BatchMode]=""
[BindAddress]=""
[BindInterface]=""
[CanonicalDomains]=""
[CanonicalizeFallbackLocal]=""
[CanonicalizeHostname]=""
[CanonicalizeMaxDots]=""
[CanonicalizePermittedCNAMEs]=""
[CASignatureAlgorithms]=""
[CertificateFile]=""
[CheckHostIP]=""
[Ciphers]=""
[ClearAllForwardings]=""
[Compression]=""
[ConnectionAttempts]=""
[ConnectTimeout]=""
[ControlMaster]=""
[ControlPath]=""
[ControlPersist]=""
[DynamicForward]=""
[EnableSSHKeysign]=""
[EscapeChar]=""
[ExitOnForwardFailure]=""
[FingerprintHash]=""
[ForkAfterAuthentication]=""
[ForwardAgent]=""
[ForwardX11]=""
[ForwardX11Timeout]=""
[ForwardX11Trusted]=""
[GatewayPorts]=""
[GlobalKnownHostsFile]=""
[GSSAPIAuthentication]=""
[GSSAPIClientIdentity]=""
[GSSAPIDelegateCredentials]=""
[GSSAPIKeyExchange]=""
[GSSAPIRenewalForcesRekey]=""
[GSSAPIServerIdentity]=""
[GSSAPITrustDns]=""
[GSSAPIKexAlgorithms]=""
[HashKnownHosts]=""
[HostbasedAcceptedAlgorithms]=""
[HostbasedAuthentication]=""
[HostKeyAlgorithms]=""
[HostKeyAlias]=""
[Hostname]=""
[IdentitiesOnly]=""
[IdentityAgent]=""
[IdentityFile]=""
[IgnoreUnknown]=""
[Include]=""
[IPQoS]=""
[KbdInteractiveAuthentication]=""
[KbdInteractiveDevices]=""
[KexAlgorithms]=""
[KnownHostsCommand]=""
[LocalCommand]=""
[LocalForward]=""
[LogLevel]=""
[LogVerbose]=""
[MACs]=""
[NoHostAuthenticationForLocalhost]=""
[NumberOfPasswordPrompts]=""
[PasswordAuthentication]=""
[PermitLocalCommand]=""
[PermitRemoteOpen]=""
[PKCS11Provider]=""
[Port]=""
[PreferredAuthentications]=""
[ProxyCommand]=""
[ProxyJump]=""
[ProxyUseFdpass]=""
[PubkeyAcceptedAlgorithms]=""
[PubkeyAuthentication]=""
[RekeyLimit]=""
[RemoteCommand]=""
[RemoteForward]=""
[RequestTTY]=""
[RevokedHostKeys]=""
[SecurityKeyProvider]=""
[SendEnv]=""
[ServerAliveCountMax]=""
[ServerAliveInterval]=""
[SessionType]=""
[SetEnv]=""
[StdinNull]=""
[StreamLocalBindMask]=""
[StreamLocalBindUnlink]=""
[StrictHostKeyChecking]=""
[SyslogFacility]=""
[TCPKeepAlive]=""
[Tunnel]=""
[TunnelDevice]=""
[UpdateHostKeys]=""
[User]=""
[UserKnownHostsFile]=""
[VerifyHostKeyDNS]=""
[VisualHostKey]=""
[XAuthLocation]=""
)


function help()
{
  cat << ENDHELP1
===========================================================================
Manage SSH RSA private and public keys
- Set basic SSH client settings
- Delete all SSH client settings
- Show SSH client information
- Delete all indentities from the SSH agent
- Delete all from SSH config hosts $HOME/.ssh/config.auto
- Create a new SSH RSA key
- Import one SSH RSA key
- Add to or delete from SSH Agent Keychain
- Add to or delete from SSH config settings using $HOME/.ssh/config.auto
- Delete one SSH RSA key
- Show detailed information of one SSH RSA key
===========================================================================
ENDHELP1
  if [ "$*" != "" ]; then echo -e "$*\n" >&2; fi
  cat << ENDHELP2
Usage: ./${PROGNAME} --set-sshclient | --deleteall-sshclient --show-sshclient
Usage: ./${PROGNAME} --deleteall-sshagent | --deleteall-sshconf
Usage: ./${PROGNAME} --create-sshkey filename-privatekey [--import] [--add-sshagent | --delete-sshagent] [--add-sshconf 'host list' | --delete-sshconf]
Usage: ./${PROGNAME} --config-sshkey filename-privatekey [--add-sshagent | --delete-sshagent] [--add-sshconf 'host list' | --delete-sshconf]
Usage: ./${PROGNAME} --delete-sshkey filename-privatekey | --show-sshkey filename-privatekey
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
Detailed information:
  This tool create the SSH keys as PEM RSA format or PKCS8 and length of 4096 bits
  This tool can be used to create SSH keys for machines
    or create SSH keys to use for Github users accessing to GitHub web user configuration:
    Settings -> SSH and GPG keys -> New SSH key
    Then in title one descriptive and identificative string, Key type as Authetication Key and in Key paste your SSH RSA public key
  TODO
Examples:
  TODO
ENDHELP3
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

function show_sshkey()
{
  echo -e "${_C_FCYAN}INI: SSH RSA private key $HOME/.ssh/${1}${_C_DEF}"
  cat $HOME/.ssh/${1}
  echo -e "${_C_FCYAN}END: SSH RSA private key $HOME/.ssh/${1}${_C_DEF}"
  echo -e "${_C_FCYAN}INFO: SSH RSA public key $HOME/.ssh/${1}.pub${_C_DEF}"
  cat $HOME/.ssh/${1}.pub
  echo -e "${_C_FCYAN}INFO: Print PEM RSA public key${_C_DEF}"
  openssl rsa -in $HOME/.ssh/${1} -pubout
  echo -e "${_C_FCYAN}INFO: Print SHA256 fingerprint${_C_DEF}"
  ssh-keygen -l -E sha256 -f $HOME/.ssh/${1}.pub
  echo -e "${_C_FCYAN}INFO: Print MD5 fingerprint${_C_DEF}"
  ssh-keygen -l -E md5 -f $HOME/.ssh/${1}.pub
  chmod 600 $HOME/.ssh/* || true
  if ssh-add -T $HOME/.ssh/${1} &>/dev/null
  then
    echo -e "${_C_FCYAN}INFO: The key is added to SSH Agent${_C_DEF}"
  else
    echo -e "${_C_FCYAN}INFO: The key is not added to SSH Agent${_C_DEF}"
  fi
  echo -e "${_C_BRED}TODO: Manage sshconf${_C_DEF}"
}












function add_sshconf_list()
{
  if [[ "${sshconf_block}" != "" ]]
  then
    if [[ $(echo "${sshconf_block}" | wc -l) -gt 1 ]]
    then
      sshhoststring="$(echo "${sshconf_block}" | grep -Po '^Host\s+\K([^\s].*)' || true)"
      if [[ "${sshhoststring}" != "" ]]
      then
        sshidfile="$(echo "${sshconf_block}" | grep -Po '^\s+IdentityFile\s+\K(.*)' || true)"
        if [[ "${sshidfile}" != "" ]]
        then
          if [[ -f "${sshidfile/\~/$HOME}" ]]
          then
            sshconf_list+=("${sshconf_block}")
          fi
        fi
      fi
    fi
    sshconf_block=""
  fi
}

function print_sshconf_list()
{
  if [[ "${DEBUG}" == "true" ]]
  then
    echo "*** INI Show sshconf_list array"
    for indexarr in "${!sshconf_list[@]}"
    do
      printf "Number %s\n%s\n" "${indexarr}" "${sshconf_list[${indexarr}]}"
    done
    echo "*** END Show sshconf_list array"
  fi
}

function parse_sshconf_list()
{
  sshconf_block=""
  while IFS= read -r inputline
  do
    # Discard empty, space or comment lines
    echo "${inputline}" | grep -qPo '^\s*(#|$)' && continue
    if [[ "$(echo "${inputline}" | sed -r -n '/^Host\s+[^\s].*$/p')" != "" ]]
    then
      # Begin of processing a new SSH Host entry
      [[ "${DEBUG}" == "true" ]] && echo "New Host entry <${inputline}>"
      # Add to sshconf_list if this entry is good
      add_sshconf_list
      if [[ "${sshconf_block}" != "" ]]
      then
        sshconf_block+=$'\n'"${inputline}"
      else
        sshconf_block+="${inputline}"
      fi
    elif [[ "$(echo "${inputline}" | sed -r -n '/^\s+[^\s].*$/p')" != "" ]]
    then
      # Process of one SSH Host item
      [[ "${DEBUG}" == "true" ]] && echo "Host item <${inputline}>"
      [[ "${sshconf_block}" != "" ]] && sshconf_block+=$'\n'"${inputline}" || continue
    else
      # Process others not contemplated
      [[ "${DEBUG}" == "true" ]] && echo "Not contemplated <${inputline}>"
      # If the entry is still in process then add to sshconf_list if this entry is good
      [[ "${sshconf_block}" != "" ]] && add_sshconf_list
      continue
    fi
  done < $HOME/.ssh/config.auto
  # For the last entry still in process then add to sshconf_list if this entry is good
  add_sshconf_list
  # Print sshconf_list array for debug only
  print_sshconf_list
}

# Execute with required arguments
if [ "$#" == "0" ]; then help; fi

while [ $# -gt 0 ] ; do
  case "${1}" in
    --set-sshclient)
      [[ -v params[--set-sshclient] ]] && help "ERROR: Repeated parameters"
      params[--set-sshclient]=""
      ;;
    --deleteall-sshclient)
      [[ -v params[--deleteall-sshclient] ]] && help "ERROR: Repeated parameters"
      params[--deleteall-sshclient]=""
      ;;
    --show-sshclient)
      [[ -v params[--show-sshclient] ]] && help "ERROR: Repeated parameters"
      params[--show-sshclient]=""
      ;;
    --deleteall-sshagent)
      [[ -v params[--deleteall-sshagent] ]] && help "ERROR: Repeated parameters"
      params[--deleteall-sshagent]=""
      ;;
    --deleteall-sshconf)
      [[ -v params[--deleteall-sshconf] ]] && help "ERROR: Repeated parameters"
      params[--deleteall-sshconf]=""
      ;;
    --delete-sshkey)
      [[ -v params[--delete-sshkey] ]] && help "ERROR: Repeated parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --delete-sshkey"
      params[--delete-sshkey]="${2}"
      shift
      ;;
    --show-sshkey)
      [[ -v params[--show-sshkey] ]] && help "ERROR: Repeated parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --show-sshkey"
      params[--show-sshkey]="${2}"
      shift
      ;;
    --create-sshkey)
      [[ -v params[--create-sshkey] ]] && help "ERROR: Repeated parameters"
      [[ -v params[--config-sshkey] ]] && help "ERROR: Mixed parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --create-sshkey"
      params[--create-sshkey]="${2}"
      shift
      ;;
    --import)
      [[ -v params[--import] ]] && help "ERROR: Repeated parameters"
      [[ ! -v params[--create-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey"
      params[--import]=""
      ;;
    --config-sshkey)
      [[ -v params[--config-sshkey] ]] && help "ERROR: Repeated parameters"
      [[ -v params[--create-sshkey] ]] && help "ERROR: Mixed parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --config-sshkey"
      params[--config-sshkey]="${2}"
      shift
      ;;
    --add-sshagent)
      [[ -v params[--add-sshagent] ]] && help "ERROR: Repeated parameters"
      [[ ! -v params[--create-sshkey] && ! -v params[--config-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey or --config-sshkey"
      [[ -v params[--delete-sshagent] ]] && help "ERROR: Mixed parameters"
      params[--add-sshagent]=""
      ;;
    --delete-sshagent)
      [[ -v params[--delete-sshagent] ]] && help "ERROR: Repeated parameters"
      [[ ! -v params[--create-sshkey] && ! -v params[--config-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey or --config-sshkey"
      [[ -v params[--add-sshagent] ]] && help "ERROR: Mixed parameters"
      params[--delete-sshagent]=""
      ;;
    --add-sshconf)
      [[ -v params[--add-sshconf] ]] && help "ERROR: Repeated parameters"
      [[ ! -v params[--create-sshkey] && ! -v params[--config-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey or --config-sshkey"
      [[ -v params[--delete-sshconf] ]] && help "ERROR: Mixed parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --add-sshconf"
      params[--add-sshconf]="${2}"
      shift
      ;;
    --delete-sshconf)
      [[ -v params[--delete-sshconf] ]] && help "ERROR: Repeated parameters"
      [[ ! -v params[--create-sshkey] && ! -v params[--config-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey or --config-sshkey"
      [[ -v params[--add-sshconf] ]] && help "ERROR: Mixed parameters"
      params[--delete-sshconf]=""
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


if [[ -v params[--set-sshclient] ]]
then
  [[ ${#params[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  # Apply SSH client settings
  set_sshclient
elif [[ -v params[--deleteall-sshclient] ]]
then
  [[ ${#params[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  [[ -d $HOME/.ssh ]] && confirmquestion "WARN: The directory $HOME/.ssh will be deleted" && (rm -rf $HOME/.ssh; ssh-add -D) || :
elif [[ -v params[--show-sshclient] ]]
then
  [[ ${#params[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  echo "INFO: Show SSH client settings"
  ON_ERROR=return
  for mytool in "${TOOL_CHECKS_LIST[@]}"
  do
    case ${mytool} in
      openssl)
        echo -e "${_C_FCYAN}--- CHECK version ${mytool}${_C_DEF}"
        ${mytool} version
        echo -e "${_C_FCYAN}--- CHECK paths ${mytool}${_C_DEF}"
        if type -ap ${mytool}
        then
          [[ "$(type -p ${mytool})" != "/usr/bin/${mytool}" ]] && echo -e "${_C_FRED}WARN: ${mytool} on the first match PATH correspond to other software${_C_DEF}"
        else
          echo -e "${_C_FRED}WARN: ${mytool} not found on the path${_C_DEF}"
        fi
      ;;
      openssh)
        othercommand=ssh
        echo -e "${_C_FCYAN}--- CHECK version ${mytool} (${othercommand})${_C_DEF}"
        ${othercommand} -V
        echo -e "${_C_FCYAN}--- CHECK paths ${mytool} (${othercommand})${_C_DEF}"
        if type -ap ${othercommand}
        then
          [[ "$(type -p ${othercommand})" != "/usr/bin/${othercommand}" ]] && echo -e "${_C_FRED}WARN: ${mytool} (${othercommand}) on the first match PATH correspond to other software${_C_DEF}"
        else
          echo -e "${_C_FRED}WARN: ${mytool} (${othercommand}) not found on the path${_C_DEF}"
        fi
      ;;
      sshpass)
        echo -e "${_C_FCYAN}--- CHECK version ${mytool}${_C_DEF}"
        ${mytool} -V
        echo -e "${_C_FCYAN}--- CHECK paths ${mytool}${_C_DEF}"
        if type -ap ${mytool}
        then
          [[ "$(type -p ${mytool})" != "/usr/bin/${mytool}" ]] && echo -e "${_C_FRED}WARN: ${mytool} on the first match PATH correspond to other software${_C_DEF}"
        else
          echo -e "${_C_FRED}WARN: ${mytool} not found on the path${_C_DEF}"
        fi
      ;;
      keychain)
        echo -e "${_C_FCYAN}--- CHECK version ${mytool}${_C_FCYAN}"
        ${mytool} -V
        echo -e "${_C_FCYAN}--- CHECK paths ${mytool}${_C_FCYAN}"
        if type -ap ${mytool}
        then
          [[ "$(type -p ${mytool})" != "/usr/bin/${mytool}" ]] && echo -e "${_C_FRED}WARN: ${mytool} on the first match PATH correspond to other software${_C_DEF}"
        else
          echo -e "${_C_FRED}WARN: ${mytool} not found on the path${_C_DEF}"
        fi
      ;;
    esac
  done
  echo -e "${_C_FCYAN}INI: SSH Agent List${_C_DEF}"
  ssh-add -L || true
  echo -e "${_C_FCYAN}END: SSH Agent List${_C_DEF}"
  if [[ -d $HOME/.ssh ]]
  then
    echo -e "${_C_FCYAN}ls -dl \$HOME/.ssh${_C_DEF}"
    ls -dl $HOME/.ssh
    echo -e "${_C_FCYAN}ls -l \$HOME/.ssh${_C_DEF}"
    ls -l $HOME/.ssh
    [[ -f "$HOME/.ssh/config" ]] && (echo -e "${_C_FCYAN}INI \$HOME/.ssh/config${_C_DEF}"; cat $HOME/.ssh/config; echo -e "${_C_FCYAN}END \$HOME/.ssh/config${_C_DEF}") || echo -e "${_C_FRED}WARN: The file $HOME/.ssh/config does not exist or is not a file${_C_DEF}"
    [[ -f "$HOME/.ssh/config.generic" ]] && (echo -e "${_C_FCYAN}INI \$HOME/.ssh/config.generic${_C_DEF}"; cat $HOME/.ssh/config.generic; echo -e "${_C_FCYAN}END \$HOME/.ssh/config.generic${_C_DEF}") || echo -e "${_C_FRED}WARN: The file $HOME/.ssh/config.generic does not exist or is not a file${_C_DEF}"
    [[ -f "$HOME/.ssh/config.auto" ]] && (echo -e "${_C_FCYAN}INI \$HOME/.ssh/config.auto${_C_DEF}"; cat $HOME/.ssh/config.auto; echo -e "${_C_FCYAN}END \$HOME/.ssh/config.auto${_C_DEF}") || echo -e "${_C_FRED}WARN: The file $HOME/.ssh/config.auto does not exist or is not a file${_C_DEF}"
  else
    echo -e "${_C_RED}WARN: The directory $HOME/.ssh does not exist or is not a directory${_C_DEF}"
  fi
elif [[ -v params[--deleteall-sshagent] ]]
then
  [[ ${#params[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  confirmquestion "WARN: Delete all identities from the agent" && ssh-add -D || :
elif [[ -v params[--deleteall-sshconf] ]]
then
  [[ ${#params[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  confirmquestion "WARN: Delete $HOME/.ssh/config.auto file" && rm -f $HOME/.ssh/config.auto || :
  # Apply SSH client settings
  set_sshclient
elif [[ -v params[--delete-sshkey] ]]
then
  [[ ${#params[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  # Basic verification of parameter values
  echo "${params[--delete-sshkey]}" | grep -Pxq '\w+|\w+((-|_)?\w+)+' || help "ERROR: The argument filename-privatekey must be a valid value"
  # Apply SSH client settings
  set_sshclient
  ACTION=false
  # The file utility has a bug https://bugs.astron.com/view.php?id=443 and can't detect needed file types
  if [[ -f "$HOME/.ssh/${params[--delete-sshkey]}" ]]
  then
    confirmquestion "WARN: All the data of the SSH private key $HOME/.ssh/${params[--delete-sshkey]} will be deleted" && ACTION=true || ACTION=false
  else
    # If the SSH private key is not found then try to delete all rests if exist
    ACTION=true
  fi
  if [[ "${ACTION}" == "true" ]]
  then
    echo "INFO: Delete $HOME/.ssh/${params[--delete-sshkey]} from SSH Agent if exist"
    ssh-add -d $HOME/.ssh/${params[--delete-sshkey]} 2>/dev/null || true
    ssh-add -d $HOME/.ssh/${params[--delete-sshkey]}.pub 2>/dev/null || true
    while IFS= read -r inputline
    do
      [[ "${DEBUG}" == "true" ]] && echo "WARN: Delete possibly orphaned key from SSH Agent"
      [[ "${DEBUG}" == "true" ]] && echo "${inputline}"
      echo "${inputline}" | ssh-add -d -
    done < <(ssh-add -L | grep "/${params[--delete-sshkey]}$" || true)
    echo -e "${_C_BRED}TODO: Manage sshconf${_C_DEF}"
    echo "INFO: Delete SSH PEM RSA private key $HOME/.ssh/${params[--delete-sshkey]} and public key $HOME/.ssh/${params[--delete-sshkey]}.pub"
    rm -f $HOME/.ssh/${params[--delete-sshkey]}
    rm -f $HOME/.ssh/${params[--delete-sshkey]}.pub
  else
    :
  fi
elif [[ -v params[--show-sshkey] ]]
then
  [[ ${#params[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  # Basic verification of parameter values
  echo "${params[--show-sshkey]}" | grep -Pxq '\w+|\w+((-|_)?\w+)+' || help "ERROR: The argument filename-privatekey must be a valid value"
  # Apply SSH client settings
  set_sshclient
  ON_ERROR=return
  show_sshkey "${params[--show-sshkey]}"





elif [[ -v params[--create-sshkey] ]]
then
  # Basic verification of parameter values
  echo "${params[--create-sshkey]}" | grep -Pxq '\w+|\w+((-|_)?\w+)+' || help "ERROR: The argument filename-privatekey must be a valid value"
  if [[ -v params[--add-sshconf] ]]
  then
    echo "${params[--add-sshconf]}" | grep -Pxq '[^\s,]+(,[^\s,]+)*' || help "ERROR: The SSH config hosts are not valid"
  else
    :
  fi
  # Apply SSH client settings
  set_sshclient
  ACTION=false
  if [[ -f "$HOME/.ssh/${params[--create-sshkey]}" ]]
  then
    confirmquestion "WARN: The file $HOME/.ssh/${params[--create-sshkey]} will be overwritten" && ACTION=true || ACTION=false
  else
    ACTION=true
  fi
  if [[ "${ACTION}" == "true" ]]
  then
    if [[ -v params[--import] ]]
    then
      echo "INFO: Copy and paste the SSH PEM RSA private key and press enter to end to store in $HOME/.ssh/${params[--create-sshkey]}"
      truncate -s 0 $HOME/.ssh/${params[--create-sshkey]}
      chmod 600 $HOME/.ssh/${params[--create-sshkey]}
      while IFS= read -r inputline
      do
        [ -z "${inputline}" ] && break
        printf "%s\n" "${inputline}" >> $HOME/.ssh/${params[--create-sshkey]}
      done < /dev/stdin
      echo "INFO: Create the SSH RSA public key $HOME/.ssh/${params[--create-sshkey]}.pub from the provided private key $HOME/.ssh/${params[--create-sshkey]}"
      ssh-keygen -y -f $HOME/.ssh/${params[--create-sshkey]} > $HOME/.ssh/${params[--create-sshkey]}.pub
      chmod 600 $HOME/.ssh/${params[--create-sshkey]}.pub
    else
      echo "INFO: Create SSH PEM RSA private key $HOME/.ssh/${params[--create-sshkey]} and public key $HOME/.ssh/${params[--create-sshkey]}.pub"
      ssh-keygen -b 4096 -t rsa -m PKCS8 -N "" -C "my@${params[--create-sshkey]}" -f $HOME/.ssh/${params[--create-sshkey]} <<< $'y'
    fi
    chmod 600 $HOME/.ssh/${params[--create-sshkey]} $HOME/.ssh/${params[--create-sshkey]}.pub
  fi
  if [[ -v params[--add-sshagent] ]]
  then
    echo "INFO: Add $HOME/.ssh/${params[--create-sshkey]} to SSH Agent"
    ssh-add $HOME/.ssh/${params[--create-sshkey]}
  fi
  if [[ -v params[--delete-sshagent] ]]
  then
    echo "INFO: Delete $HOME/.ssh/${params[--create-sshkey]} from SSH Agent"
    ssh-add -d $HOME/.ssh/${params[--create-sshkey]} || true
  fi
  if [[ -v params[--delete-sshconf] ]]
  then
    echo -e "${_C_BRED}TODO: Manage sshconf${_C_DEF}"
  fi
  if [[ -v params[--add-sshconf] ]]
  then
    echo -e "${_C_BRED}TODO: Manage sshconf${_C_DEF}"
#    echo "INFO: Add $HOME/.ssh/${params[--create-sshkey]} to SSH client settings Host in $HOME/.ssh/config.auto"
#    printf "Host %s\n  IdentityFile %s\n  IdentitiesOnly yes\n  ForwardAgent yes\n" "${ADDTO_sshconf}" "~/.ssh/${params[--create-sshkey]}" >> $HOME/.ssh/config.auto
  fi






elif [[ -v params[--config-sshkey] ]]
then
  # Basic verification of parameter values
  echo "${params[--config-sshkey]}" | grep -Pxq '\w+|\w+((-|_)?\w+)+' || help "ERROR: The argument filename-privatekey must be a valid value"
  if [[ -v params[--add-sshconf] ]]
  then
    echo "${params[--add-sshconf]}" | grep -Pxq '[a-zA-Z\d]+(-[a-zA-Z\d]+)*(\.[a-zA-Z\d]+(-[a-zA-Z\d]+)*)*(\s+[a-zA-Z\d]+(-[a-zA-Z\d]+)*(\.[a-zA-Z\d]+(-[a-zA-Z\d]+)*)*)*' || help "ERROR: The SSH config hosts are not valid"
  else
    :
  fi
  # Apply SSH client settings
  set_sshclient
  if [[ -v params[--add-sshagent] ]]
  then
    echo "INFO: Add $HOME/.ssh/${params[--config-sshkey]} to SSH Agent"
    ssh-add $HOME/.ssh/${params[--config-sshkey]}
  fi
  if [[ -v params[--delete-sshagent] ]]
  then
    echo "INFO: Delete $HOME/.ssh/${params[--config-sshkey]} from SSH Agent"
    ssh-add -d $HOME/.ssh/${params[--config-sshkey]} || true
  fi
  if [[ -v params[--delete-sshconf] ]]
  then
    echo -e "${_C_BRED}TODO: Manage sshconf${_C_DEF}"
  fi
  if [[ -v params[--add-sshconf] ]]
  then
    echo -e "${_C_BRED}TODO: Manage sshconf${_C_DEF}"
    parse_sshconf_list

    for indexarr in "${!sshconf_list[@]}"
    do
      printf "Number %s\n%s\n" "${indexarr}" "${sshconf_list[${indexarr}]}"
    done

    echo "INFO: Add $HOME/.ssh/${params[--config-sshkey]} to SSH client settings Host $HOME/.ssh/config.auto"
    printf "Host %s\n  IdentityFile %s\n  IdentitiesOnly yes\n  ForwardAgent yes\n" "${params[--add-sshconf]}" "~/.ssh/${params[--config-sshkey]}" >> $HOME/.ssh/config.auto
#    printf "Host %s\n  IdentityFile %s\n  IdentitiesOnly yes\n  ForwardAgent yes\n" "${ADDTO_sshconf}" "~/.ssh/${params[--config-sshkey]}" >> $HOME/.ssh/config.auto
  fi
else
  help "ERROR: Internal error"
fi


[[ "${RESULT}" != "0" ]] && echo "ERROR: Some errors exists. Error code ${RESULT}"
exit ${RESULT}
