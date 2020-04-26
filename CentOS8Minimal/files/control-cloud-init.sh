#!/usr/bin/env bash

if virt-what | grep -qs '^virtualbox$'
then
  sudo rm -rf /var/log/cloud-init*.log
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  for cloudunit in $(sudo systemctl list-unit-files | grep -s ^cloud- | cut -f1 -d' ')
  do
    sudo systemctl stop ${cloudunit}
    sudo systemctl disable ${cloudunit}
    sudo systemctl mask ${cloudunit}
  done
elif virt-what | grep -qs '^vmware$'
then
  sudo rm -rf /var/log/cloud-init*.log
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  for cloudunit in $(sudo systemctl list-unit-files | grep -s ^cloud- | cut -f1 -d' ')
  do
    sudo systemctl stop ${cloudunit}
    sudo systemctl disable ${cloudunit}
    sudo systemctl mask ${cloudunit}
  done
elif virt-what | grep -qs '^kvm$'
then
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled && sudo rm -f /etc/cloud/cloud-init.disabled || true
  for cloudunit in $(sudo systemctl list-unit-files | grep -s ^cloud- | cut -f1 -d' ')
  do
    sudo systemctl unmask ${cloudunit}
    sudo systemctl enable ${cloudunit}
  done
elif virt-what | grep -qs '^aws$'
then
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled && sudo rm -f /etc/cloud/cloud-init.disabled || true
  for cloudunit in $(sudo systemctl list-unit-files | grep -s ^cloud- | cut -f1 -d' ')
  do
    sudo systemctl unmask ${cloudunit}
    sudo systemctl enable ${cloudunit}
  done
else
  sudo rm -rf /var/log/cloud-init*.log
  sudo mkdir -p /etc/cloud
  sudo test -f /etc/cloud/cloud-init.disabled || sudo touch /etc/cloud/cloud-init.disabled
  for cloudunit in $(sudo systemctl list-unit-files | grep -s ^cloud- | cut -f1 -d' ')
  do
    sudo systemctl stop ${cloudunit}
    sudo systemctl disable ${cloudunit}
    sudo systemctl mask ${cloudunit}
  done
fi

