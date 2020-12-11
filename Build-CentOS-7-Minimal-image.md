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

- [1. Build CentOS 7 Minimal image](#1-build-centos-7-minimal-image)
   - [1.1. Download and install Packer](#11-download-and-install-packer)
   - [1.2. Download the iso image](#12-download-the-iso-image)
   - [1.3. Build the image](#13-build-the-image)
   - [1.4. Optionally upload to the OpenStack Image Store](#14-optionally-upload-to-the-openstack-image-store)
   - [1.5. Utility files used in this image](#15-utility-files-used-in-this-image)
   - [1.6. Virtual machine example in VirtualBox](#16-virtual-machine-example-in-virtualbox)
      - [1.6.1. Import the virtualized service](#161-import-the-virtualized-service)
      - [1.6.2. Configure the virtual machine](#162-configure-the-virtual-machine)
      - [1.6.3. Use the virtual machine](#163-use-the-virtual-machine)
   - [1.7. Convert vmdk image to work inside VMware ESXI](#17-convert-vmdk-image-to-work-inside-vmware-esxi)

<!-- /MDTOC -->


# 1. Build CentOS 7 Minimal image

This section explains howto build this *Virtual Machine Image*.


## 1.1. Download and install Packer

To build the image you need to download and install *Packer* software.

The directory where it install this software is `CentOS7Minimal/packer-software`.

The version is determined by its own configuration file located at [CentOS7Minimal Configuration Directory](CentOS7Minimal/conf/virtual-machine.conf "CentOS7Minimal Configuration Directory").

To perform this task run:

```bash
CentOS7Minimal/bin/download-and-install-packer.sh
```


## 1.2. Download the iso image

To build the image you need to download the **iso** files for this *Operating System*.

The directory where it download this **iso** files is `isos` at home of this repository.

The version is determined by its own configuration file located at [CentOS7Minimal Configuration Directory](CentOS7Minimal/conf/virtual-machine.conf "CentOS7Minimal Configuration Directory").

To perform this task run:

```bash
CentOS7Minimal/bin/download-iso.sh
```


## 1.3. Build the image

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
export PACKER_VERSION="1.6.5"
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
export SO_MINORVERSION="9"
export SO_NAMEVERSION="2009"
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
# The time to wait after booting the initial virtual machine before typing the boot_command
export SO_BOOT_WAIT="10s"
```


## 1.4. Optionally upload to the OpenStack Image Store

If you have one *OpenStack virtualization environment*, you can upload the **qcow2** image file to the *OpenStack Image Store*.

To do the upload you need one appropiated virtualenv and environment variables defined and be registered in that *OpenStack virtualization environment* and launch:

```bash
CentOS7Minimal/bin/upload-qcow2-to-openstack.sh
```


## 1.5. Utility files used in this image

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
  eth0              08:00:27:fc:3e:83 192.168.56.142/24                             fe80::a00:27ff:fefc:3e83/64
  eth1              08:00:27:38:99:ed 10.0.3.15/24                                  fe80::a00:27ff:fe38:99ed/64
  CPU TOTAL..........: 1
  CPU ONLINE.........: 1
  MEMORY.............:
                total        used        free      shared  buff/cache   available
  Mem:           990M        141M        246M         12M        603M        683M
  Swap:          2.0G          0B        2.0G
  FILESYSTEMS........:
  Filesystem                      Size  Used Avail Use% Mounted on
  devtmpfs                        485M     0  485M   0% /dev
  tmpfs                           496M     0  496M   0% /dev/shm
  tmpfs                           496M   13M  483M   3% /run
  tmpfs                           496M     0  496M   0% /sys/fs/cgroup
  /dev/mapper/centos_centos-root   37G  895M   37G   3% /
  /dev/sda1                      1014M   69M  946M   7% /boot
  tmpfs                           100M     0  100M   0% /run/user/1000
  /dev/loop0                       59M   59M     0 100% /mnt/VBoxGuestAdditionsISO
  tmpfs                           100M     0  100M   0% /run/user/0
  SYSTEM UPTIME......: 12:58:05 up 1 min, 2 users, load average: 1.04, 0.31, 0.11
  RELEASE............: CentOS Linux 7 (Core)
  KERNEL.............: 3.10.0-1160.6.1.el7.x86_64
  DATE...............: Fri Dec 11 12:58:05 CET 2020
  USERS..............: Currently 2 user(s) logged on
  CURRENT USER.......: adminuser
  PROCESSES..........: 143 running
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
  CPU MHz:               1800.000
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


## 1.6. Virtual machine example in VirtualBox

Steps to use virtual machines using *VirtualBox*.


### 1.6.1. Import the virtualized service

To import virtualized service in *VirtualBox* to create a virtual machine perform the following steps using the `Oracle VM VirtualBox Administrator`.

- Click in `Archive -> Import virtualized service...`
- Click in `Select a virtualized service file to import...` in `Service to import`. Example `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211.ovf`
- Name: `myvm`
- Type of guest OS: `Red Hat (64-bit)`
- CPU: `1`
- RAM: `1024 MB`
- Storage Controller (SATA) -> Virtual Disk Image: `myvm.vmdk`
- MAC address policy: `Generate new MAC addresses for all network adapters`
- Additional options: `Import disks as VDI`
- Click in `Import` button


### 1.6.2. Configure the virtual machine

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


### 1.6.3. Use the virtual machine

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


## 1.7. Convert vmdk image to work inside VMware ESXI

The image formats obtained **vmdk** or **ovf** are compatible with *VMware Workstation Player* but they are not compatible for *VMware ESXI*.

For this reason you need to use *VMware Workstation Player* for Windows to obtain a compatible virtual machine.

Then follow these steps:

- Open *VMware Workstation Player*
- Click in `Player->File->Open...` and select the **ovf** file `C:\cygwin64\home\user\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211.ovf`
- Name for the new virtual machine: `CentOS7.9-2009-Minimal-20201211`
- Storage path for the new virtual machine: `C:\VMware\CentOS7.9-2009-Minimal-20201211`
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

- To get an image for *VMware ESXI* version `5.5, HW version 10` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=10 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.9-2009-Minimal-20201211\CentOS7.9-2009-Minimal-20201211.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211-esx10.ovf'
```

- To get an image for *VMware ESXI* version `6.0, HW version 11` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=11 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.9-2009-Minimal-20201211\CentOS7.9-2009-Minimal-20201211.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211-esx11.ovf'
```

- To get an image for *VMware ESXI* version `6.5, HW version 13` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=13 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.9-2009-Minimal-20201211\CentOS7.9-2009-Minimal-20201211.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211-esx13.ovf'
```

- To get an image for *VMware ESXI* version `6.7, HW version 14` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=14 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.9-2009-Minimal-20201211\CentOS7.9-2009-Minimal-20201211.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211-esx14.ovf'
```

- To get an image for *VMware ESXI* version `6.7 U2, HW version 15` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=15 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.9-2009-Minimal-20201211\CentOS7.9-2009-Minimal-20201211.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211-esx15.ovf'
```

- To get an image for *VMware ESXI* version `7.0  (7.0.0), HW version 17` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=17 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.9-2009-Minimal-20201211\CentOS7.9-2009-Minimal-20201211.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211-esx17.ovf'
```

- To get an image for *VMware ESXI* version `7.0 U1 (7.0.1), HW version 18` launch:

```
'/cygdrive/c/Program Files (x86)/VMware/VMware Player/OVFTool/ovftool' --lax --sourceType=VMX --targetType=OVF --diskMode=thin --maxVirtualHardwareVersion=18 --skipManifestCheck --skipManifestGeneration 'C:\VMware\CentOS7.9-2009-Minimal-20201211\CentOS7.9-2009-Minimal-20201211.vmx' 'C:\cygwin64\home\'${USERNAME}'\automate-virtual-machine-linux-images\images\CentOS7.9-2009-Minimal-20201211-esx18.ovf'
```
