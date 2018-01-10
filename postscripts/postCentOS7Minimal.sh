#!/usr/bin/env bash

echo "INFO: Stop auditd service. Not use systemctl to stop because not stop"
service auditd stop

# echo "INFO: Fix for timezone issues"
# rm -f /etc/localtime
# ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime
# hwclock --systohc
# rm -f /etc/adjtime
# hwclock --systohc

echo "INFO: Current date"
date

echo "INFO: Package cleanups remove old kernels"
package-cleanup -y -C --oldkernels --count=1

echo "INFO: Remove tools used to build virtual machine drivers"
yum -y erase -C gcc libmpc mpfr cpp kernel-devel kernel-headers kernel-tools kernel-tools-libs

echo "INFO: Erase other rpms"
yum -y erase -C linux-firmware libsysfs

echo "INFO: Remove unneeded locales in /boot/grub2/locale folder except en* and es*"
find /boot/grub2/locale -mindepth 1 -maxdepth 1 ! -name 'en*' ! -name 'es*' | xargs -r rm -r

echo "INFO: Remove unneeded locales in /usr/share/locale folder except en_US, es_ES and locale.alias"
find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en_US' ! -name 'es_ES' ! -name 'locale.alias' | xargs -r rm -r

echo "INFO: Remove unneeded i18n locales in /usr/share/i18n/locales folder except en_US* and es_ES*"
find /usr/share/i18n/locales -mindepth 1 -maxdepth 1 ! -name 'en_US*' ! -name 'es_ES*' | xargs -r rm -r

echo "INFO: Remove default locales in /usr/lib/locale/locale-archive except en_US and es_ES"
localedef --list-archive | { egrep -ve '[e]n_US|[e]s_ES' || true; } | xargs -r sudo localedef --delete-from-archive
cp -f /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
build-locale-archive

echo "INFO: Clean yum and rpm caches"
yum clean all
rm -rf /var/lib/yum/yumdb
rm -rf /var/lib/yum/history
rm -rf /var/cache/yum
rpm --rebuilddb
rm -f /var/lib/rpm/__db*

echo "INFO: Install serverstatus.sh file to /usr/local/bin/serverstatus.sh"
mv serverstatus.sh /usr/local/bin
chown root.root /usr/local/bin/serverstatus.sh
chmod +x /usr/local/bin/serverstatus.sh

echo "INFO: Install control-cloud-init.sh file to /usr/local/bin/control-cloud-init.sh"
mv control-cloud-init.sh /usr/local/bin
chown root.root /usr/local/bin/control-cloud-init.sh
chmod +x /usr/local/bin/control-cloud-init.sh

echo "INFO: Install Systemd Unit /etc/systemd/system/control-cloud-init.service"
mv control-cloud-init.service /etc/systemd/system/control-cloud-init.service
chown root.root /etc/systemd/system/control-cloud-init.service
chmod 644 /etc/systemd/system/control-cloud-init.service

echo "INFO: Install guest-vmtools.sh file to /usr/local/bin/guest-vmtools.sh"
mv guest-vmtools.sh /usr/local/bin
chown root.root /usr/local/bin/guest-vmtools.sh
chmod +x /usr/local/bin/guest-vmtools.sh

echo "INFO: Install Systemd Unit /etc/systemd/system/guest-vmtools.service"
mv guest-vmtools.service /etc/systemd/system/guest-vmtools.service
chown root.root /etc/systemd/system/guest-vmtools.service
chmod 644 /etc/systemd/system/guest-vmtools.service

echo "INFO: Reload Systemd"
systemctl daemon-reload

echo "INFO: Enable at boot control-cloud-init.service"
systemctl enable control-cloud-init.service

echo "INFO: Enable at boot guest-vmtools.service"
systemctl enable guest-vmtools.service

echo "INFO: Delete /etc/cloud/cloud-init.disabled"
rm -f /etc/cloud/cloud-init.disabled

echo "INFO: Clear out machine id"
/bin/cat /dev/null > /etc/machine-id

echo "INFO: Delete packer user"
cd /tmp
userdel -f -r packer

echo "INFO: Create the admin user ${so_adminuser}"
adduser -m -U -d /home/${so_adminuser} -c "${so_adminuser}" -G wheel,adm,systemd-journal -s /bin/bash ${so_adminuser}
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
userdel -r cloud-user
rm -f /etc/sudoers.d/90-cloud-init-users /etc/group- /etc/gshadow- /etc/passwd- /etc/shadow-
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

echo "INFO: Force logs to rotate"
/usr/sbin/logrotate -f /etc/logrotate.conf
sleep 2
sync
sleep 2

echo "INFO: Clean logs and temporary files"
rm -rf /var/log/audit/*.log
rm -rf /tmp/* /var/tmp/*
rm -rf /root/*.log
rm -rf /root/*.cfg
find /var/log -name "*.log" -exec rm -f {} \;
find /var/log -name "*-????????" -exec rm -f {} \;
find /var/log -name "*.gz" -exec rm -f {} \;
rm -f /var/log/messages*
rm -f /var/log/dmesg /var/log/dmesg.old
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
rm -f /var/log/cloud-init*.log
rm -f /var/log/anaconda/syslog
rm -f /var/log/grubby*

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
sync

# echo "INFO: ONLY for test file and RPM sizes"
# rpm -qa --qf '%{archivesize} %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -rg > /root/rpmsizes.txt
# find / -type f -print0 | xargs -0 du -h | sort -rh > /root/filesizes.txt

echo "INFO: Clean logs and temporary files"
rm -rf /var/log/audit/*.log
rm -rf /tmp/* /var/tmp/*
rm -rf /root/*.log
rm -rf /root/*.cfg
find /var/log -name "*.log" -exec rm -f {} \;
find /var/log -name "*-????????" -exec rm -f {} \;
find /var/log -name "*.gz" -exec rm -f {} \;
rm -f /var/log/messages*
rm -f /var/log/dmesg /var/log/dmesg.old
/bin/cat /dev/null > /var/log/wtmp
/bin/cat /dev/null > /var/log/lastlog
rm -f /var/log/cloud-init*.log
rm -f /var/log/anaconda/syslog
rm -f /var/log/grubby*

echo "INFO: Clean bash history"
rm -f /root/.bash_history
unset HISTFILE
rm -f /home/${so_adminuser}/.bash_history
cat /dev/null > /home/${so_adminuser}/.bash_history
chown ${so_adminuser}.${so_adminuser} /home/${so_adminuser}/.bash_history
cat /dev/null > /root/.bash_history
history -c
sync

