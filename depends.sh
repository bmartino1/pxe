#!/usr/bin/env bash

# Define colors for echo statements
BLACK='\033[0;30m'
DGRAY='\033[1;30m'
RED='\033[0;31m'
BRED='\033[1;31m'
GREEN='\033[0;32m'
BGREEN='\033[1;32m'
YELLOW='\033[0;33m'
BYELLOW='\033[1;33m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
PURPLE='\033[0;35m'
BPURPLE='\033[1;35m'
CYAN='\033[0;36m'
BCYAN='\033[1;36m'
LGRAY='\033[0;37m'
WHITE='\033[1;37m'
NOCOLOR='\033[0m'

# Set PXE server directory
echo -e "${CYAN}Setting PXE server directory${NOCOLOR}"
echo -n "Enter the PXE server directory path [default: /pxeserver]: "
read pxeserver
pxeserver=${pxeserver:-/pxeserver}

# Create necessary directories
echo -e "${CYAN}Creating necessary directories${NOCOLOR}"
mkdir -p $pxeserver/{tftp/{ipxe,efi},host_server_configs,http,samba/images}
mkdir -p $pxeserver/http/ipxe

# Install necessary packages
echo -e "${CYAN}Installing dependencies${NOCOLOR}"
need_install=""
dpkg -s dnsmasq  > /dev/null 2>&1 || need_install="$need_install dnsmasq"
dpkg -s nginx-extras  > /dev/null 2>&1 || need_install="$need_install nginx-extras"
dpkg -s pv  > /dev/null 2>&1 || need_install="$need_install pv"
dpkg -s atftpd  > /dev/null 2>&1 || need_install="$need_install atftpd"
dpkg -s grub-efi-amd64  > /dev/null 2>&1 || need_install="$need_install grub-efi-amd64"
dpkg -s ipxe  > /dev/null 2>&1 || need_install="$need_install ipxe"
dpkg -s syslinux  > /dev/null 2>&1 || need_install="$need_install syslinux"
dpkg -s pixz  > /dev/null 2>&1 || need_install="$need_install pixz"
dpkg -s debootstrap  > /dev/null 2>&1 || need_install="$need_install debootstrap"
dpkg -s samba  > /dev/null 2>&1 || need_install="$need_install samba"

if [[ ! -z $need_install ]]; then
    echo "Installing needed packages. Please wait..."
    apt update > /dev/null 2>&1
    apt install -y $need_install > /dev/null 2>&1
    echo "Done"
    echo
fi

# Set up host server configurations
echo -e "${CYAN}Setting up host server configurations${NOCOLOR}"
ln -sf /etc/default/atftpd $pxeserver/host_server_configs/edit_tftp
ln -sf /etc/nginx/sites-enabled/default $pxeserver/host_server_configs/edit_nginx
ln -sf /etc/dnsmasq.conf $pxeserver/host_server_configs/edit_dnsmasqconf
ln -sf /etc/default/dnsmasq $pxeserver/host_server_configs/edit_dnsmasq
ln -sf /etc/samba/smb.conf $pxeserver/host_server_configs/edit_smb

# Summary of changes
echo -e "${CYAN}Server configuration symlinks created:${NOCOLOR}"
ls -l $pxeserver/host_server_configs/

# Prompt for server IP address
echo -e "${CYAN}Please enter the server IP address:${NOCOLOR}"

# Extract current IP address
current_ip=$(hostname -I | awk '{print $1}')
echo -n "Enter the IP address [default: $current_ip]: "
read server_ip
server_ip=${server_ip:-$current_ip}

# Save IP address and PXE server directory to server.conf in home directory
config_file="$pxeserver/host_server_configs/bmartino-pxe-server.conf"
echo "server_ip=$server_ip" > $config_file
echo "pxeserver_directory=$pxeserver" >> $config_file

# Copy the configuration file to the home directory
cp $config_file $HOME/bmartino-pxe-server.conf

echo -e "${CYAN}Server IP address and PXE server directory saved to $config_file${NOCOLOR}"

# Prompt to build PXE server
echo -e "${CYAN}Necessary structure is now installed.${NOCOLOR}"
echo -n "Shall we copy and build the PXE server from premade binaries? [Y/n]: "
read response
response=${response:-Y}

if [[ $response =~ ^[Yy]$ ]]; then
    echo "Running build.sh..."
    if [[ -f "./build.sh" ]]; then
        ./build.sh
    else
        echo "build.sh not found in the current directory."
    fi
    exit 0
else
    echo "Exiting..."
    exit 1
fi
