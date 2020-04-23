#!/usr/bin/env bash

echo "INFO: Switch Graphical User Interface to Text User Interface"

echo "INFO: Change the default login from Graphical to Text in systemd"
sudo systemctl set-default multi-user.target

echo "INFO: Disable GNOME service at boot time"
sudo systemctl disable gdm.service

echo "INFO: Add nomodeset option in /etc/default/grub. It is needed for use text interfaces correctly"
sudo sed -r -i -e 's/nofb\s+vga/nofb nomodeset vga/g' /etc/default/grub

echo "INFO: Save grub2 changes"
grub2-mkconfig -o /boot/grub2/grub.cfg

MACHINETYPE="$(sudo virt-what)"
if [ "$(echo "${MACHINETYPE}" | grep '^virtualbox$')" != "" ]
then
  echo "INFO: Detected VM of type VirtualBox. Reinstalling the Guest Additions"
  sudo touch /opt/reinstallGuestAdditions.action
  sudo /usr/local/bin/guest-vmtools.sh
fi

echo "INFO: You need to reboot your O.S. to apply the changes correctly"
echo "sudo shutdown -r now"

