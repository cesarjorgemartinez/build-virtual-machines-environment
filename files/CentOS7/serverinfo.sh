#!/usr/bin/env bash

MYUSER=$(whoami)
MYHOSTNAME=$(uname -n)
MYPROCESSES=$(ps -Afl | wc -l)
MYINTERFACES="$(ip -4 ad | grep 'state' | awk -F ": " '!/^[0-9]*: ?lo/ {print $2}')"
MYCPUCORES="$(grep -c ^processor /proc/cpuinfo)"

COLOR_COLUMN="\e[1m"
COLOR_VALUE="\e[31m"
RESET_COLORS="\e[0m"

echo -e "===========================================================================
${COLOR_COLUMN}HOSTNAME${RESET_COLORS}...........: ${COLOR_VALUE}${MYHOSTNAME}${RESET_COLORS}
${COLOR_COLUMN}INTERFACES${RESET_COLORS}.........:
${COLOR_VALUE}Interface\tMAC Address\t\tIP4 Address\t\tIP6 Address${RESET_COLORS}
${COLOR_VALUE}$(for x in ${MYINTERFACES}
do
  mac=$(ip ad show dev $x | grep link/ether | awk '{print $2}')
  ip4=$(ip ad show dev $x | grep -Fw inet | awk '{print $2}')
  ip6=$(ip ad show dev $x | grep -Fw inet6 | awk '{print $2}')
  printf  $x"\t\t"$mac"\t"$ip4"\t"$ip6"\n"
done)${RESET_COLORS}
${COLOR_COLUMN}CPU CORES${RESET_COLORS}..........: ${COLOR_VALUE}${MYCPUCORES}${RESET_COLORS}
${COLOR_COLUMN}MEMORY${RESET_COLORS}.............:
${COLOR_VALUE}$(free -h)${RESET_COLORS}
${COLOR_COLUMN}FILESYSTEMS${RESET_COLORS}........:
${COLOR_VALUE}$(df -Ph)${RESET_COLORS}
${COLOR_COLUMN}SYSTEM UPTIME${RESET_COLORS}......: ${COLOR_VALUE}$(uptime)${RESET_COLORS}
${COLOR_COLUMN}RELEASE${RESET_COLORS}............: ${COLOR_VALUE}$(cat /etc/redhat-release)${RESET_COLORS}
${COLOR_COLUMN}KERNEL${RESET_COLORS}.............: ${COLOR_VALUE}$(uname -r)${RESET_COLORS}
${COLOR_COLUMN}DATE${RESET_COLORS}...............: ${COLOR_VALUE}$(date)${RESET_COLORS}
${COLOR_COLUMN}USERS${RESET_COLORS}..............: ${COLOR_VALUE}Currently $(users | wc -w) user(s) logged on${RESET_COLORS}
${COLOR_COLUMN}CURRENT USER${RESET_COLORS}.......: ${COLOR_VALUE}${MYUSER}${RESET_COLORS}
${COLOR_COLUMN}PROCESSES${RESET_COLORS}..........: ${COLOR_VALUE}${MYPROCESSES} running${RESET_COLORS}
==========================================================================="

