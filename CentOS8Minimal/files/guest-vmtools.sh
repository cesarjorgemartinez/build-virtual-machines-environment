#!/usr/bin/env bash

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

echo "INFO: Detects if we are inside a virtual machine"
MACHINETYPE="$(sudo virt-what)"
if [ "$(echo "${MACHINETYPE}")" == "" ]
then
  echo "INFO: It is real hardware"
else
  echo "INFO: It is a virtual machine"
  if [ "$(echo "${MACHINETYPE}" | grep '^virtualbox$')" != "" ]
  then
    echo "INFO: It is a VBOX virtual machine"
    echo "INFO: If exist the file /opt/reinstallGuestAdditions.action then force to reinstall the GuestAdditions"
    echo "INFO: Erase VMware packages"
    [[ "${SO_ID}" == "centos" ]] && sudo ${PKG_MANAGER} -y erase -C -q open-vm-tools open-vm-tools-desktop
    [[ "${SO_ID}" == "ubuntu" ]] && sudo apt-get -y purge -qq open-vm-tools open-vm-tools-desktop
    echo "INFO: Get SMBIOS OEM Strings type 11 to find VBOX version of host"
    VBOXHOSTVERSION="$(LANG=C sudo dmidecode -q --type 11 2>&1 | sed -r -n -e 's/^.*vboxVer_(.+)$/\1/p')"
    echo "INFO: Get the VBOX guest version of guest if it is installed"
    VBOXGUESTVERSION="$(sudo VBoxControl --nologo guestproperty get '/VirtualBox/GuestAdd/VersionExt' 2>/dev/null | cut -d ' ' -f2 || true)"
    echo "INFO: VBOX host version <${VBOXHOSTVERSION}> VBOX guest version <${VBOXGUESTVERSION}>"
    # If differ  or exists the file /opt/reinstallGuestAdditions.action then install new guest version
    if [[ "${VBOXHOSTVERSION}" != "${VBOXGUESTVERSION}" || -f /opt/reinstallGuestAdditions.action ]]
    then
      echo "INFO: Install or update GuestAdditions"
      set +e
      sudo rm -rf /var/log/vboxadd*.log*
      if [ "${SO_ID}" == "centos" ]
      then
        # Although disabling selinux is done in a previous step, it is reapplied in case some previous tasks enables it
        sudo /sbin/setenforce 0 || true
        sudo sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
        sudo ${PKG_MANAGER} -y install -q bzip2 gcc make perl kernel-devel dkms
        export KERN_DIR=/usr/src/kernels/$(uname -r)
      elif [ "${SO_ID}" == "ubuntu" ]
      then
        sudo apt-get -y install -qq bzip2 gcc make perl dkms linux-headers-$(uname -r)
      else
        echo "ERROR: Operating System type not supported"
        exit 1
      fi
      sudo curl -s -S --fail --retry 3 --retry-delay 60 http://download.virtualbox.org/virtualbox/${VBOXHOSTVERSION}/VBoxGuestAdditions_${VBOXHOSTVERSION}.iso -o /opt/VBoxGuestAdditions_${VBOXHOSTVERSION}.iso
      sudo mkdir -p /mnt/VBoxGuestAdditionsISO
      sudo mountpoint -q /mnt/VBoxGuestAdditionsISO || sudo mount -o loop,ro /opt/VBoxGuestAdditions_${VBOXHOSTVERSION}.iso /mnt/VBoxGuestAdditionsISO || true
      sudo /mnt/VBoxGuestAdditionsISO/VBoxLinuxAdditions.run || true 2>&1
      sudo umount /mnt/VBoxGuestAdditionsISO
      sudo rm -rf /mnt/VBoxGuestAdditionsISO
      sudo rm -f /opt/reinstallGuestAdditions.action
      set -e
    else
      echo "INFO: VBOX GuestAdditions already updated"
    fi
  elif [ "$(echo "${MACHINETYPE}" | grep '^vmware$')" != "" ]
  then
    echo "INFO: It is a VMware virtual machine"
    echo "INFO: Erase VBOX GuestAdditions"
    sudo /opt/VBoxGuestAdditions-*/uninstall.sh 2>/dev/null || true
    sudo rm -rf /opt/VBoxGuestAdditions* /var/log/vboxadd*.log*
    echo "INFO: Install VMware packages"
    [[ "${SO_ID}" == "centos" ]] && sudo ${PKG_MANAGER} -y install -q open-vm-tools open-vm-tools-desktop
    [[ "${SO_ID}" == "ubuntu" ]] && sudo apt-get -y install -qq open-vm-tools open-vm-tools-desktop
    sudo systemctl restart vmtoolsd.service
  elif [ "$(echo "${MACHINETYPE}" | grep '^kvm$')" != "" ]
  then
    echo "INFO: It is a kvm virtual machine"
    echo "INFO: Erase VBOX GuestAdditions"
    sudo /opt/VBoxGuestAdditions-*/uninstall.sh 2>/dev/null || true
    sudo rm -rf /opt/VBoxGuestAdditions* /var/log/vboxadd*.log*
    echo "INFO: Erase VMware packages"
    [[ "${SO_ID}" == "centos" ]] && sudo ${PKG_MANAGER} -y erase -C -q open-vm-tools open-vm-tools-desktop
    [[ "${SO_ID}" == "ubuntu" ]] && sudo apt-get -y purge -qq open-vm-tools open-vm-tools-desktop
  else
    echo "INFO: The virtual machine is not supported"
  fi
fi

