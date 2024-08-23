# Disclaimer!
Many Thanks to https://github.com/TheJames5/hiveos-pxe-diskless alot and most of this stems forma  fork and fix towards booting hive diskless pxe
with is forked form https://github.com/panaceya/hiveos-pxe-diskless a fork from https://github.com/minershive/hiveos-pxe-diskless wher hiveon decided to chage ther support structure cahrge more to use and not maintin nor devlop the code to still work for ther servces...

## Support the Project and Donate.
If you found this help full please donate to https://www.paypal.com/donate/?business=PA3ZHF52483KW&no_recurring=1&item_name=Tech+Support+%2F+Health+%2F+Buy+Me+a+Coffee&currency_code=USD
You are free to edit use and distrubit this code. Not all code is my works but the collected works of many other projects to have a working multi-functional pxe server.

# Brief Overview:
This Git Repo is more on How to setup and install a generic PXE Server...
This pxe repository provides a script and configuration for install and setting up PXE server on Debian Bookworm. I have includes the process to grab and use the curent repository generate build tools for netbooting using Syslinux, GNU GRUB, and iPXE. a generic backup of my working pxe serve as well mising the hive stuff, clonezil live, and boot.wim fro win pe. This system works by a dhcp device using nextboot and setting a dhcp option to a tftp server. We run a prxy dhcp server that boots to the efi grub instance, here we can boot to ipxe and netboot other items if so desired... I have found that building on ubuntu over deabin breaks the pre builts and your pxe instance will not work. I have tested this and it works with unif netwrok application setting the pxe next boot to my system 192.168.2.25 and file /ipxe/boot.ipxe and setting tftp to 192.168.2.25... ther area quire a few files when changing a ip address. from the pxe menu to point to the correct file mid boot and server services. This pxe repo aims to help elivate that and help end users build a working pxe form the host repository bre-built binaries...

# Host Serve Configuration
Nginx: Configured to serve PXE boot files with directory index listing enabled.
Samba: Configured to share PXE-related directories.
TFTP: Configured for network booting.
Dnsmasq: the proxy dhcp server for pxe booting.

Pxe file Overview:
Syslinux: Provides a lightweight and flexible bootloader for BIOS-based systems. (old sytems and motherboards before uefi)
GNU GRUB: A powerful bootloader that supports both BIOS and UEFI systems.
iPXE: An advanced network bootloader that supports additional protocols and features.

In pxe server i made symlinks to all the host server files we edit to make this server function...
please see script built folders structure

## Requirements:
Debian Bookworm as host OS
Internet connection for downloading packages
***Pxe Menu Creation***
Understanding of syslinux menu.cfg, gnu grub grub.cfg, and ipxe scripts...
***Set a Static IP to your host system!**
It is a Pain to edit and fix the ip address when it changes to maintin and fix mutiple files. this especail with a hive diskless os...
the update ip scripe is targted to the host os and its sserver, not the PXE boot menu configs. 

# Installation
## Become root and move to root home folder...
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
./depends.sh

### Depends sh Script:
this script will install the applicaiton needed to run this server. it will downladed the lattest prebuilt binary and create a folder structure and prombt the end users on where to store and the ip address of the server.
we will require a tftp server, http server, and samba server in the end....

default path is /pxeserver 
a temp file will be create at your Home direectoy and moved into the default path if you chose to change the folder structure.
host server files are symlinked for easy access as to waht to easily edit to set host server settings outside of the bare min.
depends will call build.sh

### Build sh Script:
This script sets the necessary server configs to run, we will also copy and build/make the necessary files for a uefi netboot pxe server and place them in the tftp folder.

Latter we can then edit menu.cfg for bios pxe, and grub.cfg to edit the efi grub pxe boot menu. even later we will add a grub chain boot option to run a boot.ipxe script for netboot via http

# Warning
Please Use Debain Bookworm OS as host. I have found that there is a isseus with syslinux/gnu grub dependaing on what base OS you have when building form binary! 

You may experience a broken PXE server, as it will still try to boot, but you will get NBD downloaded and or a hard stop at Welcome to Grub and nothing more... I can only assume its due to Host OS libary calls when built... For this reason Debain is recomend to amintain security and longevty. script are pointed to teh debian reposiotry for filles to build the pxe server...

