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
- [6. Build CentOS 8 Minimal image](#6-build-centos-8-minimal-image)
   - [6.1. Download and install Packer](#61-download-and-install-packer)
   - [6.2. Download the iso image](#62-download-the-iso-image)
   - [6.3. Build the image](#63-build-the-image)
   - [6.4. Optionally upload to the OpenStack Image Store](#64-optionally-upload-to-the-openstack-image-store)
   - [6.5. Utility files used in this image](#65-utility-files-used-in-this-image)
   - [6.6. Virtual machine example in VirtualBox](#66-virtual-machine-example-in-virtualbox)
      - [6.6.1. Import the virtualized service](#661-import-the-virtualized-service)
      - [6.6.2. Configure the virtual machine](#662-configure-the-virtual-machine)
      - [6.6.3. Use the virtual machine](#663-use-the-virtual-machine)
   - [6.7. Convert vmdk image to work inside VMware ESXI](#67-convert-vmdk-image-to-work-inside-vmware-esxi)
- [7. Build Ubuntu 20 Minimal image](#7-build-ubuntu-20-minimal-image)
   - [7.1. Download and install Packer](#71-download-and-install-packer)
   - [7.2. Download the iso image](#72-download-the-iso-image)
   - [7.3. Build the image](#73-build-the-image)
   - [7.4. Optionally upload to the OpenStack Image Store](#74-optionally-upload-to-the-openstack-image-store)
   - [7.5. Utility files used in this image](#75-utility-files-used-in-this-image)
   - [7.7. Convert vmdk image to work inside VMware ESXI](#77-convert-vmdk-image-to-work-inside-vmware-esxi)

<!-- /MDTOC -->


# 1. Introduction

This project helps to build automatically multiple *Virtual Machine Images of Operating Systems* that are **compatible** with different virtualization systems, as *OpenStack*, *KVM*, *VirtualBox*, *VMware*, *VMware ESXI*, *Nutanix*, etc.

The image formats that are generated are the following:
- **vmdk:** For *VirtualBox*, *VMware* and *VMware ESXI*.
- **ovf:** For *VirtualBox*, *VMware* and *VMware ESXI*.
- **qcow2:** For *OpenStack*, *KVM* and *Nutanix*.

The virtualization system *VirtualBox* also uses the **vdi** format but it is not necessary since the *VirtualBox* itself converts the **vmdk** format into **vdi**.

You can deploy and boot directly these images in these virtualization systems without doing anything special or extra, thanks to the use of two *systemd* units:

- **control-cloud-init.service**: If the virtual machine boots in *OpenStack* or *KVM* or *AWS* then lets execute `cloud-init`. If the virtual machine boots in *VMware* or *VirtualBox* or other virtualization systems then mask `cloud-init`.
- **guest-vmtools.service**: If the virtual machine boots inside *VirtualBox* then install its *GuestTools* disabling others. If the virtual machine boots inside *VMware* or *VMware ESXI* then install its *VMwareTools* disabling others.

These images are ideal to work as servers in *Cloud*, *traditional* or *development* environments, and is very useful to work with **Docker**, because the size of the image created is very small and clean. These images are builded with a *Linux* admin account provided as parameter at the time of build. The `cloud-init` software use other account provided as optional parameter at the time of build (not created because the `cloud-init` do this work at the first boot of the virtual machine) that by default is *cloud-user*. Also these images come with six network intefaces named `eth0`, `eth1`, `eth2`, `eth3`, `eth4` and `eth5` by default.

To work with this software you need **Windows 10 for 64 bits** and **CygWin 64 bits** to use **Linux-Bash** commands.


# 2. Operating Systems that can be built

Actually you can build the following Operating Systems:

- **CentOS 7 Minimal**
- **CentOS 8 Minimal**
- **Ubuntu 20 Minimal**


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
# For Packer version you can use one release or nightly to use nightly build
export PACKER_VERSION="1.5.6"
export PACKER_MACHINEREADABLEOUTPUT="False"
export PACKER_DEBUG="False"
export PACKER_SSH_TIMEOUT="50m"
export PACKER_SSH_HANDSHAKE_ATTEMPTS=10
# The location of the core configuration file
export PACKER_CONFIG="$(cygpath -m ${HOME_BASEDIR}/.packerconfig)"
# The location of the packer.d config directory
export PACKER_CONFIG_DIR="$(cygpath -m ${HOME_BASEDIR})"
export VBOXPATH="/cygdrive/c/Program Files/Oracle/VirtualBox"
export QEMUPATH="/cygdrive/c/Program Files/qemu"
export PATH="${VBOXPATH}:${QEMUPATH}:${PATH}"
export SO_GUESTOSTYPE="RedHat_64"
# Disk size of virtual machine in MB
export SO_GUESTDISKSIZE=40960
# Values for hard_drive_interface are: ide sata or scsi
export SO_GUESTHDDINTERFACE="sata"
# The image obtained can be Minimal (for servers) or Desktop (for final users using a GUI)
export SO_IMAGETYPE="Minimal"
export SO_DISTRIBUTION="CentOS"
export SO_MAJORVERSION="7"
export SO_MINORVERSION="8"
export SO_NAMEVERSION="2003"
export SO_SHORTVERSION="${SO_MAJORVERSION}.${SO_MINORVERSION}"
# The iso file type to download and use can be Minimal or DVD (can exists others but here only use these types)
export SO_ISOTYPE="Minimal"
export SO_ISOIMAGENAME="${SO_DISTRIBUTION}-${SO_MAJORVERSION}-x86_64-${SO_ISOTYPE}-${SO_NAMEVERSION}.iso"
export SO_ISOURLIMAGE="http://ftp.uma.es/mirror/${SO_DISTRIBUTION}/${SO_MAJORVERSION}.${SO_MINORVERSION}.${SO_NAMEVERSION}/isos/x86_64/${SO_ISOIMAGENAME}"
export SO_ISOSHA256SUMNAME="${SO_ISOIMAGENAME%.iso}.sum"
export SO_ISOCHECKSUMTYPE="sha256"
export SO_ISOURLSHA256SUM="http://ftp.uma.es/mirror/${SO_DISTRIBUTION}/${SO_MAJORVERSION}.${SO_MINORVERSION}.${SO_NAMEVERSION}/isos/x86_64/sha256sum.txt"
export SO_BUILDDATE="$(date +%Y%m%d)"
export SO_VMFULLNAME="${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}"
```


## 5.4. Optionally upload to the OpenStack Image Store

If you have one *OpenStack virtualization environment*, you can upload the **qcow2** image file to the *OpenStack Image Store*.

To do the upload you need one appropiated virtualenv and environment variables defined and be registered in that *OpenStack virtualization environment* and launch:

```bash
CentOS7Minimal/bin/upload-qcow2-to-openstack.sh
```


## 5.5. Utility files used in this image

When build this image the following files in [Files for CentOS7Minimal Directory](CentOS7Minimal/files "Files for CentOS7Minimal Directory") folder are installed and configured.

* **control-cloud-init.service**: Unit to control `cloud-init` to enable in *OpenStack* or *KVM* or *AWS* and mask in *VMware* or *VirtualBox* or other virtualization systems. This unit calls the file `/usr/local/bin/control-cloud-init.sh`. Installed in `/etc/systemd/system/control-cloud-init.service`. See [control-cloud-init.service](CentOS7Minimal/files/control-cloud-init.service "control-cloud-init.service").

* **control-cloud-init.sh**: Process that controls `cloud-init` to enable in *OpenStack* or *KVM* or *AWS* and mask in *VMware* or *VirtualBox* or other virtualization systems. Installed in `/usr/local/bin/control-cloud-init.sh`. See [control-cloud-init.sh](CentOS7Minimal/files/control-cloud-init.sh "control-cloud-init.sh").

* **guest-vmtools.service**: Unit to manage virtual machine tools for *VirtualBox*, *VMware* or *VMware ESXI*. This unit calls the file `/usr/local/bin/guest-vmtools.sh`. Installed in `/etc/systemd/system/guest-vmtools.service`. See [guest-vmtools.service](CentOS7Minimal/files/guest-vmtools.service "guest-vmtools.service").

* **guest-vmtools.sh**: Process that install and configure the *GuestTools* for *VirtualBox* or *VMwareTools* for *VMware* or *VMware ESXI*. Or remove these tools if boot in other virtual environments. Installed in `/usr/local/bin/guest-vmtools.sh`. See [guest-vmtools.sh](CentOS7Minimal/files/guest-vmtools.sh "guest-vmtools.sh").

* **host-info.sh**: Process that informs over basic properties of a host (CPU, memory, etc). Installed in `/usr/local/bin/host-info.sh`. See [host-info.sh](CentOS7Minimal/files/host-info.sh "host-info.sh").

  Execution example:
  ```bash
  ===========================================================================
  HOSTNAME...........: centos
  INTERFACES.........:
  Interface         MAC Address       IP4 Address                                   IP6 Address
  eth0              08:00:27:af:7d:d5 192.168.56.135/24                             fe80::a00:27ff:feaf:7dd5/64
  eth1              08:00:27:d8:38:b4 10.0.3.15/24                                  fe80::a00:27ff:fed8:38b4/64
  CPU TOTAL..........: 1
  CPU ONLINE.........: 1
  MEMORY.............:
                total        used        free      shared  buff/cache   available
  Mem:           990M         94M        658M        6.5M        237M        752M
  Swap:          2.0G          0B        2.0G
  FILESYSTEMS........:
  Filesystem                      Size  Used Avail Use% Mounted on
  devtmpfs                        485M     0  485M   0% /dev
  tmpfs                           496M     0  496M   0% /dev/shm
  tmpfs                           496M  6.6M  489M   2% /run
  tmpfs                           496M     0  496M   0% /sys/fs/cgroup
  /dev/mapper/centos_centos-root   17G  874M   17G   6% /
  /dev/sda1                      1014M   68M  947M   7% /boot
  tmpfs                           100M     0  100M   0% /run/user/1000
  SYSTEM UPTIME......: 14:28:06 up 1 min, 1 user, load average: 0.87, 0.42, 0.15
  RELEASE............: CentOS Linux release 7.8.2003 (Core)
  KERNEL.............: 3.10.0-1127.8.2.el7.x86_64
  DATE...............: Sun May 17 14:28:06 CEST 2020
  USERS..............: Currently 1 user(s) logged on
  CURRENT USER.......: sysadmin
  PROCESSES..........: 186 running
  CPU DETAILED INFO..:
  Architecture:          x86_64
  CPU op-mode(s):        32-bit, 64-bit
  Byte Order:            Little Endian
  CPU(s):                1
  On-line CPU(s) list:   0
  Thread(s) per core:    1
  Core(s) per socket:    1
  Socket(s):             1
  NUMA node(s):          1
  Vendor ID:             GenuineIntel
  CPU family:            6
  Model:                 142
  Model name:            Intel(R) Core(TM) i5-8250U CPU @ 1.60GHz
  Stepping:              10
  CPU MHz:               1800.003
  BogoMIPS:              3600.00
  Hypervisor vendor:     KVM
  Virtualization type:   full
  L1d cache:             32K
  L1i cache:             32K
  L2 cache:              256K
  L3 cache:              6144K
  NUMA node0 CPU(s):     0
  Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc eagerfpu pni pclmulqdq monitor ssse3 cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx rdrand hypervisor lahf_lm abm 3dnowprefetch invpcid_single fsgsbase avx2 invpcid rdseed clflushopt md_clear flush_l1d
  ===========================================================================
  ```

* **switch-to-graphical-user-interface.sh**: Process that install and enable the `GNOME Display Manager` and set `Graphical Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-graphical-user-interface.sh`. See [switch-to-graphical-user-interface.sh](CentOS7Minimal/files/switch-to-graphical-user-interface.sh "switch-to-graphical-user-interface.sh").

* **switch-to-text-user-interface.sh**: Process that disables (not uninstall) the `GNOME Display Manager` and set `Text Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-text-user-interface.sh`. See [switch-to-text-user-interface.sh](CentOS7Minimal/files/switch-to-text-user-interface.sh "switch-to-text-user-interface.sh").


## 5.6. Virtual machine example in VirtualBox

Steps to use virtual machines using *VirtualBox*.


### 5.6.1. Import the virtualized service

To import virtualized service in *VirtualBox* to create a virtual machine perform the following steps using the `Oracle VM VirtualBox Administrator`.

- Click in `Archive -> Import virtualized service...`
- Click in `Select a virtualized service file to import...` in `Service to import`. Example `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\CentOS7.8-2003-Minimal-20200517.ovf`
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
- Click in `Player->File->Open...` and select the **ovf** file `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\CentOS7.8-2003-Minimal-20200517.ovf`
- Name for the new virtual machine: `CentOS7.8-2003-Minimal-20200517`
- Storage path for the new virtual machine: `C:\VMware\CentOS7.8-2003-Minimal-20200517`
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

- To get an image for *VMware ESXI* version `5.5` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=10 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.8-2003-Minimal-20200517\CentOS7.8-2003-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.8-2003-Minimal-20200517-esx10.ovf'
```

- To get an image for *VMware ESXI* version `6.0` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=11 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.8-2003-Minimal-20200517\CentOS7.8-2003-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.8-2003-Minimal-20200517-esx11.ovf'
```

- To get an image for *VMware ESXI* version `6.5` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=13 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.8-2003-Minimal-20200517\CentOS7.8-2003-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.8-2003-Minimal-20200517-esx13.ovf'
```

- To get an image for *VMware ESXI* version `6.7` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=14 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.8-2003-Minimal-20200517\CentOS7.8-2003-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.8-2003-Minimal-20200517-esx14.ovf'
```

- To get an image for *VMware ESXI* version `6.7 U2` or `6.8.x` or `6.9.x` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=15 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.8-2003-Minimal-20200517\CentOS7.8-2003-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.8-2003-Minimal-20200517-esx15.ovf'
```

- To get an image for *VMware ESXI* version `7.0.x` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=17 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.8-2003-Minimal-20200517\CentOS7.8-2003-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.8-2003-Minimal-20200517-esx17.ovf'
```


# 6. Build CentOS 8 Minimal image

This section explains howto build this *Virtual Machine Image*.


## 6.1. Download and install Packer

To build the image you need to download and install *Packer* software.

The directory where it install this software is `CentOS8Minimal/packer-software`.

The version is determined by its own configuration file located at [CentOS8Minimal Configuration Directory](CentOS8Minimal/conf/virtual-machine.conf "CentOS8Minimal Configuration Directory").

To perform this task run:

```bash
CentOS8Minimal/bin/download-and-install-packer.sh
```


## 6.2. Download the iso image

To build the image you need to download the **iso** files for this *Operating System*.

The directory where it download this **iso** files is `isos` at home of this repository.

The version is determined by its own configuration file located at [CentOS8Minimal Configuration Directory](CentOS8Minimal/conf/virtual-machine.conf "CentOS8Minimal Configuration Directory").

To perform this task run:

```bash
CentOS8Minimal/bin/download-iso.sh
```


## 6.3. Build the image

You need enter the `username` and `userpass` of the *Linux* admin account what is desired, and one optional parameter for the `cloud-init` default user (if this parameter is not provided then the default user is `cloud-user`.

```bash
CentOS8Minimal/bin/build-virtual-machine.sh --adminuser adminuser --adminpass adminpass [--defaultclouduser defaultclouduser]
```

When finished the build then will create the image files **vmdk**, **ovf** and **qcow2** inside the `images` directory at home of this repository.

To understand how the builder works see the configuration files in [CentOS8Minimal Configuration Directory](CentOS8Minimal/conf/virtual-machine.conf "CentOS8Minimal Configuration Directory").

The format name of the generated image files is as follows:

```bash
${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}.(vmdk|ovf|qcow2)
```

Example of **CentOS 8 Minimal** configuration file:

```bash
# Variables to build Operating System
# For Packer version you can use one release or nightly to use nightly build
export PACKER_VERSION="1.5.6"
export PACKER_MACHINEREADABLEOUTPUT="False"
export PACKER_DEBUG="False"
export PACKER_SSH_TIMEOUT="50m"
export PACKER_SSH_HANDSHAKE_ATTEMPTS=10
# The location of the core configuration file
export PACKER_CONFIG="$(cygpath -m ${HOME_BASEDIR}/.packerconfig)"
# The location of the packer.d config directory
export PACKER_CONFIG_DIR="$(cygpath -m ${HOME_BASEDIR})"
export VBOXPATH="/cygdrive/c/Program Files/Oracle/VirtualBox"
export QEMUPATH="/cygdrive/c/Program Files/qemu"
export PATH="${VBOXPATH}:${QEMUPATH}:${PATH}"
export SO_GUESTOSTYPE="RedHat_64"
# Disk size of virtual machine in MB
export SO_GUESTDISKSIZE=40960
# Values for hard_drive_interface are: ide sata or scsi
export SO_GUESTHDDINTERFACE="sata"
# The image obtained can be Minimal (for servers) or Desktop (for final users using a GUI)
export SO_IMAGETYPE="Minimal"
export SO_DISTRIBUTION="CentOS"
export SO_MAJORVERSION="8"
export SO_MINORVERSION="1"
export SO_NAMEVERSION="1911"
export SO_SHORTVERSION="${SO_MAJORVERSION}.${SO_MINORVERSION}"
# The iso file type to download and use can be boot or dvd1 (can exists others but here only use these types)
export SO_ISOTYPE="boot"
export SO_ISOIMAGENAME="${SO_DISTRIBUTION}-${SO_MAJORVERSION}.${SO_MINORVERSION}.${SO_NAMEVERSION}-x86_64-${SO_ISOTYPE}.iso"
export SO_ISOURLIMAGE="http://ftp.uma.es/mirror/${SO_DISTRIBUTION}/${SO_MAJORVERSION}/isos/x86_64/${SO_ISOIMAGENAME}"
export SO_ISOSHA256SUMNAME="${SO_ISOIMAGENAME%.iso}.sum"
export SO_ISOCHECKSUMTYPE="sha256"
export SO_ISOURLSHA256SUM="http://ftp.uma.es/mirror/${SO_DISTRIBUTION}/${SO_MAJORVERSION}/isos/x86_64/CHECKSUM"
export SO_BUILDDATE="$(date +%Y%m%d)"
export SO_VMFULLNAME="${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}"
```


## 6.4. Optionally upload to the OpenStack Image Store

If you have one *OpenStack virtualization environment*, you can upload the **qcow2** image file to the *OpenStack Image Store*.

To do the upload you need one appropiated virtualenv and environment variables defined and be registered in that *OpenStack virtualization environment* and launch:

```bash
CentOS8Minimal/bin/upload-qcow2-to-openstack.sh
```


## 6.5. Utility files used in this image

When build this image the following files in [Files for CentOS8Minimal Directory](CentOS8Minimal/files "Files for CentOS8Minimal Directory") folder are installed and configured.

* **control-cloud-init.service**: Unit to control `cloud-init` to enable in *OpenStack* or *KVM* or *AWS* and mask in *VMware* or *VirtualBox* or other virtualization systems. This unit calls the file `/usr/local/bin/control-cloud-init.sh`. Installed in `/etc/systemd/system/control-cloud-init.service`. See [control-cloud-init.service](CentOS8Minimal/files/control-cloud-init.service "control-cloud-init.service").

* **control-cloud-init.sh**: Process that controls `cloud-init` to enable in *OpenStack* or *KVM* or *AWS* and mask in *VMware* or *VirtualBox* or other virtualization systems. Installed in `/usr/local/bin/control-cloud-init.sh`. See [control-cloud-init.sh](CentOS8Minimal/files/control-cloud-init.sh "control-cloud-init.sh").

* **guest-vmtools.service**: Unit to manage virtual machine tools for *VirtualBox*, *VMware* or *VMware ESXI*. This unit calls the file `/usr/local/bin/guest-vmtools.sh`. Installed in `/etc/systemd/system/guest-vmtools.service`. See [guest-vmtools.service](CentOS8Minimal/files/guest-vmtools.service "guest-vmtools.service").

* **guest-vmtools.sh**: Process that install and configure the *GuestTools* for *VirtualBox* or *VMwareTools* for *VMware* or *VMware ESXI*. Or remove these tools if boot in other virtual environments. Installed in `/usr/local/bin/guest-vmtools.sh`. See [guest-vmtools.sh](CentOS8Minimal/files/guest-vmtools.sh "guest-vmtools.sh").

* **host-info.sh**: Process that informs over basic properties of a host (CPU, memory, etc). Installed in `/usr/local/bin/host-info.sh`. See [host-info.sh](CentOS8Minimal/files/host-info.sh "host-info.sh").

  Execution example:
  ```bash
  ===========================================================================
  HOSTNAME...........: centos
  INTERFACES.........:
  Interface         MAC Address       IP4 Address                                   IP6 Address
  eth0              08:00:27:53:ac:d3 192.168.56.136/24                             fe80::a00:27ff:fe53:acd3/64
  eth1              08:00:27:38:bf:8b 10.0.3.15/24                                  fe80::a00:27ff:fe38:bf8b/64
  CPU TOTAL..........: 1
  CPU ONLINE.........: 1
  MEMORY.............:
                total        used        free      shared  buff/cache   available
  Mem:          821Mi       107Mi       440Mi       5.0Mi       273Mi       583Mi
  Swap:         2.0Gi          0B       2.0Gi
  FILESYSTEMS........:
  Filesystem                  Size  Used Avail Use% Mounted on
  devtmpfs                    397M     0  397M   0% /dev
  tmpfs                       411M     0  411M   0% /dev/shm
  tmpfs                       411M  5.5M  406M   2% /run
  tmpfs                       411M     0  411M   0% /sys/fs/cgroup
  /dev/mapper/cl_centos-root   17G  1.3G   16G   8% /
  /dev/sda1                   976M   42M  868M   5% /boot
  tmpfs                        83M     0   83M   0% /run/user/1000
  SYSTEM UPTIME......: 14:31:33 up 0 min, 1 user, load average: 1.99, 0.70, 0.25
  RELEASE............: CentOS Linux release 8.1.1911 (Core)
  KERNEL.............: 4.18.0-147.8.1.el8_1.x86_64
  DATE...............: Sun May 17 14:31:33 CEST 2020
  USERS..............: Currently 1 user(s) logged on
  CURRENT USER.......: sysadmin
  PROCESSES..........: 184 running
  CPU DETAILED INFO..:
  Architecture:        x86_64
  CPU op-mode(s):      32-bit, 64-bit
  Byte Order:          Little Endian
  CPU(s):              1
  On-line CPU(s) list: 0
  Thread(s) per core:  1
  Core(s) per socket:  1
  Socket(s):           1
  NUMA node(s):        1
  Vendor ID:           GenuineIntel
  CPU family:          6
  Model:               142
  Model name:          Intel(R) Core(TM) i5-8250U CPU @ 1.60GHz
  Stepping:            10
  CPU MHz:             1800.003
  BogoMIPS:            3600.00
  Hypervisor vendor:   KVM
  Virtualization type: full
  L1d cache:           32K
  L1i cache:           32K
  L2 cache:            256K
  L3 cache:            6144K
  NUMA node0 CPU(s):   0
  Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq monitor ssse3 cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx rdrand hypervisor lahf_lm abm 3dnowprefetch invpcid_single pti fsgsbase avx2 invpcid rdseed clflushopt md_clear flush_l1d
  ===========================================================================
  ```

* **switch-to-graphical-user-interface.sh**: Process that install and enable the `GNOME Display Manager` and set `Graphical Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-graphical-user-interface.sh`. See [switch-to-graphical-user-interface.sh](CentOS8Minimal/files/switch-to-graphical-user-interface.sh "switch-to-graphical-user-interface.sh").

* **switch-to-text-user-interface.sh**: Process that disables (not uninstall) the `GNOME Display Manager` and set `Text Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-text-user-interface.sh`. See [switch-to-text-user-interface.sh](CentOS8Minimal/files/switch-to-text-user-interface.sh "switch-to-text-user-interface.sh").


## 6.6. Virtual machine example in VirtualBox

Steps to use virtual machines using *VirtualBox*.


### 6.6.1. Import the virtualized service

To import virtualized service in *VirtualBox* to create a virtual machine perform the following steps using the `Oracle VM VirtualBox Administrator`.

- Click in `Archive -> Import virtualized service...`
- Click in `Select a virtualized service file to import...` in `Service to import`. Example `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\CentOS8.1-1911-Minimal-20200504.ovf`
- Name: `myvm`
- Type of guest OS: `Red Hat (64-bit)`
- CPU: `1`
- RAM: `1024 MB`
- Storage Controller (SATA) -> Virtual Disk Image: `myvm.vdi`
- MAC address policy: `Generate new MAC addresses for all network adapters`
- Additional options: `Import disks as VDI`
- Click in `Import` button


### 6.6.2. Configure the virtual machine

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


### 6.6.3. Use the virtual machine

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


## 6.7. Convert vmdk image to work inside VMware ESXI

The image formats obtained **vmdk** or **ovf** are compatible with *VMware Workstation Player* but they are not compatible for *VMware ESXI*.

For this reason you need to use *VMware Workstation Player* for Windows to obtain a compatible virtual machine.

Then follow these steps:

- Open *VMware Workstation Player*
- Click in `Player->File->Open...` and select the **ovf** file `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\CentOS8.1-1911-Minimal-20200504.ovf`
- Name for the new virtual machine: `CentOS8.1-1911-Minimal-20200504`
- Storage path for the new virtual machine: `C:\VMware\CentOS8.1-1911-Minimal-20200504`
- Click in `Import` button
- Click in `Retry` button to relax OVF specifications
- Click in `Edit virtual machine settings`
- Options -> General -> Guest Operation System: `Linux`
- Options -> General -> Guest Operation System -> Version: `Centos 8 64-bit`
- Options -> VMware Tools -> VMware Tools features -> Syncronize guest time with host: `Enabled`
- Hardware->Network Adapter -> Network connection -> Bridged: Connected directly to the physical network: `Enabled`
- Hardware->Network Adapter -> Network connection -> Replicate physical network connection state: `Disabled`
- Hardware->Network Adapter -> Network connection -> Configure Adapters -> Realtek PCIe GBE Family Controller: `Enabled`
- Hardware->Network Adapter -> Network connection -> Configure Adapters -> Other adapters: `Disabled`

Then you have an image imported into *VMware Workstation Player*. Here you need to choose the *VMware ESXI* version reading the article <https://kb.vmware.com/s/article/1003746> and follow these steps:

- Enter in a *Cygwin64 session*.

- To get an image for *VMware ESXI* version `5.5` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=10 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS8.1-1911-Minimal-20200504\CentOS8.1-1911-Minimal-20200504.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS8.1-1911-Minimal-20200504-esx10.ovf'
```

- To get an image for *VMware ESXI* version `6.0` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=11 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS8.1-1911-Minimal-20200504\CentOS8.1-1911-Minimal-20200504.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS8.1-1911-Minimal-20200504-esx11.ovf'
```

- To get an image for *VMware ESXI* version `6.5` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=13 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS8.1-1911-Minimal-20200504\CentOS8.1-1911-Minimal-20200504.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS8.1-1911-Minimal-20200504-esx13.ovf'
```

- To get an image for *VMware ESXI* version `6.7` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=14 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS8.1-1911-Minimal-20200504\CentOS8.1-1911-Minimal-20200504.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS8.1-1911-Minimal-20200504-esx14.ovf'
```

- To get an image for *VMware ESXI* version `6.7 U2` or `6.8.x` or `6.9.x` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=15 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS8.1-1911-Minimal-20200504\CentOS8.1-1911-Minimal-20200504.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS8.1-1911-Minimal-20200504-esx15.ovf'
```

- To get an image for *VMware ESXI* version `7.0.x` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=17 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS8.1-1911-Minimal-20200504\CentOS8.1-1911-Minimal-20200504.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS8.1-1911-Minimal-20200504-esx17.ovf'
```


# 7. Build Ubuntu 20 Minimal image

This section explains howto build this *Virtual Machine Image*.


## 7.1. Download and install Packer

To build the image you need to download and install *Packer* software.

The directory where it install this software is `Ubuntu20Minimal/packer-software`.

The version is determined by its own configuration file located at [Ubuntu20Minimal Configuration Directory](Ubuntu20Minimal/conf/virtual-machine.conf "Ubuntu20Minimal Configuration Directory").

To perform this task run:

```bash
Ubuntu20Minimal/bin/download-and-install-packer.sh
```


## 7.2. Download the iso image

To build the image you need to download the **iso** files for this *Operating System*.

The directory where it download this **iso** files is `isos` at home of this repository.

The version is determined by its own configuration file located at [Ubuntu20Minimal Configuration Directory](Ubuntu20Minimal/conf/virtual-machine.conf "Ubuntu20Minimal Configuration Directory").

To perform this task run:

```bash
Ubuntu20Minimal/bin/download-iso.sh
```


## 7.3. Build the image

You need enter the `username` and `userpass` of the *Linux* admin account what is desired, and one optional parameter for the `cloud-init` default user (if this parameter is not provided then the default user is `cloud-user`.

```bash
Ubuntu20Minimal/bin/build-virtual-machine.sh --adminuser adminuser --adminpass adminpass [--defaultclouduser defaultclouduser]
```

When finished the build then will create the image files **vmdk**, **ovf** and **qcow2** inside the `images` directory at home of this repository.

To understand how the builder works see the configuration files in [Ubuntu20Minimal Configuration Directory](Ubuntu20Minimal/conf/virtual-machine.conf "Ubuntu20Minimal Configuration Directory").

The format name of the generated image files is as follows:

```bash
${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}.(vmdk|ovf|qcow2)
```

Example of **Ubuntu 20 Minimal** configuration file:

```bash
# Variables to build Operating System
# For Packer version you can use one release or nightly to use nightly build
export PACKER_VERSION="1.5.6"
export PACKER_MACHINEREADABLEOUTPUT="False"
export PACKER_DEBUG="False"
export PACKER_SSH_TIMEOUT="20m"
export PACKER_SSH_HANDSHAKE_ATTEMPTS=30
# The location of the core configuration file
export PACKER_CONFIG="$(cygpath -m ${HOME_BASEDIR}/.packerconfig)"
# The location of the packer.d config directory
export PACKER_CONFIG_DIR="$(cygpath -m ${HOME_BASEDIR})"
export VBOXPATH="/cygdrive/c/Program Files/Oracle/VirtualBox"
export QEMUPATH="/cygdrive/c/Program Files/qemu"
export PATH="${VBOXPATH}:${QEMUPATH}:${PATH}"
export SO_GUESTOSTYPE="Ubuntu_64"
# Disk size of virtual machine in MB
export SO_GUESTDISKSIZE=40960
# Values for hard_drive_interface are: ide sata or scsi
export SO_GUESTHDDINTERFACE="sata"
# The image obtained can be Minimal (for servers) or Desktop (for final users using a GUI)
export SO_IMAGETYPE="Minimal"
export SO_DISTRIBUTION="Ubuntu"
export SO_MAJORVERSION="20"
export SO_MINORVERSION="04"
export SO_NAMEVERSION="server"
export SO_SHORTVERSION="${SO_MAJORVERSION}.${SO_MINORVERSION}"
# The iso file type to download and use can be boot or dvd1 (can exists others but here only use these types)
export SO_ISOTYPE="live-server"
export SO_ISOIMAGENAME="${SO_DISTRIBUTION,,}-${SO_SHORTVERSION}-${SO_ISOTYPE}-amd64.iso"
export SO_ISOURLIMAGE="https://releases.ubuntu.com/${SO_SHORTVERSION}/${SO_ISOIMAGENAME}"
export SO_ISOSHA256SUMNAME="${SO_ISOIMAGENAME%.iso}.sum"
export SO_ISOCHECKSUMTYPE="sha256"
export SO_ISOURLSHA256SUM="https://releases.ubuntu.com/${SO_SHORTVERSION}/SHA256SUMS"
export SO_BUILDDATE="$(date +%Y%m%d)"
export SO_VMFULLNAME="${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}"
```


## 7.4. Optionally upload to the OpenStack Image Store

If you have one *OpenStack virtualization environment*, you can upload the **qcow2** image file to the *OpenStack Image Store*.

To do the upload you need one appropiated virtualenv and environment variables defined and be registered in that *OpenStack virtualization environment* and launch:

```bash
Ubuntu20Minimal/bin/upload-qcow2-to-openstack.sh
```


## 7.5. Utility files used in this image

When build this image the following files in [Files for Ubuntu20Minimal Directory](Ubuntu20Minimal/files "Files for Ubuntu20Minimal Directory") folder are installed and configured.

* **control-cloud-init.service**: Unit to control `cloud-init` to enable in *OpenStack* or *KVM* or *AWS* and mask in *VMware* or *VirtualBox* or other virtualization systems. This unit calls the file `/usr/local/bin/control-cloud-init.sh`. Installed in `/etc/systemd/system/control-cloud-init.service`. See [control-cloud-init.service](Ubuntu20Minimal/files/control-cloud-init.service "control-cloud-init.service").

* **control-cloud-init.sh**: Process that controls `cloud-init` to enable in *OpenStack* or *KVM* or *AWS* and mask in *VMware* or *VirtualBox* or other virtualization systems. Installed in `/usr/local/bin/control-cloud-init.sh`. See [control-cloud-init.sh](Ubuntu20Minimal/files/control-cloud-init.sh "control-cloud-init.sh").

* **guest-vmtools.service**: Unit to manage virtual machine tools for *VirtualBox*, *VMware* or *VMware ESXI*. This unit calls the file `/usr/local/bin/guest-vmtools.sh`. Installed in `/etc/systemd/system/guest-vmtools.service`. See [guest-vmtools.service](Ubuntu20Minimal/files/guest-vmtools.service "guest-vmtools.service").

* **guest-vmtools.sh**: Process that install and configure the *GuestTools* for *VirtualBox* or *VMwareTools* for *VMware* or *VMware ESXI*. Or remove these tools if boot in other virtual environments. Installed in `/usr/local/bin/guest-vmtools.sh`. See [guest-vmtools.sh](Ubuntu20Minimal/files/guest-vmtools.sh "guest-vmtools.sh").

* **host-info.sh**: Process that informs over basic properties of a host (CPU, memory, etc). Installed in `/usr/local/bin/host-info.sh`. See [host-info.sh](Ubuntu20Minimal/files/host-info.sh "host-info.sh").

  Execution example:
  ```bash
  ===========================================================================
  HOSTNAME...........: ubuntu
  INTERFACES.........:
  Interface         MAC Address       IP4 Address                                   IP6 Address
  eth0              08:00:27:c3:0d:f7 192.168.56.138/24                             fe80::a00:27ff:fec3:df7/64
  eth1              08:00:27:95:ed:5b 10.0.3.15/24                                  fe80::a00:27ff:fe95:ed5b/64
  CPU TOTAL..........: 1
  CPU ONLINE.........: 1
  MEMORY.............:
                total        used        free      shared  buff/cache   available
  Mem:          981Mi       153Mi       567Mi       0.0Ki       260Mi       681Mi
  Swap:         1.9Gi          0B       1.9Gi
  FILESYSTEMS........:
  Filesystem                         Size  Used Avail Use% Mounted on
  udev                               449M     0  449M   0% /dev
  tmpfs                               99M 1012K   98M   2% /run
  /dev/mapper/ubuntu--vg-ubuntu--lv   19G  4.1G   14G  23% /
  tmpfs                              491M     0  491M   0% /dev/shm
  tmpfs                              5.0M     0  5.0M   0% /run/lock
  tmpfs                              491M     0  491M   0% /sys/fs/cgroup
  /dev/sda2                          976M  103M  806M  12% /boot
  /dev/loop0                          55M   55M     0 100% /snap/core18/1705
  /dev/loop1                          69M   69M     0 100% /snap/lxd/14804
  /dev/loop2                          28M   28M     0 100% /snap/snapd/7264
  tmpfs                               99M     0   99M   0% /run/user/1000
  SYSTEM UPTIME......: 21:28:33 up 24 min, 2 users, load average: 0.00, 0.00, 0.02
  RELEASE............: Ubuntu 20.04 LTS (Focal Fossa)
  KERNEL.............: 5.4.0-29-generic
  DATE...............: Sun 17 May 2020 09:28:33 PM UTC
  USERS..............: Currently 2 user(s) logged on
  CURRENT USER.......: sysadmin
  PROCESSES..........: 162 running
  CPU DETAILED INFO..:
  Architecture:                    x86_64
  CPU op-mode(s):                  32-bit, 64-bit
  Byte Order:                      Little Endian
  Address sizes:                   39 bits physical, 48 bits virtual
  CPU(s):                          1
  On-line CPU(s) list:             0
  Thread(s) per core:              1
  Core(s) per socket:              1
  Socket(s):                       1
  NUMA node(s):                    1
  Vendor ID:                       GenuineIntel
  CPU family:                      6
  Model:                           142
  Model name:                      Intel(R) Core(TM) i5-8250U CPU @ 1.60GHz
  Stepping:                        10
  CPU MHz:                         1800.003
  BogoMIPS:                        3600.00
  Hypervisor vendor:               KVM
  Virtualization type:             full
  L1d cache:                       32 KiB
  L1i cache:                       32 KiB
  L2 cache:                        256 KiB
  L3 cache:                        6 MiB
  NUMA node0 CPU(s):               0
  Vulnerability Itlb multihit:     KVM: Vulnerable
  Vulnerability L1tf:              Mitigation; PTE Inversion
  Vulnerability Mds:               Mitigation; Clear CPU buffers; SMT Host state unknown
  Vulnerability Meltdown:          Mitigation; PTI
  Vulnerability Spec store bypass: Vulnerable
  Vulnerability Spectre v1:        Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Vulnerability Spectre v2:        Mitigation; Full generic retpoline, STIBP disabled, RSB filling
  Vulnerability Tsx async abort:   Not affected
  Flags:                           fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq monitor ssse3 cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx rdrand hypervisor lahf_lm abm 3dnowprefetch invpcid_single pti fsgsbase avx2 invpcid rdseed clflushopt md_clear flush_l1d
  ===========================================================================
  ```

* **switch-to-graphical-user-interface.sh**: Process that install and enable the `GNOME Display Manager` and set `Graphical Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-graphical-user-interface.sh`. See [switch-to-graphical-user-interface.sh](Ubuntu20Minimal/files/switch-to-graphical-user-interface.sh "switch-to-graphical-user-interface.sh").

* **switch-to-text-user-interface.sh**: Process that disables (not uninstall) the `GNOME Display Manager` and set `Text Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-text-user-interface.sh`. See [switch-to-text-user-interface.sh](Ubuntu20Minimal/files/switch-to-text-user-interface.sh "switch-to-text-user-interface.sh").


## 7.6. Virtual machine example in VirtualBox

Steps to use virtual machines using *VirtualBox*.


### 7.6.1. Import the virtualized service

To import virtualized service in *VirtualBox* to create a virtual machine perform the following steps using the `Oracle VM VirtualBox Administrator`.

TOREVIEW

- Click in `Archive -> Import virtualized service...`
- Click in `Select a virtualized service file to import...` in `Service to import`. Example `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\Ubuntu20.04-server-Minimal-20200517.ovf`
- Name: `myvm`
- Type of guest OS: `Ubuntu (64-bit)`
- CPU: `1`
- RAM: `1024 MB`
- Storage Controller (SATA) -> Virtual Disk Image: `myvm.vdi`
- MAC address policy: `Generate new MAC addresses for all network adapters`
- Additional options: `Import disks as VDI`
- Click in `Import` button


### 7.6.2. Configure the virtual machine

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


### 7.6.3. Use the virtual machine

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


## 7.7. Convert vmdk image to work inside VMware ESXI

The image formats obtained **vmdk** or **ovf** are compatible with *VMware Workstation Player* but they are not compatible for *VMware ESXI*.

For this reason you need to use *VMware Workstation Player* for Windows to obtain a compatible virtual machine.

Then follow these steps:

- Open *VMware Workstation Player*
- Click in `Player->File->Open...` and select the **ovf** file `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\Ubuntu20.04-server-Minimal-20200517.ovf`
- Name for the new virtual machine: `Ubuntu20.04-server-Minimal-20200517`
- Storage path for the new virtual machine: `C:\VMware\Ubuntu20.04-server-Minimal-20200517`
- Click in `Import` button
- Click in `Retry` button to relax OVF specifications
- Click in `Edit virtual machine settings`
- Options -> General -> Guest Operation System: `Linux`
- Options -> General -> Guest Operation System -> Version: `Ubuntu 64-bit`
- Options -> VMware Tools -> VMware Tools features -> Syncronize guest time with host: `Enabled`
- Hardware->Network Adapter -> Network connection -> Bridged: Connected directly to the physical network: `Enabled`
- Hardware->Network Adapter -> Network connection -> Replicate physical network connection state: `Disabled`
- Hardware->Network Adapter -> Network connection -> Configure Adapters -> Realtek PCIe GBE Family Controller: `Enabled`
- Hardware->Network Adapter -> Network connection -> Configure Adapters -> Other adapters: `Disabled`

Then you have an image imported into *VMware Workstation Player*. Here you need to choose the *VMware ESXI* version reading the article <https://kb.vmware.com/s/article/1003746> and follow these steps:

- Enter in a *Cygwin64 session*.

- To get an image for *VMware ESXI* version `5.5` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=10 --skipManifestCheck --skipManifestGeneration 'C:\VMware\Ubuntu20.04-server-Minimal-20200517\Ubuntu20.04-server-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\Ubuntu20.04-server-Minimal-20200517-esx10.ovf'
```

- To get an image for *VMware ESXI* version `6.0` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=11 --skipManifestCheck --skipManifestGeneration 'C:\VMware\Ubuntu20.04-server-Minimal-20200517\Ubuntu20.04-server-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\Ubuntu20.04-server-Minimal-20200517-esx11.ovf'
```

- To get an image for *VMware ESXI* version `6.5` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=13 --skipManifestCheck --skipManifestGeneration 'C:\VMware\Ubuntu20.04-server-Minimal-20200517\Ubuntu20.04-server-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\Ubuntu20.04-server-Minimal-20200517-esx13.ovf'
```

- To get an image for *VMware ESXI* version `6.7` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=14 --skipManifestCheck --skipManifestGeneration 'C:\VMware\Ubuntu20.04-server-Minimal-20200517\Ubuntu20.04-server-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\Ubuntu20.04-server-Minimal-20200517-esx14.ovf'
```

- To get an image for *VMware ESXI* version `6.7 U2` or `6.8.x` or `6.9.x` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=15 --skipManifestCheck --skipManifestGeneration 'C:\VMware\Ubuntu20.04-server-Minimal-20200517\Ubuntu20.04-server-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\Ubuntu20.04-server-Minimal-20200517-esx15.ovf'
```

- To get an image for *VMware ESXI* version `7.0.x` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=17 --skipManifestCheck --skipManifestGeneration 'C:\VMware\Ubuntu20.04-server-Minimal-20200517\Ubuntu20.04-server-Minimal-20200517.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\Ubuntu20.04-server-Minimal-20200517-esx17.ovf'
```
