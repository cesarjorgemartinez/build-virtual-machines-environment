#!/usr/bin/env bash

echo "INFO: Switch Text User Interface to Graphical User Interface"

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

if [ "${SO_ID}" == "centos" ]
then
  echo "INFO: Install the Server with GUI (environment-id graphical-server-environment, using GNOME Display Manager) group. It takes a bit of time..."
  sudo ${PKG_MANAGER} group install -q -y "graphical-server-environment"
elif [ "${SO_ID}" == "ubuntu" ]
then
  echo "INFO: Install GNOME Vanilla Desktop. It takes a bit of time..."
  sudo apt-get install -y -qq gnome-session gdm3 gnome-shell-extensions gnome-terminal
else
  echo "ERROR: Operating System type not supported"
  exit 1
fi

if [ "${SO_ID}" == "centos" ]
then
  echo "INFO: Set GNOME Autostart configuration to false in /etc/xdg/autostart/gnome-initial-setup-first-login.desktop"
  sudo sed -r -i -e '/^\s*X-GNOME-Autostart-enabled\s*=/{
h
s/=.*/=false/
}
${
x
/^$/{
s//X-GNOME-Autostart-enabled=false/
H
}
x
}' /etc/xdg/autostart/gnome-initial-setup-first-login.desktop
  echo "INFO: Change the default login from Text to Graphical in systemd"
  sudo systemctl set-default graphical.target
  echo "INFO: Enable GNOME service at boot time"
  sudo systemctl enable gdm.service
  echo "INFO: Remove nomodeset option in /etc/default/grub. It is needed for use graphical interfaces correctly"
  sudo sed -r -i -e 's/nomodeset\s+//g' /etc/default/grub
  echo "INFO: Save grub2 changes"
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi

MACHINETYPE="$(sudo virt-what)"
if [ "$(echo "${MACHINETYPE}" | grep '^virtualbox$')" != "" ]
then
  echo "INFO: Detected VM of type VirtualBox. Reinstalling the Guest Additions"
  sudo touch /opt/reinstallGuestAdditions.action
  sudo /usr/local/bin/guest-vmtools.sh
fi

echo "INFO: You need to reboot your O.S. to apply the changes correctly"
echo "sudo shutdown -r now"

