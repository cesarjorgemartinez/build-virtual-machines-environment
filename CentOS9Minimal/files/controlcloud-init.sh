#!/usr/bin/env bash

if virt-what | grep -qs '^virtualbox$'
then
  echo "INFO: Virtual environment VirtualBox"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo rm -rf /var/log/cloud-init*.log
elif virt-what | grep -qs '^vmware$'
then
  echo "INFO: Virtual environment VMware"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo rm -rf /var/log/cloud-init*.log
  echo "INFO: Default disable Guest OS Customization with cloud-init"
  grep -qs '^disable_vmware_customization:' /etc/cloud/cloud.cfg || echo -e '\ndisable_vmware_customization: true' | sudo tee -a /etc/cloud/cloud.cfg > /dev/null
  sudo sed -r -i -e 's/^(disable_vmware_customization:).*/\1 true/g' /etc/cloud/cloud.cfg
elif virt-what | grep -qs '^kvm$'
then
  echo "INFO: Virtual environment KVM"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled && sudo rm -f /etc/cloud/cloud-init.disabled || true
elif virt-what | grep -qs '^aws$'
then
  echo "INFO: Virtual environment AWS"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled && sudo rm -f /etc/cloud/cloud-init.disabled || true
else
  echo "INFO: Virtual environment unknown"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo rm -rf /var/log/cloud-init*.log
fi

