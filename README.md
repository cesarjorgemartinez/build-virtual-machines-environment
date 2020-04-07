<h1><center><b>Automate Virtual Machine Images</b></center></h1>
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
- [2. Create and configure the environment](#2-create-and-configure-the-environment)
   - [2.1. Install VirtualBox](#21-install-virtualbox)
   - [2.2. Install VMware Workstation Player](#22-install-vmware-workstation-player)
   - [2.3. Install CygWin 64 bits](#23-install-cygwin-64-bits)
   - [2.4. Disable Windows Python installation](#24-disable-windows-python-installation)
   - [2.5. Install needed CygWin packages](#25-install-needed-cygwin-packages)
   - [2.6. Install Python system pip packages](#26-install-python-system-pip-packages)
   - [2.7. Configure your Git environment to work with github](#27-configure-your-git-environment-to-work-with-github)
- [3. Getting started for CentOS 7 minimum](#3-getting-started-for-centos-7-minimum)
   - [3.1. Clone and enter in the git root directory of this repository](#31-clone-and-enter-in-the-git-root-directory-of-this-repository)
   - [3.2. Get the software to work for this project](#32-get-the-software-to-work-for-this-project)
   - [3.3. Build the image](#33-build-the-image)
   - [3.4. Optionally upload to the OpenStack Image Store](#34-optionally-upload-to-the-openstack-image-store)
   - [3.5. Utility files used in this image](#35-utility-files-used-in-this-image)
   - [3.6. Virtual machine example in VirtualBox](#36-virtual-machine-example-in-virtualbox)
      - [3.6.1. Import the virtualized service](#361-import-the-virtualized-service)
      - [3.6.2. Configure the virtual machine](#362-configure-the-virtual-machine)
      - [3.6.3. Use the virtual machine](#363-use-the-virtual-machine)
   - [3.7. Convert vmdk image to work inside VMware ESXI](#37-convert-vmdk-image-to-work-inside-vmware-esxi)
- [4. Build other Operating Systems](#4-build-other-operating-systems)

<!-- /MDTOC -->


# 1. Introduction

This project helps to build automatically *Virtual Machine Images of Operating Systems* that are **compatible** with different virtualization systems, as *OpenStack* (*kvm*), *VirtualBox*, *VMware*, *ESXI*, *Nutanix*, etc.

The image formats that are generated are the following:
- **vmdk:** For *VirtualBox*, *VMware* and *ESXI*.
- **ovf:** For *VirtualBox*, *VMware* and *ESXI*.
- **qcow2:** For *OpenStack* (*kvm*) and *Nutanix*.

The virtualization system *VirtualBox* also uses the **vdi** format. but it is not necessary since the *VirtualBox* itself converts the **vmdk** format into **vdi**.

You can deploy and boot directly these images in these virtualization systems without doing anything special or extra, thanks to the use of two *systemd* units:

- **control-cloud-init.service**: By default the cloud-init units are enabled. But if the virtual machine boots in a virtualization system that is not *OpenStack*, then disable the cloud-init units.
- **guest-vmtools.service**: If the virtual machine boots inside *VirtualBox* then install its *GuestTools* disabling others. If the virtual machine boots inside *VMware* or *ESXI* then install its *VMwareTools* disabling others.

For now you can only build an image of **CentOS 7 minimum**, ideal to work as servers in *Cloud*, *traditional* or *development* environments, and is very useful to work with **Docker**, because the size of the image created is very small. This image is builded with a *Linux* admin account provided as parameter at the time of build. The `cloud-init` software use other account provided as optional parameter at the time of build (not created because the `cloud-init` do this work at the first boot of the virtual machine) that by default is *cloud-user*.

To work with this software you need **Windows 10 for 64 bits** and **CygWin 64 bits** to use **Linux-Bash** commands.


# 2. Create and configure the environment

You need to do the next tasks.


## 2.1. Install VirtualBox

Go to this URL <https://www.virtualbox.org/wiki/Downloads> and install latest *VirtualBox* for Windows. You need to ensure that in addition to installing *VirtualBox* you also install *Oracle VM VirtualBox Extension Pack*.


## 2.2. Install VMware Workstation Player

Go to this URL <https://www.vmware.com/go/downloadworkstationplayer> and install latest *VMware Workstation Player* for Windows.

This is optional step only if you will be use *VMware* or *ESXI*.


## 2.3. Install CygWin 64 bits

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


## 2.4. Disable Windows Python installation

To prevent that *CygWin* use the *Python* installed in *Windows* (if exist), do the following to disable access to *Windows Python installation*:

- Enter in a *Cygwin64 session*.
- Launch this:
```bash
echo $'PATH=$(echo $PATH | tr \':\' \'\\n\' | grep -v "/cygdrive/.*/Python[23]7" | paste -sd:)' >> .bash_profile
exit
```


## 2.5. Install needed CygWin packages

You need to do the following tasks:

- Enter in a *Cygwin64 session*.
- Launch this:
```bash
curl -O https://cygwin.com/setup-x86_64.exe
./setup-x86_64.exe -q --packages="bash,python,python-devel,python-setuptools,python-crypto,python-paramiko,python2-boto,python2-certifi,python2-pip,openssl,openssh,openssl-devel,libffi-devel,gcc-g++,git,nc,nc6,python2-nacl,libsodium-common,libsodium-devel,dialog,figlet,rsync,gettext,autoconf,automake,binutils,cygport,gcc-core,make,lynx,zip,sshpass"
```


## 2.6. Install Python system pip packages

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


## 2.7. Configure your Git environment to work with github

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


# 3. Getting started for CentOS 7 minimum

After you have completed the previous sections, follow the next steps.


## 3.1. Clone and enter in the git root directory of this repository

Do the following tasks:

```bash
git clone git@github.com:cesarjorgemartinez/automate-virtual-machine-linux-images.git
cd automate-virtual-machine-linux-images
```


## 3.2. Get the software to work for this project

This software is *Packer*, *QEMU for Windows* and the **iso** image of **CentOS 7 minimum**. See the configuration files in [Configuration Directory](conf "Configuration Directory").

```bash
bin/getswandisoCentOS7Minimal.sh
```

A *QEMU for Windows* installer window appears and do the following:
- Please select a language: Select your language, as example `English / English`
- Click in OK
- Next
- I Agree
- Next
- Install
- Finish


## 3.3. Build the image

You need enter the username and userpass of the *Linux* admin account what is desired, and one optional parameter for the `cloud-init` default user (if this parameter is not provided then the default user is `cloud-user`.

```bash
bin/buildCentOS7Minimal.sh --adminuser adminuser --adminpass adminpass [--defaultclouduser defaultclouduser]
```

When finished the build then will create the image files **vmdk**, **ovf** and **qcow2** inside the images directory. See the configuration files in [Configuration Directory](conf "Configuration Directory").

The format name of the generated image files is as follows:

```bash
${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}.(vmdk|ovf|qcow2)
```

Example of **CentOS 7 minimum** configuration file:

```bash
# Variables to build Operating System
export PACKER_VERSION="1.4.5"
export PACKER_MACHINEREADABLEOUTPUT="False"
export PACKER_DEBUG="False"
export PACKER_SSH_TIMEOUT="50m"
export PACKER_TMP_DIR="${HOME_BASEDIR}/packer.d"
export VBOXPATH="/cygdrive/c/Program Files/Oracle/VirtualBox"
export QEMUPATH="/cygdrive/c/Program Files/qemu"
export PATH="${VBOXPATH}:${QEMUPATH}:${PATH}"
export SO_GUESTOSTYPE="RedHat_64"
# Values for hard_drive_interface are: ide sata or scsi
export SO_GUESTHDDINTERFACE="sata"
# Minimal or Desktop
export SO_IMAGETYPE="Minimal"
export SO_DISTRIBUTION="CentOS"
export SO_MAJORVERSION="7"
export SO_MINORVERSION="7"
export SO_NAMEVERSION="1908"
export SO_SHORTVERSION="${SO_MAJORVERSION}.${SO_MINORVERSION}"
export SO_FULLVERSION="${SO_SHORTVERSION}-${SO_NAMEVERSION}"
# Minimal or DVD
export SO_ISOTYPE="Minimal"
export SO_ISOIMAGENAME="${SO_DISTRIBUTION}-${SO_MAJORVERSION}-x86_64-${SO_ISOTYPE}-${SO_NAMEVERSION}.iso"
export SO_ISOURLIMAGE="http://ftp.uma.es/mirror/${SO_DISTRIBUTION}/${SO_MAJORVERSION}/isos/x86_64/${SO_ISOIMAGENAME}"
export SO_ISOSHA256SUMNAME="sha256sum.txt"
export SO_ISOCHECKSUMTYPE="sha256"
export SO_ISOURLSHA256SUM="http://ftp.uma.es/mirror/${SO_DISTRIBUTION}/${SO_MAJORVERSION}/isos/x86_64/${SO_ISOSHA256SUMNAME}"
export SO_BUILDDATE="$(date +%Y%m%d)"
export SO_VMFULLNAME="${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}"
```


## 3.4. Optionally upload to the OpenStack Image Store

If you have one *OpenStack virtualization environment*, you can upload the **qcow2** image file to the *OpenStack Image Store* (you need one appropiated virtualenv and environment variables defined and be registered in that *OpenStack*). These tasks are not related (TODO).

```bash
bin/uploadqcow2toopenstack.sh
```


## 3.5. Utility files used in this image

When build this image the following files in [Files for Centos7 Directory](files/CentOS7 "Files for Centos7 Directory") folder are installed and configured.

* **control-cloud-init.service**: Unit to control `cloud-init` to enable in *OpenStack* and disable in other virtualization systems. This unit calls the file `/usr/local/bin/control-cloud-init.sh`. Installed in `/etc/systemd/system/control-cloud-init.service`. See [control-cloud-init.service](files/CentOS7/control-cloud-init.service "control-cloud-init.service").

* **control-cloud-init.sh**: Process that controls `cloud-init` to enable in *OpenStack* and disable in other virtualization systems. Installed in `/usr/local/bin/control-cloud-init.sh`. See [control-cloud-init.sh](files/CentOS7/control-cloud-init.sh "control-cloud-init.sh").

* **guest-vmtools.service**: Unit to manage virtual machine tools for *VirtualBox*, *VMware* or *ESXI*. This unit calls the file `/usr/local/bin/guest-vmtools.sh`. Installed in `/etc/systemd/system/guest-vmtools.service`. See [guest-vmtools.service](files/CentOS7/guest-vmtools.service "guest-vmtools.service").

* **guest-vmtools.sh**: Process that install and configure the *GuestTools* for *VirtualBox* or *VMwareTools* for *VMware* or *ESXI*. Or remove these tools if boot in other virtual environments. Installed in `/usr/local/bin/guest-vmtools.sh`. See [guest-vmtools.sh](files/CentOS7/guest-vmtools.sh "guest-vmtools.sh").

* **hostinfo.sh**: Process that informs over basic properties of a host (CPU, memory, etc). Installed in `/usr/local/bin/hostinfo.sh`. See [hostinfo.sh](files/CentOS7/hostinfo.sh "hostinfo.sh").

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

* **switch-to-GraphicalUserInterface.sh**: Process that install and enable the `GNOME Display Manager` and set `Graphical Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-GraphicalUserInterface.sh`. See [switch-to-GraphicalUserInterface.sh](files/CentOS7/switch-to-GraphicalUserInterface.sh "switch-to-GraphicalUserInterface.sh").


* **switch-to-TextUserInterface.sh**: Process that disables (not uninstall) the `GNOME Display Manager` and set `Text Mode` as the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-TextUserInterface.sh`. See [switch-to-TextUserInterface.sh](files/CentOS7/switch-to-TextUserInterface.sh "switch-to-TextUserInterface.sh").


## 3.6. Virtual machine example in VirtualBox

Steps to use virtual machines using *VirtualBox*.


### 3.6.1. Import the virtualized service

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


### 3.6.2. Configure the virtual machine

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


### 3.6.3. Use the virtual machine

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
/usr/local/bin/hostinfo.sh
```

Switch to `Graphical User Interface` for this virtual machine:

```bash
sudo /usr/local/bin/switch-to-GraphicalUserInterface.sh
# Wait a bit to terminate this execution
sudo reboot
```


## 3.7. Convert vmdk image to work inside VMware ESXI

The image formats obtained **vmdk** or **ovf** are compatible with *VMware Workstation Player* but they are not compatible for *ESXI*.

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

Then you have an image imported into *VMware Workstation Player*. Here you need to choose the *ESXI* version reading the article <https://kb.vmware.com/s/article/1003746> and follow these steps:

- Enter in a *Cygwin64 session*.

- To get an image for *ESXI* version `6.0` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=11 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.7-1908-Minimal-20191115\CentOS7.7-1908-Minimal-20191115.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115-esx11.ovf'
```

- To get an image for *ESXI* version `6.5` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=13 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.7-1908-Minimal-20191115\CentOS7.7-1908-Minimal-20191115.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115-esx13.ovf'
```

- To get an image for *ESXI* version `6.7` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=14 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.7-1908-Minimal-20191115\CentOS7.7-1908-Minimal-20191115.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115-esx14.ovf'
```

- To get an image for *ESXI* version `6.7 U2` or `6.8.x` or `6.9.x` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=15 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.7-1908-Minimal-20191115\CentOS7.7-1908-Minimal-20191115.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.7-1908-Minimal-20191115-esx15.ovf'
```


# 4. Build other Operating Systems

Later, the builders for other Operating Systems will be coded or you can contribute to these builders (TODO).
