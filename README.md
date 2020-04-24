<h1><center><b>Automate Virtual Machine Linux Images</b></center></h1>
<br>

**Author: Cesar Jorge Martínez**
<br>

**Site: <https://cesarjorgemartinez.github.io/automate-virtual-machine-linux-images>**
<br>

**Read the LICENSE [GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007](LICENSE "GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007")**
<br>

<h2>Index</h2>
<!-- MDTOC maxdepth:6 firsth1:1 numbering:0 flatten:0 bullets:1 updateOnSave:0 -->

- [1. Introduction](#1-introduction)
- [2. Operating Systems that can be built](#2-operating-systems-that-can-be-built)
- [3. Create and configure the environment](#3-create-and-configure-the-environment)
   - [3.1. Install VirtualBox](#31-install-virtualbox)
   - [3.2. Install VMware Workstation Player](#32-install-vmware-workstation-player)
   - [3.3. Install CygWin 64 bits](#33-install-cygwin-64-bits)
   - [3.4. Disable Windows Python installation](#34-disable-windows-python-installation)
   - [3.5. Install needed CygWin packages](#35-install-needed-cygwin-packages)
   - [3.6. Install Python system pip packages](#36-install-python-system-pip-packages)
   - [3.7. Configure your Git environment to work with github](#37-configure-your-git-environment-to-work-with-github)
- [4. Getting started](#4-getting-started)
   - [4.1. Clone and enter into the git root directory of this repository](#41-clone-and-enter-into-the-git-root-directory-of-this-repository)
   - [4.2. Install QEMU for Windows](#42-install-qemu-for-windows)
- [5. Build CentOS 7 Minimal image](#5-build-centos-7-minimal-image)
   - [5.1. Download and install Packer](#51-download-and-install-packer)
   - [5.2. Download the iso image](#52-download-the-iso-image)
   - [5.3. Build the image](#53-build-the-image)
   - [5.4. Optionally upload to the OpenStack Image Store](#54-optionally-upload-to-the-openstack-image-store)
   - [5.5. Utility files used in this image](#55-utility-files-used-in-this-image)
   - [5.6. Virtual machine example in VirtualBox](#56-virtual-machine-example-in-virtualbox)
      - [5.6.1. Import the virtualized service](#561-import-the-virtualized-service)
      - [5.6.2. Configure the virtual machine](#562-configure-the-virtual-machine)
      - [5.6.3. Use the virtual machine](#563-use-the-virtual-machine)
   - [5.7. Convert vmdk image to work inside VMware ESXI](#57-convert-vmdk-image-to-work-inside-vmware-esxi)

<!-- /MDTOC -->


# 1. Introduction

This project helps to build automatically multiple *Virtual Machine Images of Operating Systems* that are **compatible** with different virtualization systems, as *OpenStack* (*kvm*), *VirtualBox*, *VMware*, *VMware ESXI*, *Nutanix*, etc.

The image formats that are generated are the following:
- **vmdk:** For *VirtualBox*, *VMware* and *VMware ESXI*.
- **ovf:** For *VirtualBox*, *VMware* and *VMware ESXI*.
- **qcow2:** For *OpenStack* (*kvm*) and *Nutanix*.

The virtualization system *VirtualBox* also uses the **vdi** format. but it is not necessary since the *VirtualBox* itself converts the **vmdk** format into **vdi**.

You can deploy and boot directly these images in these virtualization systems without doing anything special or extra, thanks to the use of two *systemd* units:

- **control-cloud-init.service**: By default the cloud-init units are enabled. But if the virtual machine boots in a virtualization system that is not *OpenStack*, then disable the cloud-init units.
- **guest-vmtools.service**: If the virtual machine boots inside *VirtualBox* then install its *GuestTools* disabling others. If the virtual machine boots inside *VMware* or *VMware ESXI* then install its *VMwareTools* disabling others.

These images are ideal to work as servers in *Cloud*, *traditional* or *development* environments, and is very useful to work with **Docker**, because the size of the image created is very small and clean. These images are builded with a *Linux* admin account provided as parameter at the time of build. The `cloud-init` software use other account provided as optional parameter at the time of build (not created because the `cloud-init` do this work at the first boot of the virtual machine) that by default is *cloud-user*.

To work with this software you need **Windows 10 for 64 bits** and **CygWin 64 bits** to use **Linux-Bash** commands.


# 2. Operating Systems that can be built

Actually you can build the following Operating Systems:

- **CentOS 7 Minimal**
- **CentOS 8 Minimal**


# 3. Create and configure the environment

You need to do the next tasks.


## 3.1. Install VirtualBox

Go to this URL <https://www.virtualbox.org/wiki/Downloads> and install latest *VirtualBox* for Windows. You need to ensure that in addition to installing *VirtualBox* you also install *Oracle VM VirtualBox Extension Pack*.


## 3.2. Install VMware Workstation Player

Go to this URL <https://www.vmware.com/go/downloadworkstationplayer> and install latest *VMware Workstation Player* for Windows.

This is optional step only if you will be use *VMware* or *VMware ESXI*.


## 3.3. Install CygWin 64 bits

To install **CygWin 64 bits** you need to do the following tasks:

- With a browser download <https://cygwin.com/setup-x86_64.exe>.
- Install this doing right button of the mouse over this downloaded file, and `Run as admistrator`.
- Following.
- Install from Internet.
- Following.
- Local Package Directory: `C:\cygwin64\mypackages`.
- Use System Proxy Settings.
- Choose A Download Site, choose one and:
- Following.
- Use default packages (Don't select others).
- Following.
- Following.
- Finalize.

When terminate these tasks, then:

- In `Cygwin64 Terminal Desktop Icon` click on right button of the mouse and select `properties`.
- Click in `Advanced options`.
- Set `Run as administrator` and click `Accept` and `Accept`.


## 3.4. Disable Windows Python installation

To prevent that *CygWin* use the *Python* installed in *Windows* (if exist), do the following to disable access to *Windows Python installation*:

- Enter in a *Cygwin64 session*.
- Launch this:
```bash
echo $'PATH=$(echo $PATH | tr \':\' \'\\n\' | grep -v "/cygdrive/.*/Python[23]7" | paste -sd:)' >> .bash_profile
exit
```


## 3.5. Install needed CygWin packages

You need to do the following tasks:

- Enter in a *Cygwin64 session*.
- Launch this:
```bash
curl -O https://cygwin.com/setup-x86_64.exe
./setup-x86_64.exe -q --packages="bash,python,python-devel,python-setuptools,python-crypto,python-paramiko,python2-boto,python2-certifi,python2-pip,openssl,openssh,openssl-devel,libffi-devel,gcc-g++,git,nc,nc6,python2-nacl,libsodium-common,libsodium-devel,dialog,figlet,rsync,gettext,autoconf,automake,binutils,cygport,gcc-core,make,lynx,zip,sshpass"
```


## 3.6. Install Python system pip packages

To work with *Python* install basic *pip* packages in a system level:

- Enter in a *Cygwin64 session*.
- Launch this:
```bash
easy_install-2.7 pip
pip install --upgrade pip
pip install --upgrade setuptools
pip install --upgrade wheel
pip install --upgrade virtualenv
pip install --upgrade terrafile
```


## 3.7. Configure your Git environment to work with github

To work with <https://github.com> you need to do the next tasks. Example to use *Git* with *SSH*.

- Get your public and private *SSH keys* of your *GitHub account*.

- Enter in a *Cygwin64 session*.

```bash
mkdir -p ~/.ssh
echo "StrictHostKeyChecking no
UserKnownHostsFile /dev/null
ServerAliveInterval 30
ServerAliveCountMax 3
ControlMaster no

Host github.com
  IdentityFile ~/.ssh/id_rsa_private_github
" > ~/.ssh/config
```

- Store your public key to `~/.ssh/id_rsa_private_github.pub` and your private key to `~/.ssh/id_rsa_private_github`.

- Set good permissions in the *SSH* config folder.

```bash
chmod 600 ~/.ssh/*
chmod 700 ~/.ssh
```

- Configure your Git client settings. You need the `user.name` and `user.email` of your *GitHub account*. Enter in a *Cygwin64 session*.

```bash
git config --system color.ui "true"
git config --system alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --system user.name "<your user.name>"
git config --system user.email "<your user.email>"
git config --system http.sslVerify false
```


# 4. Getting started

After you have completed the previous sections, follow the next steps.


## 4.1. Clone and enter into the git root directory of this repository

Do the following tasks:

```bash
git clone git@github.com:cesarjorgemartinez/automate-virtual-machine-linux-images.git
cd automate-virtual-machine-linux-images
```


## 4.2. Install QEMU for Windows

The *QEMU for Windows* is needed to convert the **vmdk** to **qcow2** image format. Launch this command:

```bash
download-and-install-qemu.sh
```

Then a *QEMU for Windows* installer window appears and do the following:
- Please select a language: Select your language, as example `English / English`
- Click in OK
- Next
- I Agree
- Next
- Install
- Finish


# 5. Build CentOS 7 Minimal image

This section explains howto build this *Virtual Machine Image*.


## 5.1. Download and install Packer

To build the image you need to download and install *Packer* software.

The directory where it install this software is `CentOS7Minimal/packer-software`.

The version is determined by its own configuration file located at [CentOS7Minimal Configuration Directory](CentOS7Minimal/conf/virtual-machine.conf "CentOS7Minimal Configuration Directory").

To perform this task run:

```bash
CentOS7Minimal/bin/download-and-install-packer.sh
```


## 5.2. Download the iso image

To build the image you need to download the **iso** files for this *Operating System*.

The directory where it download this **iso** files is `isos` at home of this repository.

The version is determined by its own configuration file located at [CentOS7Minimal Configuration Directory](CentOS7Minimal/conf/virtual-machine.conf "CentOS7Minimal Configuration Directory").

To perform this task run:

```bash
CentOS7Minimal/bin/download-iso.sh
```


## 5.3. Build the image

You need enter the `username` and `userpass` of the *Linux* admin account what is desired, and one optional parameter for the `cloud-init` default user (if this parameter is not provided then the default user is `cloud-user`.

```bash
CentOS7Minimal/bin/build-virtual-machine.sh --adminuser adminuser --adminpass adminpass [--defaultclouduser defaultclouduser]
```

When finished the build then will create the image files **vmdk**, **ovf** and **qcow2** inside the `images` directory at home of this repository.

To understand how the builder works see the configuration files in [CentOS7Minimal Configuration Directory](CentOS7Minimal/conf/virtual-machine.conf "CentOS7Minimal Configuration Directory").

The format name of the generated image files is as follows:

```bash
${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}.(vmdk|ovf|qcow2)
```

Example of **CentOS 7 Minimal** configuration file:

```bash
# Variables to build Operating System
export PACKER_VERSION="1.4.5"
export PACKER_MACHINEREADABLEOUTPUT="False"
export PACKER_DEBUG="False"
export PACKER_SSH_TIMEOUT="50m"
# The location of the core configuration file
export PACKER_CONFIG="${HOME_BASEDIR}/.packerconfig"
# The location of the .packer.d config directory
export PACKER_CONFIG_DIR="${HOME_BASEDIR}"
export VBOXPATH="/cygdrive/c/Program Files/Oracle/VirtualBox"
export QEMUPATH="/cygdrive/c/Program Files/qemu"
export PATH="${VBOXPATH}:${QEMUPATH}:${PATH}"
export SO_GUESTOSTYPE="RedHat_64"
# Values for hard_drive_interface are: ide sata or scsi
export SO_GUESTHDDINTERFACE="sata"
# The image obtained can be Minimal (for servers) or Desktop (for final users using a GUI)
export SO_IMAGETYPE="Minimal"
export SO_DISTRIBUTION="CentOS"
export SO_MAJORVERSION="7"
export SO_MINORVERSION="7"
export SO_NAMEVERSION="1908"
export SO_SHORTVERSION="${SO_MAJORVERSION}.${SO_MINORVERSION}"
export SO_FULLVERSION="${SO_SHORTVERSION}-${SO_NAMEVERSION}"
# The iso file type to download and use can be Minimal or DVD (can exists others but here only use these types)
export SO_ISOTYPE="Minimal"
export SO_ISOIMAGENAME="${SO_DISTRIBUTION}-${SO_MAJORVERSION}-x86_64-${SO_ISOTYPE}-${SO_NAMEVERSION}.iso"
export SO_ISOURLIMAGE="http://ftp.uma.es/mirror/${SO_DISTRIBUTION}/${SO_MAJORVERSION}/isos/x86_64/${SO_ISOIMAGENAME}"
export SO_ISOSHA256SUMNAME="${SO_ISOIMAGENAME%.iso}.sum"
export SO_ISOCHECKSUMTYPE="sha256"
export SO_ISOURLSHA256SUM="http://ftp.uma.es/mirror/${SO_DISTRIBUTION}/${SO_MAJORVERSION}/isos/x86_64/sha256sum.txt"
export SO_BUILDDATE="$(date +%Y%m%d)"
export SO_VMFULLNAME="${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}"
```


## 5.4. Optionally upload to the OpenStack Image Store

If you have one *OpenStack virtualization environment*, you can upload the **qcow2** image file to the *OpenStack Image Store*.

To do the upload you need one appropiated virtualenv and environment variables defined and be registered in that *OpenStack virtualization environment* and launch:

```bash
CentOS7Minimal/bin/uploadqcow2toopenstack.sh
```


## 5.5. Utility files used in this image

When build this image the following files in [Files for CentOS7Minimal Directory](CentOS7Minimal/files "Files for CentOS7Minimal Directory") folder are installed and configured.

* **control-cloud-init.service**: Unit to control `cloud-init` to enable in *OpenStack* and disable in other virtualization systems. This unit calls the file `/usr/local/bin/control-cloud-init.sh`. Installed in `/etc/systemd/system/control-cloud-init.service`. See [control-cloud-init.service](CentOS7Minimal/files/control-cloud-init.service "control-cloud-init.service").

* **control-cloud-init.sh**: Process that controls `cloud-init` to enable in *OpenStack* and disable in other virtualization systems. Installed in `/usr/local/bin/control-cloud-init.sh`. See [control-cloud-init.sh](CentOS7Minimal/files/control-cloud-init.sh "control-cloud-init.sh").

* **guest-vmtools.service**: Unit to manage virtual machine tools for *VirtualBox*, *VMware* or *VMware ESXI*. This unit calls the file `/usr/local/bin/guest-vmtools.sh`. Installed in `/etc/systemd/system/guest-vmtools.service`. See [guest-vmtools.service](CentOS7Minimal/files/guest-vmtools.service "guest-vmtools.service").

* **guest-vmtools.sh**: Process that install and configure the *GuestTools* for *VirtualBox* or *VMwareTools* for *VMware* or *VMware ESXI*. Or remove these tools if boot in other virtual environments. Installed in `/usr/local/bin/guest-vmtools.sh`. See [guest-vmtools.sh](CentOS7Minimal/files/guest-vmtools.sh "guest-vmtools.sh").

* **host-info.sh**: Process that informs over basic properties of a host (CPU, memory, etc). Installed in `/usr/local/bin/host-info.sh`. See [host-info.sh](CentOS7Minimal/files/host-info.sh "host-info.sh").

  Execution example:
  ```bash
  ===========================================================================
  HOSTNAME...........: myvm
  INTERFACES.........:
  Interface         MAC Address       IP4 Address                                   IP6 Address
  eth0              08:00:27:34:1c:b6 192.168.56.115/24                             fe80::a00:27ff:fe34:1cb6/64
  eth1              08:00:27:c1:06:ba 10.0.3.15/24                                  fe80::a00:27ff:fec1:6ba/64
  CPU CORES..........: 1
  MEMORY.............:
                total        used        free      shared  buff/cache   available
  Mem:           991M        116M        186M         12M        688M        701M
  Swap:          1.0G          0B        1.0G
  FILESYSTEMS........:
  Filesystem                      Size  Used Avail Use% Mounted on
  devtmpfs                        485M     0  485M   0% /dev
  tmpfs                           496M     0  496M   0% /dev/shm
  tmpfs                           496M   13M  483M   3% /run
  tmpfs                           496M     0  496M   0% /sys/fs/cgroup
  /dev/mapper/centos_centos-root   18G  906M   18G   5% /
  /dev/sda1                      1014M   68M  947M   7% /boot
  tmpfs                           100M     0  100M   0% /run/user/1000
  SYSTEM UPTIME......: 13:26:36 up 16 min, 1 user, load average: 0.00, 0.08, 0.21
  RELEASE............: CentOS Linux release 7.7.1908 (Core)
  KERNEL.............: 3.10.0-1062.4.1.el7.x86_64
  DATE...............: Thu Nov  7 13:26:36 CET 2019
  USERS..............: Currently 1 user(s) logged on
  CURRENT USER.......: adminuser
  PROCESSES..........: 154 running
  ===========================================================================
  ```

* **switch-to-graphical-user-interface.sh**: Process that install and enable the `GNOME Display Manager` and set `Graphical Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-graphical-user-interface.sh`. See [switch-to-graphical-user-interface.sh](CentOS7Minimal/files/switch-to-graphical-user-interface.sh "switch-to-graphical-user-interface.sh").


* **switch-to-text-user-interface.sh**: Process that disables (not uninstall) the `GNOME Display Manager` and set `Text Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-text-user-interface.sh`. See [switch-to-text-user-interface.sh](CentOS7Minimal/files/switch-to-text-user-interface.sh "switch-to-text-user-interface.sh").


## 5.6. Virtual machine example in VirtualBox

Steps to use virtual machines using *VirtualBox*.


### 5.6.1. Import the virtualized service

To import virtualized service in *VirtualBox* to create a virtual machine perform the following steps using the `Oracle VM VirtualBox Administrator`.

- Click in `Archive -> Import virtualized service...`
- Click in `Select a virtualized service file to import...` in `Service to import`. Example `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115.ovf`
- Name: `myvm`
- Type of guest OS: `Red Hat (64-bit)`
- CPU: `1`
- RAM: `1024 MB`
- Storage Controller (SATA) -> Virtual Disk Image: `myvm.vmdk`
- MAC address policy: `Generate new MAC addresses for all network adapters`
- Additional options: `Import disks as VDI`
- Click in `Import` button


### 5.6.2. Configure the virtual machine

The virtual machine is created and the next steps are to configure it correcty doing double-click in this virtual machine and select `Configuration...` or using the menu `Machine -> Configuration...`.

- General -> Advanced -> Share clipboard: `Bidirectional`
- General -> Advanced -> Drag and drop: `Bidirectional`
- System -> Motherboard -> UTC time hardware clock: `Enabled`
- Screen -> Screen -> Video memory: `16 MB`
- Display -> Display -> Graphic controller: `VMSVGA`
- Network -> Network -> Adapter 1 -> Enable network adapter: `Enabled`
- Network -> Network -> Adapter 1 -> Connected to: `Host-only adapter`
- Network -> Network -> Adapter 1 -> Name: `VirtualBox Host-Only Ethernet Adapter`
- Network -> Network -> Adapter 1 -> Advanced -> Promiscuous mode: `Allow all`
- Network -> Network -> Adapter 2 -> Enable network adapter: `Enabled`
- Network -> Network -> Adapter 2 -> Connected to: `NAT`


### 5.6.3. Use the virtual machine

Once the virtual machine is configured you can click in `Start` button.

To get guest properties of the virtual machine:

- Enter in a *Cygwin64 session*.
- To get all guest properties.
```bash
'/cygdrive/c/Program Files/Oracle/VirtualBox/VBoxManage' guestproperty enumerate myvm
```
- To get the assigned IP for adapter 1.
```bash
'/cygdrive/c/Program Files/Oracle/VirtualBox/VBoxManage' guestproperty get myvm /VirtualBox/GuestInfo/Net/0/V4/IP
```

Launch a ssh session to this virtual machine:

```bash
sshpass -p adminpass ssh adminuser@<assigned_IP_for_adapter_1>
```

Change the `hostname` for this virtual machine:

```bash
sudo hostnamectl --static set-hostname myvm
sudo hostnamectl --transient set-hostname myvm
```

Get basic properties of this virtual machine:

```bash
/usr/local/bin/host-info.sh
```

Switch to `Graphical User Interface` for this virtual machine:

```bash
sudo /usr/local/bin/switch-to-graphical-user-interface.sh
# Wait a bit to terminate this execution
sudo reboot
```

Or back to `Text User Interface` for this virtual machine:

```bash
sudo /usr/local/bin/switch-to-text-user-interface.sh
# Wait a bit to terminate this execution
sudo reboot
```


## 5.7. Convert vmdk image to work inside VMware ESXI

The image formats obtained **vmdk** or **ovf** are compatible with *VMware Workstation Player* but they are not compatible for *VMware ESXI*.

For this reason you need to use *VMware Workstation Player* for Windows to obtain a compatible virtual machine.

Then follow these steps:

- Open *VMware Workstation Player*
- Click in `Player->File->Open...` and select the **ovf** file `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115.ovf`
- Name for the new virtual machine: `CentOS7.7-1908-Minimal-20191115`
- Storage path for the new virtual machine: `C:\VMware\CentOS7.7-1908-Minimal-20191115`
- Click in `Import` button
- Click in `Retry` button to relax OVF specifications
- Click in `Edit virtual machine settings`
- Options -> General -> Guest Operation System: `Linux`
- Options -> General -> Guest Operation System -> Version: `Centos 7 64-bit`
- Options -> VMware Tools -> VMware Tools features -> Syncronize guest time with host: `Enabled`
- Hardware->Network Adapter -> Network connection -> Bridged: Connected directly to the physical network: `Enabled`
- Hardware->Network Adapter -> Network connection -> Replicate physical network connection state: `Disabled`
- Hardware->Network Adapter -> Network connection -> Configure Adapters -> Realtek PCIe GBE Family Controller: `Enabled`
- Hardware->Network Adapter -> Network connection -> Configure Adapters -> Other adapters: `Disabled`

Then you have an image imported into *VMware Workstation Player*. Here you need to choose the *VMware ESXI* version reading the article <https://kb.vmware.com/s/article/1003746> and follow these steps:

- Enter in a *Cygwin64 session*.

- To get an image for *VMware ESXI* version `6.0` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=11 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.7-1908-Minimal-20191115\CentOS7.7-1908-Minimal-20191115.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115-esx11.ovf'
```

- To get an image for *VMware ESXI* version `6.5` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=13 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.7-1908-Minimal-20191115\CentOS7.7-1908-Minimal-20191115.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115-esx13.ovf'
```

- To get an image for *VMware ESXI* version `6.7` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=14 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.7-1908-Minimal-20191115\CentOS7.7-1908-Minimal-20191115.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115-esx14.ovf'
```

- To get an image for *VMware ESXI* version `6.7 U2` or `6.8.x` or `6.9.x` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=15 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.7-1908-Minimal-20191115\CentOS7.7-1908-Minimal-20191115.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115-esx15.ovf'
```
