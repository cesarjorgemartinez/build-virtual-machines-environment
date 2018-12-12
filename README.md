<h1><center><b>Automate Virtual Machine Images</b></center></h1>
<br>

**Author: Cesar Jorge Martínez**
<br>

**Site: <https://cesarjorgemartinez.github.io/automatevmimages>**
<br>

**Read the LICENSE [GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007](LICENSE "GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007")**
<br>

<h2>Index</h2>
<!-- MDTOC maxdepth:6 firsth1:1 numbering:0 flatten:0 bullets:1 updateOnSave:0 -->

- [1. Introduction](#1-introduction)
- [2. Prepare the CygWin and Git environment](#2-prepare-the-cygwin-and-git-environment)
   - [2.1. Install CygWin 64 bits](#21-install-cygwin-64-bits)
   - [2.2. Disable Windows Python installation](#22-disable-windows-python-installation)
   - [2.3. Install needed packages](#23-install-needed-packages)
   - [2.4. Optionally tasks if need to use sshpass](#24-optionally-tasks-if-need-to-use-sshpass)
   - [2.5. Install Python system pip packages](#25-install-python-system-pip-packages)
   - [2.6. Configure your Git environment to work with github](#26-configure-your-git-environment-to-work-with-github)
- [3. Getting stated for CentOS 7 minimum](#3-getting-stated-for-centos-7-minimum)
   - [3.1. Clone this repository](#31-clone-this-repository)
   - [3.2. Enter your git root directory](#32-enter-your-git-root-directory)
   - [3.3. Get the base software to work for this project](#33-get-the-base-software-to-work-for-this-project)
   - [3.4. Build the image](#34-build-the-image)
   - [3.5. Convert the image to other formats](#35-convert-the-image-to-other-formats)
   - [3.6. Optionally upload to the OpenStack Image Store](#36-optionally-upload-to-the-openstack-image-store)
   - [3.7. Utility files used in this image](#37-utility-files-used-in-this-image)
- [4. Build other Operationg Systems](#4-build-other-operationg-systems)

<!-- /MDTOC -->


# 1. Introduction #
This project helps to build automatically *Virtual Machine Images of Operating Systems* that are **compatible** with different virtualization systems, as *OpenStack* (*kvm*), *VirtualBox*, *VMware*, *Hyper-V*, etc.

You can deploy and boot directly these images in these virtualization systems without doing anything special or extra, thanks to the use of two *systemd* units:
- **control-cloud-init.service**: By default the cloud-init units are enabled. But if the Virtual Machine boots inside *VirtualBox* or *VMware*, then disable the cloud-init units.
- **guest-vmtools.service**: If the Virtual Machine boots inside *VirtualBox* then install its *GuestTools* disabling others. Same behavihour for *VMware* and *OpenStack*.

For now you can only build an image of **CentOS 7 minimum**, ideal to work as servers in *Cloud*, *traditional* or *development* environments, and is very useful to work with **Docker**, because the size of the image created is very small. This image is builded with a *Linux* admin account provided as parameter at the time of build. The cloud-init use other account provided as optional parameter at the time of build (not created because the cloud-init do this work at the first boot of the virtual machine) that by default is *cloud-user*.

To work with this software you need **Windows 7 or 10 for 64 bits** and **CygWin 64 bits** to use **Linux-Bash** commands.


# 2. Prepare the CygWin and Git environment #
You need to do the following tasks.


## 2.1. Install CygWin 64 bits ##
To use **CygWin 64 bits** you need to do the following tasks:

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


## 2.2. Disable Windows Python installation ##

To prevent that *CygWin* use the *Python* installed in *Windows* (if exist), do the following to disable access to *Windows Python installation*:

- Enter in a *Cygwin64 session*.
- Launch this:
```bash
echo $'PATH=$(echo $PATH | tr \':\' \'\\n\' | grep -v "/cygdrive/.*/Python[23]7" | paste -sd:)' >> .bash_profile
exit
```


## 2.3. Install needed packages ##
You need to install the following packages.
- Enter in a *Cygwin64 session*.
- Launch this:
```bash
curl -O https://cygwin.com/setup-x86_64.exe
./setup-x86_64.exe -q --packages="bash,python,python-devel,python-setuptools,openssl,openssh,openssl-devel,libffi-devel,gcc-g++,git"
```


## 2.4. Optionally tasks if need to use sshpass ##
Follow the next tasks.
- Enter in a *Cygwin64 session*.
- Launch this:
```bash
./setup-x86_64.exe -q --packages="bash,rsync,gettext,autoconf,automake,binutils,cygport,gcc-core,make"
# Build sshpass
curl -L https://sourceforge.net/projects/sshpass/files/latest/download -o sshpass.tar.gz
tar zxf sshpass.tar.gz
cd sshpass-1.06
./configure
make && make install
```


## 2.5. Install Python system pip packages ##
To work with *Python*, it install *pip*, *setuptools*, *wheel* and *virtualenv* in a system level.
- Enter in a *Cygwin64 session*.
- Launch this:
```bash
easy_install-2.7 pip
pip install --upgrade pip
pip install --upgrade setuptools
pip install --upgrade wheel
pip install virtualenv
```


## 2.6. Configure your Git environment to work with github ##
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


# 3. Getting stated for CentOS 7 minimum #
After you have completed the previous sections, follow the next steps.


## 3.1. Clone this repository ##
Clone this repository.
```bash
git clone git@github.com:cesarjorgemartinez/automatevmimages.git
```


## 3.2. Enter your git root directory ##
To launch commands you need to enter your git root directory.
```bash
cd automatevmimages
```


## 3.3. Get the base software to work for this project ##
This software is *Packer*, *QEMU for Windows*, and the **iso** image of **CentOS 7 minimum**.
```bash
bin/getswandisoCentOS7Minimal.sh
```


## 3.4. Build the image ##
You need enter the username and userpass of the *Linux* admin account what is desired, and one optional parameter for the cloud-init default user (if this parameter is not provided then the default user is `cloud-user`.
```bash
bin/buildCentOS7Minimal.sh --adminuser adminuser --adminpass adminpass [--defaultclouduser defaultclouduser]
```

When finished the build then will create three files (**vmdk**, **ovf** and **ova** files) inside the images directory. See the configuration files in [Configuration Directory](conf "Configuration Directory").

The base format of the generated files (and extensions **.vmdk** or **.ovf** or **.ova**) is as follows:
```bash
${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}
```

Content of **CentOS 7 minimum** configuration file.
```bash
# Variables to build Operationg System
export PACKER_VERSION="1.3.1"
export PACKER_MACHINEREADABLEOUTPUT="False"
export PACKER_DEBUG="False"
export PACKER_SSH_WAIT_TIMEOUT="50m"
export QEMUIMG_VERSION="2.3.0"
export SO_GUESTOSTYPE="RedHat_64"
# Minimal or Desktop
export SO_IMAGETYPE="Minimal"
export SO_DISTRIBUTION="CentOS"
export SO_MAJORVERSION="7"
export SO_MINORVERSION="5"
export SO_NAMEVERSION="1804"
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
export SO_CONVERTFIXED_VHD_VHDX_IMAGES="false"
```


## 3.5. Convert the image to other formats ##
The previous process creates **vmdk**, **ovf** and **ova** files. If you need the image in other formats (**qcow2**, **vdi**, **vhd** and **vhdx**) then launch this converter. The converted images are saved inside the images directory.
```bash
bin/convertCentOS7Minimal.sh
```

List of formats:
- **qcow2**: baseformat.qcow2
- **vdi**: baseformat.vdi
- **vhd dynamic**: baseformat-dynamic.vhd
- **vhdx dynamic**: baseformat-dynamic.vhdx
- And optionally according to the variable `SO_CONVERTFIXED_VHD_VHDX_IMAGES` (by default is set to false):
   - **vhd fixed**: baseformat-fixed.vhd
   - **vhdx fixed**: baseformat-fixed.vhdx


## 3.6. Optionally upload to the OpenStack Image Store ##
If you have one *OpenStack virtualization environment*, you can upload the **qcow2** image file to the *OpenStack Image Store* (you need one appropiated virtualenv and environment variables defined and be registered in that *OpenStack*). These tasks are not related (TODO).
```bash
bin/uploadqcow2toopenstack.sh
```


## 3.7. Utility files used in this image ##
When build this image, automatically the following files in [Files for Centos7 Directory](files/CentOS7 "Files for Centos7 Directory") folder are installed and configured.

* **control-cloud-init.service**: Systemd Unit to control cloud-init to enable in OpenStack and disable in VMware or VirtualBox. This service calls the file `/usr/local/bin/control-cloud-init.sh`. Installed in `/etc/systemd/system/control-cloud-init.service`. See [control-cloud-init.service](files/CentOS7/control-cloud-init.service "control-cloud-init.service").

* **control-cloud-init.sh**: Process that controls cloud-init to enable in OpenStack and disable in VMware or VirtualBox. Installed in `/usr/local/bin/control-cloud-init.sh`. See [control-cloud-init.sh](files/CentOS7/control-cloud-init.sh "control-cloud-init.sh").

* **guest-vmtools.service**: Manage virtual machine tools for OpenStack or VMware or VirtualBox. This service calls the file `/usr/local/bin/guest-vmtools.sh`. Installed in `/etc/systemd/system/guest-vmtools.service`. See [guest-vmtools.service](files/CentOS7/guest-vmtools.service "guest-vmtools.service").

* **guest-vmtools.sh**: Process that install/configure certain tasks for OpenStack or VMware or VirtualBox (Install and update the Guest Tools for VMware or VirtualBox, or remove these tools if use OpenStack). Installed in `/usr/local/bin/guest-vmtools.sh`. See [guest-vmtools.sh](files/CentOS7/guest-vmtools.sh "guest-vmtools.sh").

* **hostinfo.sh**: Process that informs over basic properties of a host (CPU, memory, etc). Installed in `/usr/local/bin/hostinfo.sh`. See [hostinfo.sh](files/CentOS7/hostinfo.sh "hostinfo.sh").

  Execution example:
  ```bash
  [sysadmin@host ~]$ /usr/local/bin/hostinfo.sh
  ===========================================================================
  HOSTNAME...........: ripley
  INTERFACES.........:
  Interface         MAC Address       IP4 Address                                   IP6 Address
  enp0s3            08:08:08:08:08:08 1.2.3.4/24                                    fe80::a00:eeee:eeee:eeee/64
  enp0s8            09:09:09:09:09:09 10.20.30.40/24                                fe80::a00:ffff:ffff:ffff/64
  CPU CORES..........: 1
  MEMORY.............:
                total        used        free      shared  buff/cache   available
  Mem:           1.6G        876M        576M        4.0M        202M        604M
  Swap:          3.0G        443M        2.6G
  FILESYSTEMS........:
  Filesystem               Size  Used Avail Use% Mounted on
  /dev/mapper/centos-root   37G   14G   24G  37% /
  devtmpfs                 812M     0  812M   0% /dev
  tmpfs                    828M  316K  828M   1% /dev/shm
  tmpfs                    828M  1.4M  827M   1% /run
  tmpfs                    828M     0  828M   0% /sys/fs/cgroup
  /dev/sda1                497M  254M  244M  51% /boot
  tmpfs                    166M  8.0K  166M   1% /run/user/42
  tmpfs                    166M   32K  166M   1% /run/user/1000
  SYSTEM UPTIME......: 13:37:44 up 4:24, 7 users, load average: 3.66, 2.70, 2.85
  RELEASE............: CentOS Linux release 7.5.1804 (Core)
  KERNEL.............: 3.10.0-862.11.6.el7.x86_64
  DATE...............: Mon Sep 24 13:37:44 CEST 2018
  USERS..............: Currently 7 user(s) logged on
  CURRENT USER.......: sysadmin
  PROCESSES..........: 213 running
  ===========================================================================
  ```

* **switch-to-GraphicalUserInterface.sh**: Process that install and enable the GNOME Display Manager and set Graphical the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-GraphicalUserInterface.sh`. See [switch-to-GraphicalUserInterface.sh](files/CentOS7/switch-to-GraphicalUserInterface.sh "switch-to-GraphicalUserInterface.sh").


* **switch-to-TextUserInterface.sh**: Process that disables (not uninstall) the GNOME Display Manager and set Text the default login. After finish, you need to reboot this host to apply these changes (`sudo shutdown -r now`). Installed in `/usr/local/bin/switch-to-TextUserInterface.sh`. See [switch-to-TextUserInterface.sh](files/CentOS7/switch-to-TextUserInterface.sh "switch-to-TextUserInterface.sh").


# 4. Build other Operationg Systems #
Later, the builders for other Operating Systems will be coded or you can contribute to these builders (TODO).
