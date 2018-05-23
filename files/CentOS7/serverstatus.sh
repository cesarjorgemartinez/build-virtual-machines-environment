#!/usr/bin/env bash

MYUSER=$(whoami)
MYHOSTNAME=$(uname -n)
MYIP=$(hostname -i)
MYPROCESSES=$(ps -Afl | wc -l)
MYINTERFACES=$(ip -4 ad | grep 'state UP' | awk -F ":" '!/^[0-9]*: ?lo/ {print $2}')
MYCPUCORES="$(grep -c ^processor /proc/cpuinfo)"

COLOR_COLUMN="\e[1m"
COLOR_VALUE="\e[31m"
RESET_COLORS="\e[0m"

echo -e "===========================================================================
${COLOR_COLUMN}HOSTNAME${RESET_COLORS}.......: ${COLOR_VALUE}${MYHOSTNAME}${RESET_COLORS}
${COLOR_COLUMN}IP${RESET_COLORS}.............: ${COLOR_VALUE}${MYIP}${RESET_COLORS}
${COLOR_COLUMN}INTERFACES${RESET_COLORS}.....:
${COLOR_VALUE}Interface\tMAC Address\t\tIP Address${RESET_COLORS}
${COLOR_VALUE}$(for x in ${MYINTERFACES}
do
        MAC=$(ip ad show dev $x |grep link/ether |awk '{print $2}')
        IP=$(ip ad show dev $x |grep -v inet6 | grep inet|awk '{print $2}')
        printf  $x"\t\t"$MAC"\t"$IP"\t\n"
done)${RESET_COLORS}
${COLOR_COLUMN}CPU CORES${RESET_COLORS}......: ${COLOR_VALUE}${MYCPUCORES}${RESET_COLORS}
${COLOR_COLUMN}MEMORY${RESET_COLORS}.........:
${COLOR_VALUE}$(free -h)${RESET_COLORS}
${COLOR_COLUMN}DISKS${RESET_COLORS}...........:
${COLOR_VALUE}$(df -Ph)${RESET_COLORS}
${COLOR_COLUMN}SYSTEM UPTIME${RESET_COLORS}..:
${COLOR_VALUE}$(uptime)${RESET_COLORS}
${COLOR_COLUMN}RELEASE${RESET_COLORS}........: ${COLOR_VALUE}$(cat /etc/redhat-release)${RESET_COLORS}
${COLOR_COLUMN}KERNEL${RESET_COLORS}.........: ${COLOR_VALUE}$(uname -r)${RESET_COLORS}
${COLOR_COLUMN}DATE${RESET_COLORS}...........: ${COLOR_VALUE}$(date)${RESET_COLORS}
${COLOR_COLUMN}USERS${RESET_COLORS}..........: ${COLOR_VALUE}Currently $(users | wc -w) user(s) logged on${RESET_COLORS}
${COLOR_COLUMN}CURRENT USER${RESET_COLORS}...: ${COLOR_VALUE}${MYUSER}${RESET_COLORS}
${COLOR_COLUMN}PROCESSES${RESET_COLORS}......: ${COLOR_VALUE}${MYPROCESSES} running${RESET_COLORS}
==========================================================================="

