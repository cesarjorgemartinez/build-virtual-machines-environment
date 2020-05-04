#!/usr/bin/env bash

if virt-what | grep -qs '^virtualbox$'
then
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo rm -rf /var/log/cloud-init*.log
elif virt-what | grep -qs '^vmware$'
then
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo rm -rf /var/log/cloud-init*.log
elif virt-what | grep -qs '^kvm$'
then
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled && sudo rm -f /etc/cloud/cloud-init.disabled || true
elif virt-what | grep -qs '^aws$'
then
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled && sudo rm -f /etc/cloud/cloud-init.disabled || true
else
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  sudo rm -rf /var/log/cloud-init*.log
fi

