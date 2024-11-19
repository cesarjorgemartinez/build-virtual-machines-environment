#!/usr/bin/env bash

echo "INFO: Switch Graphical User Interface to Text User Interface"

echo "INFO: Detects Operating System"
SO_ID="$(source /etc/os-release && echo "${ID}")"
SO_VERSION_ID="$(source /etc/os-release && echo "${VERSION_ID}")"
echo "INFO: SO_ID <${SO_ID}>"
echo "INFO: SO_VERSION_ID <${SO_VERSION_ID}>"

PKG_MANAGER=
if [ "${SO_ID}" == "centos" ]
then
  [[ "${SO_VERSION_ID}" == "7" ]] && PKG_MANAGER=yum
  [[ "${SO_VERSION_ID}" == "8" ]] && PKG_MANAGER=dnf
elif [ "${SO_ID}" == "ubuntu" ]
then
  export DEBIAN_FRONTEND=noninteractive
else
  echo "ERROR: Operating System type not supported"
  exit 1
fi

echo "INFO: Change the default login from Graphical to Text in systemd"
sudo systemctl set-default multi-user.target

if [ "${SO_ID}" == "centos" ]
then
  echo "INFO: Add nomodeset option in /etc/default/grub. It is needed for use text interfaces correctly"
  sudo sed -r -i -e 's/nofb\s+vga/nofb nomodeset vga/g' /etc/default/grub
  echo "INFO: Save grub2 changes"
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi

MACHINETYPE="$(sudo virt-what)"
if [ "$(echo "${MACHINETYPE}" | grep '^virtualbox$')" != "" ]
then
  echo "INFO: Detected VM of type VirtualBox. Reinstalling the Guest Additions"
  sudo touch /opt/reinstallGuestAdditions.action
  sudo /usr/local/bin/guestvmtools.sh
fi

echo "INFO: You need to reboot your O.S. to apply the changes correctly"
echo "sudo shutdown -r now"

