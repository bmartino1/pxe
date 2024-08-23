#!/usr/bin/env bash

# Define colors for echo statements
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NOCOLOR='\033[0m'

# Load configuration
config_file="/pxeserver/host_server_configs/bmartino-pxe-server.conf"
echo -e "${CYAN}Loading configuration from $config_file${NOCOLOR}"
if [[ -f $config_file ]]; then
    source $config_file
else
    echo -e "${RED}Configuration file $config_file not found!${NOCOLOR}"
    exit 1
fi

# Verify PXE server directory
if [[ ! -d $pxeserver_directory ]]; then
    echo -e "${RED}PXE server directory does not exist: $pxeserver_directory${NOCOLOR}"
    exit 1
fi

echo -e "${CYAN}PXE server directory: $pxeserver_directory${NOCOLOR}"

# Display the current IP address from the config file and the current machine's IP address
echo -e "${CYAN}Current IP address in config file: $server_ip${NOCOLOR}"
current_ip=$(hostname -I | awk '{print $1}')
echo -e "${CYAN}Current machine IP address: $current_ip${NOCOLOR}"

# Prompt for the new server IP address
echo -e "${CYAN}Please enter the new server IP address:${NOCOLOR}"
echo -n "Enter the IP address [default: $current_ip]: "
read new_ip
new_ip=${new_ip:-$current_ip}

# Update the config file with the new IP address if it has changed
if [[ "$new_ip" != "$server_ip" ]]; then
    echo -e "${CYAN}Updating $config_file with new IP address: $new_ip${NOCOLOR}"
    sed -i "s/^server_ip=.*/server_ip=$new_ip/" $config_file
    echo -e "${GREEN}Configuration file updated successfully.${NOCOLOR}"
else
    echo -e "${CYAN}No changes made to the configuration file.${NOCOLOR}"
fi

# Update DNSMASQ configuration
echo -e "${CYAN}Updating DNSMASQ configuration with new IP: $new_ip${NOCOLOR}"
dnsmasq_conf="/etc/dnsmasq.conf"
sed -i "s/^dhcp-range=.*/dhcp-range=$new_ip,proxy/" $dnsmasq_conf
sed -i "s|^pxe-service=X86PC,.*|pxe-service=X86PC, \"Boot BIOS PXE\",/bios/lpxelinux.0,$new_ip|" $dnsmasq_conf
sed -i "s|^pxe-service=BC_EFI,.*|pxe-service=BC_EFI, \"Boot UEFI PXE-BC\",/efi/grubnetx64.efi,$new_ip|" $dnsmasq_conf
sed -i "s|^pxe-service=X86-64_EFI,.*|pxe-service=X86-64_EFI, \"Boot UEFI PXE-64\",/efi/grubnetx64.efi,$new_ip|" $dnsmasq_conf

systemctl restart dnsmasq

# Regenerate UEFI GRUB image with the new IP address
echo -e "${CYAN}Recreating UEFI GRUB image with IP: $new_ip${NOCOLOR}"
grub-mkimage -d /usr/lib/grub/x86_64-efi/ -O x86_64-efi -o $pxeserver_directory/tftp/efi/grubnetx64.efi --prefix="(tftp,$new_ip)/efi" efinet tftp efi_uga efi_gop http configfile normal search

echo -e "${GREEN}IP address updated and UEFI GRUB image recreated successfully.${NOCOLOR}"
echo -e "${RED}IP address changes may require edits made to the pxe menus. please review the tftp bios, efi, ipxe menus so they have the correct IP address to recieve file${NOCOLOR}"
