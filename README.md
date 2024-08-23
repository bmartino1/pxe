# WIP

PXE Server Setup
This repository provides a script and configuration for setting up a PXE server on Debian Bookworm. It includes tools for netbooting using Syslinux, GNU GRUB, and iPXE.

Overview
Syslinux: Provides a lightweight and flexible bootloader for BIOS-based systems.
GNU GRUB: A powerful bootloader that supports both BIOS and UEFI systems.
iPXE: An advanced network bootloader that supports additional protocols and features.
Requirements
Debian Bookworm
Internet connection for downloading packages
Installation
Clone the Repository

bash
Copy code
git clone https://github.com/yourusername/your-repository.git
cd your-repository
Run the Dependencies Script

bash
Copy code
./depends.sh
This script installs necessary packages and sets up the server configurations.

Run the Build Script

bash
Copy code
./build.sh
This script builds and configures the PXE server.

Configuration
Nginx: Configured to serve PXE boot files with directory index listing enabled.

Samba: Configured to share PXE-related directories.

TFTP: Configured for network booting.

Resources
Syslinux: Official Syslinux documentation and source code.
GNU GRUB: GNU GRUB bootloader documentation.
iPXE: iPXE documentation and source code.
Troubleshooting
If you encounter issues, ensure that:

All services (Nginx, Samba, TFTP) are running.
The configurations in /etc/dnsmasq.conf, /etc/nginx/sites-enabled/default, and /etc/samba/smb.conf are correct.

# Setup
***Set a Static IP to your host device!**
It is a Pain if the ip address changes to maintina dn fix this especail with a hive diskless os...

code in debain os:

#Become root and move to root home folder...
sudo su
cd /root
#Git clone the entire repository
git clone https://github.com/bmartino1/PXE.git
#Fix permission adn set script executable
chmod 777 -R *
#run 1 of 2 scripts
./depends.sh

Depends sh Script:
this script will install the applicaiton needed to run this server. it will downladed the lattest prebuilt binary and create a folder structure and prombt the end users on where to store and the ip address of the server.
we will require a tftp server, http server, and samba server in the end....

default path is /pxeserver 
a temp file will be create at your Home direectoy and moved into the default path if you chose to change the folder structure.
host server files are symlinked for easy access as to waht to easily edit to set host server settings outside of the bare min.
depends will call build.sh

Build sh Script:
This script sets the necessary server configs to run, we will also copy and build/make the necessary files for a uefi netboot pxe server and place them in the tftp folder.

Latter we can then edit menu.cfg for bios pxe, and grub.cfg to edit the efi grub pxe boot menu. even later we will add a grub chain boot option to run a boot.ipxe script for netboot via http

# Warning
Please Use Debain Bookworm OS as host. I have found that there is a isseus with syslinux/gnu grub dependaing on what base OS you have when building form binary! 

You may experience a broken PXE server, as it will still try to boot, but you will get NBD downloaded and or a hard stop at Welcome to Grub and nothing more... I can only assume its due to Host OS libary calls when built...

We will leverage DNSmasq for PC pxe Boot as a proxy
We will leverage nginx for a http web server for ipxe latter
We will leverage atftp as our tftp and pxe boot source to load main files
We will leverage samba for smb and file access for images for clonezilla

# License
If you found this help full please donate to https://www.paypal.com/donate/?business=PA3ZHF52483KW&no_recurring=1&item_name=Tech+Support+%2F+Health+%2F+Buy+Me+a+Coffee&currency_code=USD
You are free to edit use and distrubit this code. Not all code is my works but the coleted works of many other projects to have a functional pxe server.

