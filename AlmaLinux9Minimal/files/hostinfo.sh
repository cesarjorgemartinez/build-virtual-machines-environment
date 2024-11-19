#!/usr/bin/env bash

MYUSER=$(whoami)
MYHOSTNAME=$(uname -n)
MYPROCESSES=$(ps -Afl | wc -l)
MYINTERFACES="$(ip -4 ad | grep 'state' | awk -F ": " '!/^[0-9]*: ?lo/ {print $2}')"

COLOR_COLUMN="\e[1m"
COLOR_VALUE="\e[31m"
RESET_COLORS="\e[0m"

echo -e "===========================================================================
${COLOR_COLUMN}HOSTNAME${RESET_COLORS}...........: ${COLOR_VALUE}${MYHOSTNAME}${RESET_COLORS}
${COLOR_COLUMN}INTERFACES${RESET_COLORS}.........:
${COLOR_VALUE}$(printf "%-18s%-18s%-46s%-46s" "Interface" "MAC Address" "IP4 Address" "IP6 Address" | sed -e 's/[[:space:]]*$//')${RESET_COLORS}
${COLOR_VALUE}$(for ifacename in ${MYINTERFACES}
do
  mac=$(ip ad show dev ${ifacename} | grep link/ether | awk '{print $2}')
  ip4=$(ip ad show dev ${ifacename} | grep -Fw inet | awk '{print $2}')
  ip6=$(ip ad show dev ${ifacename} | grep -Fw inet6 | awk '{print $2}')
  printf "%-18s%-18s%-46s%-46s\n" "${ifacename}" "${mac}" "${ip4}" "${ip6}" | sed -e 's/[[:space:]]*$//'
done)${RESET_COLORS}
${COLOR_COLUMN}CPU TOTAL${RESET_COLORS}..........: ${COLOR_VALUE}$(nproc --all)${RESET_COLORS}
${COLOR_COLUMN}CPU ONLINE${RESET_COLORS}.........: ${COLOR_VALUE}$(nproc)${RESET_COLORS}
${COLOR_COLUMN}MEMORY${RESET_COLORS}.............:
${COLOR_VALUE}$(free -h)${RESET_COLORS}
${COLOR_COLUMN}FILESYSTEMS${RESET_COLORS}........:
${COLOR_VALUE}$(df -Ph | egrep -v '^overlay|^shm')${RESET_COLORS}
${COLOR_COLUMN}SYSTEM UPTIME${RESET_COLORS}......: ${COLOR_VALUE}$(uptime | xargs)${RESET_COLORS}
${COLOR_COLUMN}RELEASE${RESET_COLORS}............: ${COLOR_VALUE}$(source /etc/os-release && echo "${NAME} ${VERSION}")${RESET_COLORS}
${COLOR_COLUMN}KERNEL${RESET_COLORS}.............: ${COLOR_VALUE}$(uname -r)${RESET_COLORS}
${COLOR_COLUMN}DATE${RESET_COLORS}...............: ${COLOR_VALUE}$(date)${RESET_COLORS}
${COLOR_COLUMN}USERS${RESET_COLORS}..............: ${COLOR_VALUE}Currently $(users | wc -w) user(s) logged on${RESET_COLORS}
${COLOR_COLUMN}CURRENT USER${RESET_COLORS}.......: ${COLOR_VALUE}${MYUSER}${RESET_COLORS}
${COLOR_COLUMN}PROCESSES${RESET_COLORS}..........: ${COLOR_VALUE}${MYPROCESSES} running${RESET_COLORS}
${COLOR_COLUMN}CPU DETAILED INFO${RESET_COLORS}..:
${COLOR_VALUE}$(lscpu)${RESET_COLORS}
==========================================================================="

