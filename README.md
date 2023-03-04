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
   - [1.2. Tested software versions](#12-tested-software-versions)
- [2. Operating Systems that can be built](#2-operating-systems-that-can-be-built)
- [3. Create and configure the environment](#3-create-and-configure-the-environment)
   - [3.1. Install VirtualBox](#31-install-virtualbox)
   - [3.2. Install VMware Workstation Player](#32-install-vmware-workstation-player)
   - [3.3. Install CygWin 64 bits](#33-install-cygwin-64-bits)
   - [3.4. Disable Windows Python installation](#34-disable-windows-python-installation)
   - [3.5. Install needed CygWin packages](#35-install-needed-cygwin-packages)
   - [3.6. Install Python system pip packages](#36-install-python-system-pip-packages)
   - [3.7. Configure your Git environment to work with github](#37-configure-your-git-environment-to-work-with-github)
   - [3.8. Howto generate SHA-512 password hashes with Python3 in CygWin command line](#38-howto-generate-sha-512-password-hashes-with-python3-in-cygwin-command-line)
- [4. Getting started](#4-getting-started)
   - [4.1. Clone and enter into the git root directory of this repository](#41-clone-and-enter-into-the-git-root-directory-of-this-repository)
   - [4.2. Install QEMU for Windows](#42-install-qemu-for-windows)
- [5. Build CentOS 7 Minimal image](#5-build-centos-7-minimal-image)
- [6. Build CentOS 8 Minimal image](#6-build-centos-8-minimal-image)
- [7. Build Ubuntu 20 Minimal image](#7-build-ubuntu-20-minimal-image)

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

To work with this software you need **Windows 10 64 bits** and **CygWin 64 bits** to use **Linux-Bash** commands.


## 1.2. Tested software versions

This project has been tested with the following software versions:

- **Windows**: `10 64 bits updated`
- **VirtualBox**: `6.1.16`
- **CygWin 64 bits**: `64 bits 3.1.7(0.340/5/3)`
- **QEMU for Windows**: `qemu-w64-setup-20201124 qemu-img version 5.1.92 (v5.2.0-rc2-11843-gf571c4ffb5-dirty)`
- **VMware Workstation Player**: `16.1.0 build-17198959`
- **VMware ESXI**: `6.5` and `6.7`
- **OpenStack** (`curl https://<identity_endpoint>:13000/v3`): `3.7 Newton`
- **Nutanix**: `community edition 5.18`


# 2. Operating Systems that can be built

Actually you can build the following Operating Systems:

- **CentOS 7 Minimal**: `CentOS 7.9 (2009)`
- **CentOS 8 Minimal**: `CentOS 8.2 (2004)` and `CentOS 8.3 (2011)`
- **Ubuntu 20 Minimal**: `Ubuntu 20.04.1 (server)`


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
echo $'PATH=$(echo $PATH | tr \':\' \'\\n\' | grep -v "/cygdrive/.*/Python[23]" | paste -sd:)' >> .bash_profile
exit
```


## 3.5. Install needed CygWin packages

You need to do the following tasks:

- Enter in a *Cygwin64 session*.
- Launch this:
```bash
curl -O https://cygwin.com/setup-x86_64.exe
./setup-x86_64.exe -q --upgrade-also --packages="bash,python2,python2-devel,python2-setuptools,python2-crypto,python2-paramiko,python2-boto,python2-certifi,python2-pip,python2-nacl,python3,python3-devel,python38,python38-devel,openssl,openssh,openssl-devel,libffi-devel,gcc-g++,git,nc,nc6,libsodium-common,libsodium-devel,dialog,figlet,rsync,gettext,autoconf,automake,binutils,cygport,gcc-core,make,lynx,zip,sshpass,jq,expect,procps-ng"
```


## 3.6. Install Python system pip packages

To work with *Python* install basic *pip* packages in a system level:

TODO: Check if this tasks are obsoleted using last CygWin version. In a existing CygWin installation is not necessary.

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


## 3.8. Howto generate SHA-512 password hashes with Python3 in CygWin command line

To generate `SHA-512` password hashes you need to do the following tasks:

- Enter in a *Cygwin64 session*.

- Launch this command where `password` is the plain text password:

```bash
python3 -c 'import crypt; print(crypt.crypt("password", crypt.mksalt(crypt.METHOD_SHA512)))'
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

This section explains howto build this *Virtual Machine Image*: [Build CentOS 7 Minimal image](Build-CentOS-7-Minimal-image.md "Build CentOS 7 Minimal image").


# 6. Build CentOS 8 Minimal image

This section explains howto build this *Virtual Machine Image*: [Build CentOS 8 Minimal image](Build-CentOS-8-Minimal-image.md "Build CentOS 8 Minimal image").


# 7. Build Ubuntu 20 Minimal image

This section explains howto build this *Virtual Machine Image*: [Build Ubuntu 20 Minimal image](Build-Ubuntu-20-Minimal-image.md "Build Ubuntu 20 Minimal image").
