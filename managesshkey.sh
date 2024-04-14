#!/usr/bin/env bash

set -o pipefail
set -o errtrace

RESULT=0
trap catch_errors ERR
function catch_errors() {
  RESULT=$?
  echo "ERROR: Command ${BASH_COMMAND} line ${LINENO} failed with code ${RESULT}"
  # Only for exit inmediately
  return ${RESULT}
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
  echo "Manage SSH RSA private and public keys"
  echo "- Set basic SSH client settings"
  echo "- Delete all SSH client settings"
  echo "- Show SSH client information"
  echo "- Delete all indentities from the agent"
  echo "- Delete all from SSH config hosts $HOME/.ssh/config.auto"
  echo "- Create a new SSH RSA key"
  echo "- Import one SSH RSA key"
  echo "- Add to or delete from SSH Agent Keychain"
  echo "- Add to or delete from SSH config settings using $HOME/.ssh/config.auto"
  echo "- Delete one SSH RSA key"
  echo "- Show detailed information of one SSH RSA key"
  echo "==========================================================================="
  if [ "$*" != "" ]; then echo -e "$*\n" >&2; fi
  echo "Usage: ./${PROGNAME} --set-sshclient | --deleteall-sshclient --show-sshclient"
  echo "Usage: ./${PROGNAME} --deleteall-sshagent | --deleteall-sshconfig"
  echo "Usage: ./${PROGNAME} --create-sshkey filename-privatekey [--import] [--add-sshagent | --delete-sshagent] [--add-sshconfig 'host list' | --delete-sshconfig]"
  echo "Usage: ./${PROGNAME} --config-sshkey filename-privatekey [--add-sshagent | --delete-sshagent] [--add-sshconfig 'host list' | --delete-sshconfig]"
  echo "Usage: ./${PROGNAME} --delete-sshkey filename-privatekey | --show-sshkey filename-privatekey"
  echo "Common options: ./${PROGNAME} [--help] | <program_options_see_usage> [--debug] [--no-interactive] [--] [--options_for_wrapper_content...]"
  echo "  --debug Sets the DEBUG environment variable to debug the program itself (not the wrapper) if used"
  echo "  --no-interactive Disable interactive questions"
  echo "  -- End of options and arguments of the program. Then all others are transferred to the wrapper content if used (\"\$@\")"
  echo "  --options_for_wrapper_content... If used a wrapper one example is --debug"
  echo "More information:"
  echo "This tool create the SSH keys as PEM RSA format or PKCS8 and length of 4096 bits"
  echo "This tool can be used to create SSH keys for machines"
  echo "  or create SSH keys to use for Github users accessing to GitHub web user configuration:"
  echo "  Settings -> SSH and GPG keys -> New SSH key"
  echo "  Then in title one descriptive and identificative string, Key type as Authetication Key and in Key paste your SSH RSA public key"
  exit 10
}

sshconfigauto_headercomment='# Please do not modify this file because it is managed automatically'

function set_sshclient ()
{
  echo "INFO: Apply SSH client settings"
  mkdir -p $HOME/.ssh
  chmod 700 $HOME/.ssh
  echo 'StrictHostKeyChecking no
UserKnownHostsFile /dev/null
ControlMaster yes
ControlPersist 600s
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 5
Include config.auto' > $HOME/.ssh/config.generic
  truncate -s 0 $HOME/.ssh/known_hosts
  touch $HOME/.ssh/authorized_keys
  touch $HOME/.ssh/config.auto
  sed -r -i '/\s*#/d' $HOME/.ssh/config.auto
  sed -i 's/\t/  /g' $HOME/.ssh/config.auto
  if [[ -s "$HOME/.ssh/config.auto" ]]
  then
    sed -i "1 i${sshconfigauto_headercomment}" $HOME/.ssh/config.auto
  else
    echo "${sshconfigauto_headercomment}" > $HOME/.ssh/config.auto
  fi
  if [[ -s $HOME/.ssh/config ]]
  then
    diff -u --color=auto $HOME/.ssh/config $HOME/.ssh/config.generic || confirmquestion "WARN: The file $HOME/.ssh/config will be overwritten" && cp -p $HOME/.ssh/config.generic $HOME/.ssh/config
  else
    cp -p $HOME/.ssh/config.generic $HOME/.ssh/config
  fi
  chmod 600 $HOME/.ssh/* || true
}

function show_sshkey ()
{
  echo "INI: SSH RSA private key $HOME/.ssh/${1}"
  cat $HOME/.ssh/${1}
  echo "END: SSH RSA private key $HOME/.ssh/${1}"
  echo "INFO: SSH RSA public key $HOME/.ssh/${1}.pub"
  cat $HOME/.ssh/${1}.pub
  echo "INFO: Print PEM RSA public key"
  openssl rsa -in $HOME/.ssh/${1} -pubout
  echo "INFO: Print SHA256 fingerprint"
  ssh-keygen -l -E sha256 -f $HOME/.ssh/${1}.pub
  echo "INFO: Print MD5 fingerprint"
  ssh-keygen -l -E md5 -f $HOME/.ssh/${1}.pub
  chmod 600 $HOME/.ssh/* || true
  if ssh-add -T $HOME/.ssh/${1} &>/dev/null
  then
    echo "INFO: The key is added to SSH Agent"
  else
    echo "INFO: The key is not added to SSH Agent"
  fi
  echo "TODO: Manage sshconfig"
}

function add_sshhostslist ()
{
  if [[ "${sshhostentry}" != "" ]]
  then
    if [[ $(echo "${sshhostentry}" | wc -l) -gt 1 ]]
    then
      sshhoststring="$(echo "${sshhostentry}" | grep -Po '^Host\s+\K([^\s].*)' || true)"
      if [[ "${sshhoststring}" != "" ]]
      then
        sshidfile="$(echo "${sshhostentry}" | grep -Po '^\s+IdentityFile\s+\K(.*)' || true)"
        if [[ "${sshidfile}" != "" ]]
        then
          if [[ -f "${sshidfile/\~/$HOME}" ]]
          then
            sshhostslist+=("${sshhostentry}")
          fi
        fi
      fi
    fi
    sshhostentry=""
  fi
}

function print_sshhostslist ()
{
  if [[ "${DEBUG}" == "true" ]]
  then
    echo "*** INI Show sshhostslist array"
    for indexarr in "${!sshhostslist[@]}"
    do
      printf "Number %s\n%s\n" "${indexarr}" "${sshhostslist[${indexarr}]}"
    done
    echo "*** END Show sshhostslist array"
  fi
}

function parse_sshhostslist ()
{
  sshhostentry=""
  while IFS= read -r inputline
  do
    # Discard empty, space or comment lines
    echo "${inputline}" | grep -qPo '^\s*(#|$)' && continue
    if [[ "$(echo "${inputline}" | sed -r -n '/^Host\s+[^\s].*$/p')" != "" ]]
    then
      # Begin of processing a new SSH Host entry
      [[ "${DEBUG}" == "true" ]] && echo "New Host entry <${inputline}>"
      # Add to sshhostslist if this entry is good
      add_sshhostslist
      if [[ "${sshhostentry}" != "" ]]
      then
        sshhostentry+=$'\n'"${inputline}"
      else
        sshhostentry+="${inputline}"
      fi
    elif [[ "$(echo "${inputline}" | sed -r -n '/^\s+[^\s].*$/p')" != "" ]]
    then
      # Process of one SSH Host item
      [[ "${DEBUG}" == "true" ]] && echo "Host item <${inputline}>"
      [[ "${sshhostentry}" != "" ]] && sshhostentry+=$'\n'"${inputline}" || continue
    else
      # Process others not contemplated
      [[ "${DEBUG}" == "true" ]] && echo "Not contemplated <${inputline}>"
      # If the entry is still in process then add to sshhostslist if this entry is good
      [[ "${sshhostentry}" != "" ]] && add_sshhostslist
      continue
    fi
  done < $HOME/.ssh/config.auto
  # For the last entry still in process then add to sshhostslist if this entry is good
  add_sshhostslist
  # Print sshhostslist array for debug only
  print_sshhostslist
}

# Associative array for manage the client parameters of this tool
declare -A parmlist=()

# Execute with required arguments
if [ "$#" == "0" ]; then help; fi

while [ $# -gt 0 ] ; do
  case "${1}" in
    --set-sshclient)
      [[ -v parmlist[--set-sshclient] ]] && help "ERROR: Repeated parameters"
      parmlist[--set-sshclient]=""
      ;;
    --deleteall-sshclient)
      [[ -v parmlist[--deleteall-sshclient] ]] && help "ERROR: Repeated parameters"
      parmlist[--deleteall-sshclient]=""
      ;;
    --show-sshclient)
      [[ -v parmlist[--show-sshclient] ]] && help "ERROR: Repeated parameters"
      parmlist[--show-sshclient]=""
      ;;
    --deleteall-sshagent)
      [[ -v parmlist[--deleteall-sshagent] ]] && help "ERROR: Repeated parameters"
      parmlist[--deleteall-sshagent]=""
      ;;
    --deleteall-sshconfig)
      [[ -v parmlist[--deleteall-sshconfig] ]] && help "ERROR: Repeated parameters"
      parmlist[--deleteall-sshconfig]=""
      ;;
    --delete-sshkey)
      [[ -v parmlist[--delete-sshkey] ]] && help "ERROR: Repeated parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --delete-sshkey"
      parmlist[--delete-sshkey]="${2}"
      shift
      ;;
    --show-sshkey)
      [[ -v parmlist[--show-sshkey] ]] && help "ERROR: Repeated parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --show-sshkey"
      parmlist[--show-sshkey]="${2}"
      shift
      ;;
    --create-sshkey)
      [[ -v parmlist[--create-sshkey] ]] && help "ERROR: Repeated parameters"
      [[ -v parmlist[--config-sshkey] ]] && help "ERROR: Mixed parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --create-sshkey"
      parmlist[--create-sshkey]="${2}"
      shift
      ;;
    --import)
      [[ -v parmlist[--import] ]] && help "ERROR: Repeated parameters"
      [[ ! -v parmlist[--create-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey"
      parmlist[--import]=""
      ;;
    --config-sshkey)
      [[ -v parmlist[--config-sshkey] ]] && help "ERROR: Repeated parameters"
      [[ -v parmlist[--create-sshkey] ]] && help "ERROR: Mixed parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --config-sshkey"
      parmlist[--config-sshkey]="${2}"
      shift
      ;;
    --add-sshagent)
      [[ -v parmlist[--add-sshagent] ]] && help "ERROR: Repeated parameters"
      [[ ! -v parmlist[--create-sshkey] && ! -v parmlist[--config-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey or --config-sshkey"
      [[ -v parmlist[--delete-sshagent] ]] && help "ERROR: Mixed parameters"
      parmlist[--add-sshagent]=""
      ;;
    --delete-sshagent)
      [[ -v parmlist[--delete-sshagent] ]] && help "ERROR: Repeated parameters"
      [[ ! -v parmlist[--create-sshkey] && ! -v parmlist[--config-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey or --config-sshkey"
      [[ -v parmlist[--add-sshagent] ]] && help "ERROR: Mixed parameters"
      parmlist[--delete-sshagent]=""
      ;;
    --add-sshconfig)
      [[ -v parmlist[--add-sshconfig] ]] && help "ERROR: Repeated parameters"
      [[ ! -v parmlist[--create-sshkey] && ! -v parmlist[--config-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey or --config-sshkey"
      [[ -v parmlist[--delete-sshconfig] ]] && help "ERROR: Mixed parameters"
      [[ "${2}" == "" || "${2}" =~ ^--.*$ ]] && help "ERROR: Missing argument --add-sshconfig"
      parmlist[--add-sshconfig]="${2}"
      shift
      ;;
    --delete-sshconfig)
      [[ -v parmlist[--delete-sshconfig] ]] && help "ERROR: Repeated parameters"
      [[ ! -v parmlist[--create-sshkey] && ! -v parmlist[--config-sshkey] ]] && help "ERROR: This parameter only work with --create-sshkey or --config-sshkey"
      [[ -v parmlist[--add-sshconfig] ]] && help "ERROR: Mixed parameters"
      parmlist[--delete-sshconfig]=""
      ;;
    --help)
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

# Array for manage SSH client settings host entries stored inside $HOME/.ssh/config.auto
sshhostslist=()

if [[ -v parmlist[--set-sshclient] ]]
then
  [[ ${#parmlist[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  # Apply SSH client settings
  set_sshclient
elif [[ -v parmlist[--deleteall-sshclient] ]]
then
  [[ ${#parmlist[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  [[ -d $HOME/.ssh ]] && confirmquestion "WARN: The directory $HOME/.ssh will be deleted" && (rm -rf $HOME/.ssh; ssh-add -D) || :
elif [[ -v parmlist[--show-sshclient] ]]
then
  [[ ${#parmlist[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  echo "INFO: Show SSH client settings"
  TOOL_CHECKS_LIST=(openssl openssh)
  for mytool in "${TOOL_CHECKS_LIST[@]}"
  do
    case ${mytool} in
      openssl)
        echo "--- CHECK version ${mytool}"
        ${mytool} version
        echo "--- CHECK path ${mytool}: $(which ${mytool})"
      ;;
      openssh)
        othercommand=ssh
        echo "--- CHECK version ${mytool} (${othercommand})"
        ${othercommand} -V
        echo "--- CHECK path ${mytool} (${othercommand}): $(which ${othercommand})"
      ;;
      *)
        echo "--- CHECK version ${mytool}"
        ${mytool} --version
        echo "--- CHECK path ${mytool}: $(which ${mytool})"
      ;;
    esac
  done
  echo "INI: SSH Agent List"
  ssh-add -L || true
  echo "END: SSH Agent List"
  if [[ -d $HOME/.ssh ]]
  then
    echo "ls -dl \$HOME/.ssh"
    ls -dl $HOME/.ssh
    echo "ls -l \$HOME/.ssh"
    ls -l $HOME/.ssh
    [[ -f $HOME/.ssh/config ]] && (echo "INI \$HOME/.ssh/config"; cat $HOME/.ssh/config; echo "END \$HOME/.ssh/config") || echo "WARN: The file $HOME/.ssh/config does not exist or is not a file"
    [[ -f $HOME/.ssh/config.generic ]] && (echo "INI \$HOME/.ssh/config.generic"; cat $HOME/.ssh/config.generic; echo "END \$HOME/.ssh/config.generic") || echo "WARN: The file $HOME/.ssh/config.generic does not exist or is not a file"
    [[ -f $HOME/.ssh/config.auto ]] && (echo "INI \$HOME/.ssh/config.auto"; cat $HOME/.ssh/config.auto; echo "END \$HOME/.ssh/config.auto") || echo "WARN: The file $HOME/.ssh/config.auto does not exist or is not a file"
  else
    echo "WARN: The directory $HOME/.ssh does not exist or is not a directory"
  fi
elif [[ -v parmlist[--deleteall-sshagent] ]]
then
  [[ ${#parmlist[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  confirmquestion "WARN: Delete all identities from the agent" && ssh-add -D || :
elif [[ -v parmlist[--deleteall-sshconfig] ]]
then
  [[ ${#parmlist[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  confirmquestion "WARN: Delete $HOME/.ssh/config.auto file" && rm -f $HOME/.ssh/config.auto || :
  # Apply SSH client settings
  set_sshclient
elif [[ -v parmlist[--delete-sshkey] ]]
then
  [[ ${#parmlist[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  # Basic verification of parameter values
  echo "${parmlist[--delete-sshkey]}" | grep -Pxq '\w+|\w+((-|_)?\w+)+' || help "ERROR: The argument filename-privatekey must be a valid value"
  # Apply SSH client settings
  set_sshclient
  ACTION=false
  [[ -f "$HOME/.ssh/${parmlist[--delete-sshkey]}" ]] && confirmquestion "WARN: All the data of the SSH private key $HOME/.ssh/${parmlist[--delete-sshkey]} will be deleted" && ACTION=true || ACTION=false
  if [[ "${ACTION}" == "true" ]]
  then
    echo "INFO: Delete $HOME/.ssh/${parmlist[--delete-sshkey]} from SSH Agent if exist"
    ssh-add -d $HOME/.ssh/${parmlist[--delete-sshkey]} 2>/dev/null || true
    ssh-add -d $HOME/.ssh/${parmlist[--delete-sshkey]}.pub 2>/dev/null || true
    while IFS= read -r inputline
    do
      [[ "${DEBUG}" == "true" ]] && echo "WARN: Delete possibly orphaned key from SSH Agent"
      [[ "${DEBUG}" == "true" ]] && echo "${inputline}"
      echo "${inputline}" | ssh-add -d -
    done < <(ssh-add -L | grep "/${parmlist[--delete-sshkey]}$" || true)
    echo "TODO: Manage sshconfig"
    echo "INFO: Delete SSH PEM RSA private key $HOME/.ssh/${parmlist[--delete-sshkey]} and public key $HOME/.ssh/${parmlist[--delete-sshkey]}.pub"
    rm -f $HOME/.ssh/${parmlist[--delete-sshkey]}
    rm -f $HOME/.ssh/${parmlist[--delete-sshkey]}.pub
  else
    :
  fi
elif [[ -v parmlist[--show-sshkey] ]]
then
  [[ ${#parmlist[@]} -ne 1 ]] && help "ERROR: Mixed parameters"
  # Basic verification of parameter values
  echo "${parmlist[--show-sshkey]}" | grep -Pxq '\w+|\w+((-|_)?\w+)+' || help "ERROR: The argument filename-privatekey must be a valid value"
  # Apply SSH client settings
  set_sshclient
  show_sshkey ${parmlist[--show-sshkey]}
elif [[ -v parmlist[--create-sshkey] ]]
then
  # Basic verification of parameter values
  echo "${parmlist[--create-sshkey]}" | grep -Pxq '\w+|\w+((-|_)?\w+)+' || help "ERROR: The argument filename-privatekey must be a valid value"
  if [[ -v parmlist[--add-sshconfig] ]]
  then
    echo "${parmlist[--add-sshconfig]}" | grep -Pxq '[^\s,]+(,[^\s,]+)*' || help "ERROR: The SSH config hosts are not valid"
  else
    :
  fi
  # Apply SSH client settings
  set_sshclient
  ACTION=false
  if [[ -f "$HOME/.ssh/${parmlist[--create-sshkey]}" ]]
  then
    confirmquestion "WARN: The file $HOME/.ssh/${parmlist[--create-sshkey]} will be overwritten" && ACTION=true || ACTION=false
  else
    ACTION=true
  fi
  if [[ "${ACTION}" == "true" ]]
  then
    if [[ -v parmlist[--import] ]]
    then
      echo "INFO: Copy and paste the SSH PEM RSA private key and press enter to end to store in $HOME/.ssh/${parmlist[--create-sshkey]}"
      truncate -s 0 $HOME/.ssh/${parmlist[--create-sshkey]}
      chmod 600 $HOME/.ssh/${parmlist[--create-sshkey]}
      while IFS= read -r inputline
      do
        [ -z "${inputline}" ] && break
        printf "%s\n" "${inputline}" >> $HOME/.ssh/${parmlist[--create-sshkey]}
      done < /dev/stdin
      echo "INFO: Create the SSH RSA public key $HOME/.ssh/${parmlist[--create-sshkey]}.pub from the provided private key $HOME/.ssh/${parmlist[--create-sshkey]}"
      ssh-keygen -y -f $HOME/.ssh/${parmlist[--create-sshkey]} > $HOME/.ssh/${parmlist[--create-sshkey]}.pub
      chmod 600 $HOME/.ssh/${parmlist[--create-sshkey]}.pub
    else
      echo "INFO: Create SSH PEM RSA private key $HOME/.ssh/${parmlist[--create-sshkey]} and public key $HOME/.ssh/${parmlist[--create-sshkey]}.pub"
      ssh-keygen -b 4096 -t rsa -m PKCS8 -N "" -C "my@${parmlist[--create-sshkey]}" -f $HOME/.ssh/${parmlist[--create-sshkey]} <<< $'y'
    fi
    chmod 600 $HOME/.ssh/${parmlist[--create-sshkey]} $HOME/.ssh/${parmlist[--create-sshkey]}.pub
  fi
  if [[ -v parmlist[--add-sshagent] ]]
  then
    echo "INFO: Add $HOME/.ssh/${parmlist[--create-sshkey]} to SSH Agent"
    ssh-add $HOME/.ssh/${parmlist[--create-sshkey]}
  fi
  if [[ -v parmlist[--delete-sshagent] ]]
  then
    echo "INFO: Delete $HOME/.ssh/${parmlist[--create-sshkey]} from SSH Agent"
    ssh-add -d $HOME/.ssh/${parmlist[--create-sshkey]} || true
  fi
  if [[ -v parmlist[--delete-sshconfig] ]]
  then
    echo "TODO: Manage sshconfig"
  fi
  if [[ -v parmlist[--add-sshconfig] ]]
  then
    echo "TODO: Manage sshconfig"
#    echo "INFO: Add $HOME/.ssh/${parmlist[--create-sshkey]} to SSH client settings Host in $HOME/.ssh/config.auto"
#    printf "Host %s\n  IdentityFile %s\n  IdentitiesOnly yes\n  ForwardAgent yes\n" "${ADDTO_SSHCONFIG}" "~/.ssh/${parmlist[--create-sshkey]}" >> $HOME/.ssh/config.auto
  fi
elif [[ -v parmlist[--config-sshkey] ]]
then
  # Basic verification of parameter values
  echo "${parmlist[--config-sshkey]}" | grep -Pxq '\w+|\w+((-|_)?\w+)+' || help "ERROR: The argument filename-privatekey must be a valid value"
  if [[ -v parmlist[--add-sshconfig] ]]
  then
    echo "${parmlist[--add-sshconfig]}" | grep -Pxq '[a-zA-Z\d]+(-[a-zA-Z\d]+)*(\.[a-zA-Z\d]+(-[a-zA-Z\d]+)*)*(\s+[a-zA-Z\d]+(-[a-zA-Z\d]+)*(\.[a-zA-Z\d]+(-[a-zA-Z\d]+)*)*)*' || help "ERROR: The SSH config hosts are not valid"
  else
    :
  fi
  # Apply SSH client settings
  set_sshclient
  if [[ -v parmlist[--add-sshagent] ]]
  then
    echo "INFO: Add $HOME/.ssh/${parmlist[--config-sshkey]} to SSH Agent"
    ssh-add $HOME/.ssh/${parmlist[--config-sshkey]}
  fi
  if [[ -v parmlist[--delete-sshagent] ]]
  then
    echo "INFO: Delete $HOME/.ssh/${parmlist[--config-sshkey]} from SSH Agent"
    ssh-add -d $HOME/.ssh/${parmlist[--config-sshkey]} || true
  fi
  if [[ -v parmlist[--delete-sshconfig] ]]
  then
    echo "TODO: Manage sshconfig"
  fi
  if [[ -v parmlist[--add-sshconfig] ]]
  then
    echo "TODO: Manage sshconfig"
    parse_sshhostslist

    for indexarr in "${!sshhostslist[@]}"
    do
      printf "Number %s\n%s\n" "${indexarr}" "${sshhostslist[${indexarr}]}"
    done

    echo "INFO: Add $HOME/.ssh/${parmlist[--config-sshkey]} to SSH client settings Host $HOME/.ssh/config.auto"
    printf "Host %s\n  IdentityFile %s\n  IdentitiesOnly yes\n  ForwardAgent yes\n" "${parmlist[--add-sshconfig]}" "~/.ssh/${parmlist[--config-sshkey]}" >> $HOME/.ssh/config.auto
#    printf "Host %s\n  IdentityFile %s\n  IdentitiesOnly yes\n  ForwardAgent yes\n" "${ADDTO_SSHCONFIG}" "~/.ssh/${parmlist[--config-sshkey]}" >> $HOME/.ssh/config.auto
  fi
else
  help "ERROR: Internal error"
fi


[[ "${RESULT}" != "0" ]] && echo "ERROR: Some errors exists. Error code ${RESULT}"
exit ${RESULT}
