<h1><center>Automate Virtual Machine Images</center></h1>
<br>
<h4><center>Author: Cesar Jorge Martínez</center></h4>
<br>

**Read the LICENSE [GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007](LICENSE "GNU AFFERO GENERAL PUBLIC LICENSE Version 3, 19 November 2007")**
<br>

<h2>Index</h2>
<!-- MDTOC maxdepth:6 firsth1:1 numbering:0 flatten:0 bullets:1 updateOnSave:0 -->

- [1. Introduction](#1-introduction)

<!-- /MDTOC -->


# 1. Introduction #
This project helps to build automatically *Virtual Machine Images of Operating Systems* that are **compatible** with different virtualization systems, as *OpenStack* (*kvm*), *VirtualBox*, *VMware*, *Hyper-V*, etc.

You can deploy and boot directly these images in these virtualization systems without doing anything special or extra thanks to the use of two *systemd* units:
- **control-cloud-init.service**: By default the cloud-init units are enabled. But if the Virtual Machine boots inside *VirtualBox* or *VMware*, then disable the cloud-init units.
- **guest-vmtools.service**: If the Virtual Machine boots inside *VirtualBox* then install its *GuestTools* disabling others. Same behavihour for *VMware* and *OpenStack*.

For now you can only build an image of **CentOS 7 minimum**, ideal to work as servers in *Cloud*, *traditional* or *development* environments, and is very useful to work with **Docker**, because the size of the image created is very small.

To work with this software you need **Windows 64 bits** and **CygWin 64 bits** to use **Linux-Bash** commands.


# 2. Prepare the CygWin and Git environment #
You need to do the following tasks.

1. First you need to install **CygWin 64 bits**.
   - With a browser download <https://cygwin.com/setup-x86_64.exe> and install this software. Use a mininal installation.

2. To prevent that *CygWin* use the *Python* installed in *Windows* (if exist), do the following to disable access to *Windows Python installation*:
   - Enter in a *Cygwin64 session*.
   - Launch this:
```bash
echo $'PATH=$(echo $PATH | tr \':\' \'\\n\' | grep -v "/cygdrive/.*/Python27" | paste -sd:)' >> .bash_profile
exit
```

3. Install these packages.
   - Enter in a *Cygwin64 session*.
   - Launch this:
```bash
curl https://cygwin.com/setup-x86_64.exe -o setup-x86_64.exe
./setup-x86_64.exe -q --packages bash python python-devel python-setuptools openssl openssh openssl-devel libffi-devel gcc-g++ git
```

4. Also optionally install the following packages if need to use *sshpass*.
   - Enter in a *Cygwin64 session*.
   - Launch this:
```bash
./setup-x86_64.exe -q --packages bash rsync gettext autoconf automake binutils cygport gcc-core make
# Build sshpass
curl -L https://downloads.sourceforge.net/project/sshpass/sshpass/1.06/sshpass-1.06.tar.gz -o sshpass-1.06.tar.gz
tar -zxf sshpass-1.06.tar.gz
cd sshpass-1.06
./configure
make && make install
```

5. Install *Python* base *pip* packages.
   - Enter in a *Cygwin64 session*.
   - Launch this:
```bash
easy_install-2.7 pip
pip install --upgrade pip
pip install --upgrade setuptools
pip install --upgrade wheel
pip install virtualenv
```

6. Configure your *Git* environment to work with <https://github.com>. Example to use *Git* with *SSH*.
   - Get your public and private *SSH keys* of your *github account*.
   - Enter in a *Cygwin64 session*:
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


# 3. Getting stated #
After you have completed the previous section, follow the next steps.

1. Clone this repository and enter in its git root directory.
```bash
git clone git@github.com:cesarjorgemartinez/automatevmimages.git
cd automatevmimages
```

2. Get the base software for this project (*Packer*, *QEMU for Windows*, and the **iso** image of **CentOS 7 minimum**).
```bash
bin/getswandisoCentOS7Minimal.sh
```

3. Build the image.
```bash
bin/buildCentOS7Minimal.sh
```

4. When finished the build then will create three files (**vmdk**, **ovf** and **ova** files) inside the images directory. See the configuration files in [Configuration Directory](conf "Configuration Directory").
   - The format of the generated files is as follows:
```bash
${SO_DISTRIBUTION}${SO_SHORTVERSION}-${SO_NAMEVERSION}-${SO_IMAGETYPE}-${SO_BUILDDATE}
```
   - Content of **CentOS 7 minimum** configuration file.
```bash
# Variables to build Operationg System
export PACKER_VERSION="1.1.3"
export PACKER_MACHINEREADABLEOUTPUT="False"
export PACKER_DEBUG="False"
export QEMUIMG_VERSION="2.3.0"
export SO_GUESTOSTYPE="RedHat_64"
# Minimal or Desktop
export SO_IMAGETYPE="Minimal"
export SO_DISTRIBUTION="CentOS"
export SO_MAJORVERSION="7"
export SO_MINORVERSION="4"
export SO_NAMEVERSION="1708"
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

5. Convert the image to other formats (saved inside the images directory).
   - **qcow2**
   - **vdi**
   - **vhd dynamic**
   - **vhdx dynamic**
   - And optionally according to the variable `SO_CONVERTFIXED_VHD_VHDX_IMAGES` (by default is set to false):
      - **vhd fixed**
      - **vhdx fixed**
```bash
bin/convertCentOS7Minimal.sh
```

6. Optionally if you have one *OpenStack virtualization environment*, you can upload the **qcow2** image file to the *OpenStack Image Store*.
```bash
bin/uploadqcow2toopenstack.sh
```


# 4. Build other Operationg Systems #
Later, the builders for other Operating Systems will be coded or you can contribute to these builders.
