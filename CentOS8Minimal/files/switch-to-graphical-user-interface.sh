#!/usr/bin/env bash

echo "INFO: Switch Text User Interface to Graphical User Interface"

echo "INFO: Install the Server with GUI (GNOME Display Manager) group. It takes a bit of time..."
sudo dnf group install -q -y "Server with GUI"

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

MACHINETYPE="$(sudo virt-what)"
if [ "$(echo "${MACHINETYPE}" | grep '^virtualbox$')" != "" ]
then
  echo "INFO: Detected VM of type VirtualBox. Reinstalling the Guest Additions"
  sudo touch /opt/reinstallGuestAdditions.action
  sudo /usr/local/bin/guest-vmtools.sh
fi

echo "INFO: You need to reboot your O.S. to apply the changes correctly"
echo "sudo shutdown -r now"

