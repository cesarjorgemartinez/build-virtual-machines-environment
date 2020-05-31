#!/usr/bin/env bash

echo "INFO: Stop systemd-journald-audit.socket"
systemctl stop systemd-journald-audit.socket

echo "INFO: Stop systemd-journald.service"
systemctl stop systemd-journald.service

echo "INFO: Stop systemd-journald-dev-log.socket"
systemctl stop systemd-journald-dev-log.socket

echo "INFO: Stop systemd-journald.socket"
systemctl stop systemd-journald.socket

echo "INFO: Current date"
date

export DEBIAN_FRONTEND=noninteractive

echo "INFO: Update all packages"
apt-get update -y
echo "INFO: Upgrade all packages"
apt-get full-upgrade -y

echo "INFO: Install utils"
apt-get install -y --no-install-recommends virt-what net-tools acpid jq nmap ncat

echo "INFO: Remove ufw firewall"
apt-get purge -y ufw

echo "INFO: Enable and start acpid daemon"
systemctl enable acpid
systemctl start acpid

echo "INFO: Autoremove unused things"
apt-get purge -y -qq snapd squashfs-tools
apt-get --purge -y -qq autoremove

echo "INFO: Clean all caches"
apt-get clean
find /var/cache -type f -delete

echo "INFO: Remove unneeded locales in /usr/share/locale folder except en_US, es_ES and locale.alias"
find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en_US' ! -name 'es_ES' ! -name 'locale.alias' | xargs -r rm -r

echo "INFO: Remove unneeded i18n locales in /usr/share/i18n/locales folder except en_US* and es_ES*"
find /usr/share/i18n/locales -mindepth 1 -maxdepth 1 ! -name 'en_US*' ! -name 'es_ES*' | xargs -r rm -r

echo "INFO: Remove unneeded locales in /usr/share/man folder except es and man*"
find /usr/share/man -mindepth 1 -maxdepth 1 ! -name 'es' ! -name 'man*' | xargs -r rm -r
find /var/cache/man -mindepth 1 -maxdepth 1 ! -name 'es' ! -name 'man*' | xargs -r rm -r

echo "INFO: Install host-info.sh script to /usr/local/bin/host-info.sh"
mv host-info.sh /usr/local/bin
chown root.root /usr/local/bin/host-info.sh
chmod +x /usr/local/bin/host-info.sh

echo "INFO: Install control-cloud-init.sh script to /usr/local/bin/control-cloud-init.sh"
mv control-cloud-init.sh /usr/local/bin
chown root.root /usr/local/bin/control-cloud-init.sh
chmod +x /usr/local/bin/control-cloud-init.sh

echo "INFO: Install Systemd Unit /etc/systemd/system/control-cloud-init.service"
mv control-cloud-init.service /etc/systemd/system/control-cloud-init.service
chown root.root /etc/systemd/system/control-cloud-init.service
chmod 644 /etc/systemd/system/control-cloud-init.service

echo "INFO: Install guest-vmtools.sh script to /usr/local/bin/guest-vmtools.sh"
mv guest-vmtools.sh /usr/local/bin
chown root.root /usr/local/bin/guest-vmtools.sh
chmod +x /usr/local/bin/guest-vmtools.sh

echo "INFO: Install Systemd Unit /etc/systemd/system/guest-vmtools.service"
mv guest-vmtools.service /etc/systemd/system/guest-vmtools.service
chown root.root /etc/systemd/system/guest-vmtools.service
chmod 644 /etc/systemd/system/guest-vmtools.service

echo "INFO: Install switch-to-graphical-user-interface.sh file to /usr/local/bin/switch-to-graphical-user-interface.sh"
mv switch-to-graphical-user-interface.sh /usr/local/bin/switch-to-graphical-user-interface.sh
chown root.root /usr/local/bin/switch-to-graphical-user-interface.sh
chmod +x /usr/local/bin/switch-to-graphical-user-interface.sh

echo "INFO: Install switch-to-text-user-interface.sh file to /usr/local/bin/switch-to-text-user-interface.sh"
mv switch-to-text-user-interface.sh /usr/local/bin/switch-to-text-user-interface.sh
chown root.root /usr/local/bin/switch-to-text-user-interface.sh
chmod +x /usr/local/bin/switch-to-text-user-interface.sh

echo "INFO: Reload systemd daemon"
systemctl daemon-reload

echo "INFO: Enable at boot control-cloud-init.service"
systemctl enable control-cloud-init.service

echo "INFO: Enable at boot guest-vmtools.service"
systemctl enable guest-vmtools.service

echo "INFO: Clear out machine id"
/bin/cat /dev/null > /etc/machine-id

echo "INFO: Delete packer user"
cd /tmp
userdel -f -r packer

echo "INFO: Create the admin user ${so_adminuser}"
useradd -m -U -d /home/${so_adminuser} -c "${so_adminuser}" -G adm,cdrom,dip,lxd,plugdev,sudo -s /bin/bash ${so_adminuser}
echo "${so_adminuser}:${so_adminpass}" | chpasswd ${so_adminuser}

echo "INFO: Add the admin user to /etc/sudoers file"
echo "${so_adminuser} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
sudo -i -u ${so_adminuser}

echo "INFO: Configure sshd to enter with the admin user remotely"
echo "#Match User ${so_adminuser}
#  PasswordAuthentication yes
" >> /etc/ssh/sshd_config

echo "INFO: Configure cloud-init. Set default ssh default_user from cloud-user to ${so_defaultclouduser}"
sed -r -i 's/^ +name:.+/    name: '${so_defaultclouduser}'/' /etc/cloud/cloud.cfg

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
  swappart=$(readlink -f /dev/disk/by-uuid/$swapuuid)
  /sbin/swapoff "${swappart}"
  dd if=/dev/zero of="${swappart}" bs=1M || echo "dd exit code $? is suppressed"
  /sbin/mkswap -U "${swapuuid}" "${swappart}"
fi

echo "INFO: Remove unneeded files"
find /usr/lib -type f -name "*.pyc" -delete
find /usr/share -type f -name "*.pyc" -delete
rm -rf /var/log/journal/*
rm -f /usr/share/mime/mime.cache

echo "INFO: Force logs to rotate"
/usr/sbin/logrotate -f /etc/logrotate.conf
sleep 2
sync
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
sync

echo "INFO: Clean caches free xfs inodes and fill free space with zeroes..."
echo 3 > /proc/sys/vm/drop_caches
xfs_fsr -v
dd if=/dev/zero | dd of=/bigemptyfile bs=4096k || echo "dd exit code $? is suppressed"
rm -f /bigemptyfile
dd if=/dev/zero | dd of=/boot/bigemptyfile bs=4096k || echo "dd exit code $? is suppressed"
rm -f /boot/bigemptyfile
sync

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
sync

