# Disclaimer!
Many thanks to [TheJames5's hiveos-pxe-diskless repository](https://github.com/TheJames5/hiveos-pxe-diskless). A lot of this project stems from a fork and fixes towards booting HiveOS diskless via PXE, which itself was forked from [panaceya's hiveos-pxe-diskless](https://github.com/panaceya/hiveos-pxe-diskless), originally forked from [minershive's hiveos-pxe-diskless](https://github.com/minershive/hiveos-pxe-diskless). Hiveon decided to change their support structure, charge more for usage, and not maintain or develop the code to work with their services.

## Support the Project and Donate.
If you found this helpful, please donate via [PayPal](https://www.paypal.com/donate/?business=PA3ZHF52483KW&no_recurring=1&item_name=Tech+Support+%2F+Health+%2F+Buy+Me+a+Coffee&currency_code=USD). You are free to edit, use, and distribute this code. Not all the code is my own work; it is a collection of contributions from many other projects to create a functional multi-purpose PXE server.

# Brief Overview:
This GitHub repository is focused on how to set up and install a generic PXE server. It provides a script and configuration for installing and setting up a PXE server on Debian Bookworm. I have included the process to grab and use the current repository to generate build tools for netbooting using Syslinux, GNU GRUB, and iPXE. Additionally, this repository contains a generic backup of my working PXE server, excluding HiveOS, Clonezilla Live, and boot.wim for WinPE. This system works by using a DHCP device with a next-boot setting and a DHCP option pointing to a TFTP server. We run a proxy DHCP server that boots into the EFI GRUB instance, where we can boot into iPXE and netboot other items as desired. I have found that building on Ubuntu instead of Debian breaks the pre-built binaries, and your PXE instance will not work. I have tested this, and it works with Ubiquiti Network's application by setting the PXE next boot to my system at `192.168.2.25` and the file to `/ipxe/boot.ipxe`, with TFTP also set to `192.168.2.25`. There are quite a few files that need to be updated when changing an IP address, from the PXE menu to the correct file mid-boot and server services. This PXE repository aims to alleviate that burden and help end users build a working PXE server from the host repository with pre-built binaries.

# Host Server Configuration:
- **Nginx:** Configured to serve PXE boot files with directory index listing enabled.
- **Samba:** Configured to share PXE-related directories.
- **TFTP:** Configured for network booting.
- **Dnsmasq:** Acts as the proxy DHCP server for PXE booting.

## PXE File Overview:
- **Syslinux:** Provides a lightweight and flexible bootloader for BIOS-based systems (older systems and motherboards before UEFI).
- **GNU GRUB:** A powerful bootloader that supports both BIOS and UEFI systems.
- **iPXE:** An advanced network bootloader that supports additional protocols and features.

In the PXE server, I made symlinks to all the host server files that we edit to make this server function. Please see the script-built folder structure for more details.

## Requirements:
- **Debian Bookworm** as the host OS
- **Internet connection** for downloading packages
- **PXE Menu Creation**
  - Understanding of Syslinux `menu.cfg`, GNU GRUB `grub.cfg`, and iPXE scripts.
- **Set a Static IP** to your host system!
  - It is a pain to edit and fix the IP address when it changes, as you need to maintain and fix multiple files, especially with a Hive diskless OS.
  - The `update_ip.sh` script is targeted at the host OS and its server, not the PXE boot menu configs.

# Installation
## Become root and move to the root home folder:
```
sudo su
cd /root
```
#install git if not already installed
```
apt-get install git
```
## Git clone the entire repository
```
git clone https://github.com/bmartino1/pxe.git
```
## Fix permission and set script executable
```
cd pxe
chmod 777 -R *
```
## run 1 of 2 scripts
```
./depends.sh
```

### Depends sh Script:
This script will install the applications needed to run this server. It will download the latest pre-built binaries, create a folder structure, and prompt the end user for the directory path and the IP address of the server. We will require a TFTP server, HTTP server, and Samba server in the end.

The default path is /pxeserver. A temporary file will be created in your home directory and moved into the default path if you choose to change the folder structure. Host server files are symlinked for easy access to easily edit host server settings outside of the bare minimum. The depends.sh script will call build.sh.

### Build sh Script:
This script sets the necessary server configs to run, we will also copy and build/make the necessary files for a uefi netboot pxe server and place them in the tftp folder.

Latter we can then edit menu.cfg for bios pxe, and grub.cfg to edit the efi grub pxe boot menu. even later we will add a grub chain boot option to run a boot.ipxe script for netboot via http

# Warning
Please use Debian Bookworm OS as the host. I have found that there are issues with Syslinux/GNU GRUB depending on the base OS you use when building from binary!

You may experience a broken PXE server; it will still attempt to boot, but you may encounter NBD download errors or a hard stop at "Welcome to GRUB" with no further progress. I can only assume this is due to host OS library calls when built. For this reason, Debian is recommended to maintain security and longevity. The scripts are pointed to the Debian repository for files to build the PXE server.
