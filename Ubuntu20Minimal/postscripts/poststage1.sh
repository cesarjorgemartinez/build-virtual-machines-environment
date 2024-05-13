#!/usr/bin/env bash

echo "INFO: Current date"
date

echo "INI: Show /var/log/installer/curtin-install.log"
cat /var/log/installer/curtin-install.log
echo "END: Show /var/log/installer/curtin-install.log"

echo "INFO: Clear out swap and disable until next reboot"
set +e
swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
case "$?" in
  2|0) ;;
  *) exit 1 ;;
esac
set -e
if [ "x${swapuuid}" != "x" ]
then
  # Whiteout the swap partition to reduce box size
  # Swap is disabled till reboot
  swappart=$(readlink -f /dev/disk/by-uuid/${swapuuid})
  /sbin/swapoff "${swappart}"
  dd if=/dev/zero of="${swappart}" bs=4096k || echo "dd exit code $? is suppressed"
  sync; sleep 1; sync
  /sbin/mkswap -U "${swapuuid}" "${swappart}"
  sync; sleep 1; sync
fi

echo "INFO: Stop SystemD journal services"
systemctl stop systemd-journald.service
systemctl stop systemd-journal-flush.service
systemctl stop systemd-journald.socket
systemctl stop systemd-journald-dev-log.socket
systemctl stop systemd-journald-audit.socket

echo "INFO: Assure that unattended-upgrades package is disabled to prevent Apt lock timeouts"
systemctl disable unattended-upgrades.service
systemctl stop unattended-upgrades.service
systemctl mask unattended-upgrades.service

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l

echo "INFO: Update packages"
apt-get update
echo "INFO: Upgrade packages"
apt-get -y --no-install-recommends -o DPkg::Lock::Timeout=120 upgrade
echo "INFO: Dist-upgrade packages"
apt-get -y --no-install-recommends -o DPkg::Lock::Timeout=120 dist-upgrade

echo "INFO: Install utils"
apt-get -y install --no-install-recommends virt-what net-tools acpid jq nmap ncat glances

echo "INFO: Remove ufw firewall"
apt-get -y purge ufw

echo "INFO: Enable and start acpid daemon"
systemctl enable acpid
systemctl start acpid

echo "INFO: Autoremove unused things"
# snap remove --purge lxd
# snap remove --purge core18
# snap remove --purge snapd
# apt-get -y purge -qq snapd squashfs-tools
apt-get -y --purge -qq autoremove

echo "INFO: Clean all caches"
apt-get clean
find /var/cache -type f -delete

echo "INFO: Remove unneeded locales in /usr/share/locale folder except en, en_US, es, es_ES and locale.alias"
find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en' ! -name 'en_US' ! -name 'es' ! -name 'es_ES' ! -name 'locale.alias' | xargs -r rm -r

echo "INFO: Remove unneeded i18n locales in /usr/share/i18n/locales folder except en_US and es_ES and C"
find /usr/share/i18n/locales -mindepth 1 -maxdepth 1 ! -name 'en_US' ! -name 'es_ES' ! -name 'C' | xargs -r rm -r

echo "INFO: Remove unneeded locales in /usr/share/man folder except es and man*"
find /usr/share/man -mindepth 1 -maxdepth 1 ! -name 'es' ! -name 'man*' | xargs -r rm -r
find /var/cache/man -mindepth 1 -maxdepth 1 ! -name 'es' ! -name 'man*' | xargs -r rm -r

echo "INFO: Remove default locales in /usr/lib/locale/locale-archive except en_US and es_ES"
# localedef --list-archive | { egrep -ve '[e]n_US|[e]s_ES' || true; } | xargs -r sudo localedef --delete-from-archive
# /bin/cp -f /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
# build-locale-archive

echo "INFO: Remove unneeded locales in /usr/lib/locale folder except en_US* es_ES* C* and locale*"
find /usr/lib/locale -mindepth 1 -maxdepth 1 ! -name 'en_US*' ! -name 'es_ES*' ! -name 'C*' ! -name 'locale*' | xargs -r rm -r

echo "INFO: Install /usr/local/bin/hostinfo.sh"
mv hostinfo.sh /usr/local/bin
chown root.root /usr/local/bin/hostinfo.sh
chmod +x /usr/local/bin/hostinfo.sh

echo "INFO: Install /usr/local/bin/controlcloud-init.sh"
mv controlcloud-init.sh /usr/local/bin
chown root.root /usr/local/bin/controlcloud-init.sh
chmod +x /usr/local/bin/controlcloud-init.sh

echo "INFO: Install Systemd Unit /etc/systemd/system/controlcloud-init.service"
mv controlcloud-init.service /etc/systemd/system
chown root.root /etc/systemd/system/controlcloud-init.service
chmod 644 /etc/systemd/system/controlcloud-init.service

echo "INFO: Install /usr/local/bin/guestvmtools.sh"
mv guestvmtools.sh /usr/local/bin
chown root.root /usr/local/bin/guestvmtools.sh
chmod +x /usr/local/bin/guestvmtools.sh

echo "INFO: Install Systemd Unit /etc/systemd/system/guestvmtools.service"
mv guestvmtools.service /etc/systemd/system
chown root.root /etc/systemd/system/guestvmtools.service
chmod 644 /etc/systemd/system/guestvmtools.service

echo "INFO: Install /usr/local/bin/setguimode.sh"
mv setguimode.sh /usr/local/bin
chown root.root /usr/local/bin/setguimode.sh
chmod +x /usr/local/bin/setguimode.sh

echo "INFO: Install /usr/local/bin/settextmode.sh"
mv settextmode.sh /usr/local/bin
chown root.root /usr/local/bin/settextmode.sh
chmod +x /usr/local/bin/settextmode.sh

echo "INFO: Reload systemd daemon"
systemctl daemon-reload

echo "INFO: Enable at boot controlcloud-init.service"
systemctl enable controlcloud-init.service

echo "INFO: Enable at boot guestvmtools.service"
systemctl enable guestvmtools.service

echo "INFO: Clear out machine id"
/bin/cat /dev/null > /etc/machine-id

set -x

#    virtualbox-iso: INFO: Add the admin user to /etc/sudoers file
#==> virtualbox-iso: + echo 'admin ALL=(ALL) NOPASSWD: ALL'
#==> virtualbox-iso: + /usr/bin/sudo -i -u admin
#==> virtualbox-iso: -bash: line 1: packer: command not found
exit

echo "INFO: Delete packer user"
whoami
cd /tmp
/usr/sbin/userdel -f -r packer

echo "INFO: Create the admin user ${so_adminuser}"
/usr/sbin/useradd -m -U -d /home/${so_adminuser} -c "${so_adminuser}" -G adm,cdrom,dip,lxd,plugdev,sudo,dialout -s /bin/bash ${so_adminuser}
# useradd -m -U -d /home/${so_adminuser} -c "${so_adminuser}" -G adm,cdrom,dip,lxd,plugdev,sudo,dialout -s /bin/bash ${so_adminuser}
echo "${so_adminuser}:${so_adminpass}" | chpasswd ${so_adminuser}

echo "INFO: Add the admin user to /etc/sudoers file"
echo "${so_adminuser} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
/usr/bin/sudo -i -u ${so_adminuser}

echo "INFO: Configure sshd to enter with the admin user remotely"
echo "#Match User ${so_adminuser}
#  PasswordAuthentication yes
" >> /etc/ssh/sshd_config

echo "INFO: Configure cloud-init. Set default ssh default_user from cloud-user to ${so_defaultclouduser}"
sed -r -i -e 's/^( +name:).+/\1 '${so_defaultclouduser}'/g' /etc/cloud/cloud.cfg

echo "INFO: Clean data created by cloud-init and manage users"
rm -f /etc/group- /etc/gshadow- /etc/passwd- /etc/shadow-
rm -rf /var/lib/cloud

echo "INFO: Clear out swap and disable until next reboot"
set +e
swapuuid=$(/sbin/blkid -o value -l -s UUID -t TYPE=swap)
case "$?" in
  2|0) ;;
  *) exit 1 ;;
esac
set -e
if [ "x${swapuuid}" != "x" ]
then
  # Whiteout the swap partition to reduce box size
  # Swap is disabled till reboot
  swappart=$(readlink -f /dev/disk/by-uuid/${swapuuid})
  /sbin/swapoff "${swappart}"
  dd if=/dev/zero of="${swappart}" bs=4096k || echo "dd exit code $? is suppressed"
  sync; sleep 1; sync
  /sbin/mkswap -U "${swapuuid}" "${swappart}"
  sync; sleep 1; sync
fi

echo "INFO: Remove unneeded files"
find / -type f -name "*.pyc" -delete || true
rm -rf /var/log/journal/*
rm -f /usr/share/mime/mime.cache

echo "INFO: Force logs to rotate"
/usr/sbin/logrotate -f /etc/logrotate.conf
sleep 2
sync; sleep 1; sync
sleep 2

echo "INFO: Clean logs and temporary files"
rm -rf /tmp/* /var/tmp/*
rm -rf /root/.cache
find /var/log -name "*.log*" -type f -exec rm -f {} \;
find /var/log -name "*.[0-9]*" -type f -exec rm -f {} \;
find /var/log -name "*.gz" -type f -exec rm -f {} \;
rm -rf /var/log/installer
rm -f /var/log/syslog
rm -f /var/log/dmesg
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
/bin/cat /dev/null > /var/log/faillog
/bin/cat /dev/null > /var/log/btmp

echo "INFO: Clean bash history"
rm -f /root/.bash_history
unset HISTFILE
rm -f /home/${so_adminuser}/.bash_history
cat /dev/null > /home/${so_adminuser}/.bash_history
chown ${so_adminuser}.${so_adminuser} /home/${so_adminuser}/.bash_history
cat /dev/null > /root/.bash_history
history -c
sync; sleep 1; sync

echo "INFO: Clean caches free xfs inodes and fill free space with zeroes..."
echo 3 > /proc/sys/vm/drop_caches
xfs_fsr -v /boot
sync; sleep 1; sync
dd if=/dev/zero of=/boot/bigemptyfile bs=4096k || echo "dd exit code $? is suppressed"
sync; sleep 1; sync
rm -f /boot/bigemptyfile
sync; sleep 1; sync
xfs_fsr -v
sync; sleep 1; sync
dd if=/dev/zero of=/bigemptyfile bs=4096k || echo "dd exit code $? is suppressed"
rm -f /bigemptyfile
sync; sleep 1; sync

echo "INFO: Print to serial console a list of packages ordered by size" >> /dev/ttyS0
dpkg-query --show --showformat='${Installed-Size} ${Package}-${Version}.${Architecture}\n' | sort -rg >> /dev/ttyS0
echo "INFO: Print to serial console a list of all files ordered by size" >> /dev/ttyS0
find / -type f -print0 | xargs -0 du -h | sort -rh >> /dev/ttyS0

echo "INFO: Clean logs and temporary files"
rm -rf /tmp/* /var/tmp/*
rm -rf /root/.cache
find /var/log -name "*.log*" -type f -exec rm -f {} \;
find /var/log -name "*.[0-9]*" -type f -exec rm -f {} \;
find /var/log -name "*.gz" -type f -exec rm -f {} \;
rm -rf /var/log/installer
rm -f /var/log/syslog
rm -f /var/log/dmesg
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
/bin/cat /dev/null > /var/log/faillog
/bin/cat /dev/null > /var/log/btmp

echo "INFO: Clean bash history"
rm -f /root/.bash_history
unset HISTFILE
rm -f /home/${so_adminuser}/.bash_history
cat /dev/null > /home/${so_adminuser}/.bash_history
chown ${so_adminuser}.${so_adminuser} /home/${so_adminuser}/.bash_history
cat /dev/null > /root/.bash_history
history -c
sync; sleep 1; sync

