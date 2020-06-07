#!/usr/bin/env bash

if virt-what | grep -qs '^virtualbox$'
then
  echo "INFO: Virtual environment VirtualBox"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo systemctl mask cloud-config.service
  sudo systemctl mask cloud-final.service
  sudo systemctl mask cloud-init-local.service
  sudo systemctl mask cloud-init.service
  sudo systemctl mask cloud-config.target
  sudo systemctl mask cloud-init.target
  sudo rm -rf /var/log/cloud-init*.log
elif virt-what | grep -qs '^vmware$'
then
  echo "INFO: Virtual environment VMware"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo systemctl mask cloud-config.service
  sudo systemctl mask cloud-final.service
  sudo systemctl mask cloud-init-local.service
  sudo systemctl mask cloud-init.service
  sudo systemctl mask cloud-config.target
  sudo systemctl mask cloud-init.target
  sudo rm -rf /var/log/cloud-init*.log
elif virt-what | grep -qs '^kvm$'
then
  echo "INFO: Virtual environment KVM"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled && sudo rm -f /etc/cloud/cloud-init.disabled || true
  sudo systemctl unmask cloud-config.service
  sudo systemctl unmask cloud-final.service
  sudo systemctl unmask cloud-init-local.service
  sudo systemctl unmask cloud-init.service
  sudo systemctl unmask cloud-config.target
  sudo systemctl unmask cloud-init.target
elif virt-what | grep -qs '^aws$'
then
  echo "INFO: Virtual environment AWS"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled && sudo rm -f /etc/cloud/cloud-init.disabled || true
  sudo systemctl unmask cloud-config.service
  sudo systemctl unmask cloud-final.service
  sudo systemctl unmask cloud-init-local.service
  sudo systemctl unmask cloud-init.service
  sudo systemctl unmask cloud-config.target
  sudo systemctl unmask cloud-init.target
else
  echo "INFO: Virtual environment unknown"
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo systemctl mask cloud-config.service
  sudo systemctl mask cloud-final.service
  sudo systemctl mask cloud-init-local.service
  sudo systemctl mask cloud-init.service
  sudo systemctl mask cloud-config.target
  sudo systemctl mask cloud-init.target
  sudo rm -rf /var/log/cloud-init*.log
fi

