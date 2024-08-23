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

# Load configuration
config_file="$HOME/bmartino-pxe-server.conf"
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

# Create Netboot directory for x86_64-efi
echo -e "${CYAN}Creating Netboot directory for x86_64-efi${NOCOLOR}"
grub-mknetdir --net-directory="$pxeserver_directory/tftp" --subdir=/efi -d /usr/lib/grub/x86_64-efi/

# Make UEFI image
echo -e "${CYAN}Creating UEFI GRUB image${NOCOLOR}"
grub-mkimage -d /usr/lib/grub/x86_64-efi/ -O x86_64-efi -o $pxeserver_directory/tftp/efi/grubnetx64.efi --prefix="(tftp,$server_ip)/efi" efinet tftp efi_uga efi_gop http configfile normal search

# Verify if GRUB files were created successfully
if [[ ! -f $pxeserver_directory/tftp/efi/grubnetx64.efi ]]; then
    echo -e "${RED}Error: GRUB EFI image not created.${NOCOLOR}"
    exit 1
fi

# Copy syslinux files
echo -e "${CYAN}Copying syslinux files to $pxeserver/tftp/bios${NOCOLOR}"
cp -r /usr/lib/syslinux/modules/bios* "$pxeserver/tftp/"

# Copy GRUB EFI files
echo -e "${CYAN}Copying GRUB EFI files${NOCOLOR}"
cp $pxeserver_directory/tftp/efi/grubnetx64.efi $pxeserver_directory/tftp/efi/
if [[ -f /usr/lib/grub/x86_64-efi/grub.cfg ]]; then
    cp /usr/lib/grub/x86_64-efi/grub.cfg $pxeserver_directory/tftp/efi/
else
    echo -e "${YELLOW}Warning: grub.cfg not found, skipping copy.${NOCOLOR}"
fi

mkdir -p $pxeserver_directory/tftp/efi/x86_64-efi
for mod in normal.mod linux.mod efi_gop.mod efi_uga.mod part_gpt.mod part_msdos.mod ext2.mod fat.mod ntfs.mod search.mod multiboot.mod configfile.mod; do
    if [[ -f /usr/lib/grub/x86_64-efi/$mod ]]; then
        cp /usr/lib/grub/x86_64-efi/$mod $pxeserver_directory/tftp/efi/x86_64-efi/
    else
        echo -e "${YELLOW}Warning: $mod not found, skipping copy.${NOCOLOR}"
    fi
done

# Copy iPXE files
echo -e "${CYAN}Copying iPXE files${NOCOLOR}"
if [[ -d /usr/lib/ipxe/ ]]; then
    cp /usr/lib/ipxe/* $pxeserver_directory/tftp/ipxe/
else
    echo -e "${YELLOW}Warning: iPXE files directory not found, skipping copy.${NOCOLOR}"
fi

# Set permissions
echo -e "${CYAN}Setting permissions${NOCOLOR}"
chmod 777 -R $pxeserver_directory
chown nobody:nogroup -R $pxeserver_directory

# Append to DNSMASQ configuration
echo -e "${CYAN}Updating DNSMASQ configuration${NOCOLOR}"
{
    echo "port=0"
    echo ""
    echo "log-facility=/var/log/dnsmasq.log"
    echo "log-dhcp"
    echo ""
    echo "# Change the IP-address to the real IP-address of the server"
    echo "dhcp-range=$server_ip,proxy"
    echo "dhcp-no-override"
    echo ""
    echo "dhcp-option-force=208,f1:00:74:7e"
    echo "dhcp-option-force=211,30i"
    echo ""
    echo "# Change the IP-address to the real IP-address of the server"
    echo "pxe-service=X86PC, \"Boot BIOS PXE\",/bios/lpxelinux.0,$server_ip"
    echo "pxe-service=BC_EFI, \"Boot UEFI PXE-BC\",/efi/grubnetx64.efi,$server_ip"
    echo "pxe-service=X86-64_EFI, \"Boot UEFI PXE-64\",/efi/grubnetx64.efi,$server_ip"
} >> /etc/dnsmasq.conf

echo "DNSMASQ_EXCEPT=lo" >> /etc/default/dnsmasq
systemctl restart dnsmasq

# Update Nginx configuration
echo -e "${CYAN}Updating Nginx configuration${NOCOLOR}"
# Update root directive to use the PXE server directory
sed -i "s|root /var/www/html;|root $pxeserver_directory/http;|" /etc/nginx/sites-enabled/default
# Ensure directory listing is enabled by adding autoindex directive
if ! grep -q "autoindex on;" /etc/nginx/sites-enabled/default; then
    sed -i '/location \/ {/a \    autoindex on;\n    autoindex_exact_size off;\n    autoindex_localtime on;' /etc/nginx/sites-enabled/default
fi
# Restart Nginx to apply the changes
systemctl restart nginx

# Update Samba configuration
echo -e "${CYAN}Updating Samba configuration${NOCOLOR}"
cat <<EOL >> /etc/samba/smb.conf

[pxeserver]
path = $pxeserver_directory
writable = yes
guest ok = yes
guest only = yes
create mask = 0777
directory mask = 0777
force user = nobody

[tftp]
path = $pxeserver_directory/tftp
writable = yes
guest ok = yes
guest only = yes
create mask = 0777
directory mask = 0777
force user = nobody

[http]
path = $pxeserver_directory/http
writable = yes
guest ok = yes
guest only = yes
create mask = 0777
directory mask = 0777
force user = nobody

[samba]
path = $pxeserver_directory/samba
writable = yes
guest ok = yes
guest only = yes
create mask = 0777
directory mask = 0777
force user = nobody

[images]
path = $pxeserver_directory/samba/images
writable = yes
guest ok = yes
guest only = yes
create mask = 0777
directory mask = 0777
force user = nobody
EOL

systemctl restart smbd

# Update TFTP configuration
echo -e "${CYAN}Updating TFTP configuration${NOCOLOR}"
sed -e 's/^USE_INETD=true/USE_INETD=false/g' -i /etc/default/atftpd
sed -i "/OPTIONS=/c OPTIONS=\"--tftpd-timeout 300 --retry-timeout 5 --mcast-port 1758 --mcast-addr 239.239.239.0-255 --mcast-ttl 1 --maxthread 100 --verbose=5 ${TFTP_ROOT}\"" /etc/default/atftpd
systemctl enable atftpd > /dev/null 2>&1
systemctl restart atftpd

# Clean up and copy final files
cp ./update-ip.sh $pxeserver_directory

# Copy GRUB EFI files
echo -e "${CYAN}Copying pxe menu files${NOCOLOR}"
if [[ -f /usr/lib/grub/x86_64-efi/grub.cfg ]]; then
    cp /usr/lib/grub/x86_64-efi/grub.cfg $pxeserver_directory/tftp/efi/
else
    echo -e "${YELLOW}grub.cfg not found in /usr/lib/grub/x86_64-efi/. Using example file from the repository.${NOCOLOR}"
    cp ./pxefile/menu_examples/grub.cfg $pxeserver_directory/tftp/efi/
fi

# Copy Syslinux menu.cfg
echo -e "${CYAN}Copying Syslinux menu.cfg to BIOS folder${NOCOLOR}"
cp ./pxefile/menu_examples/menu.cfg $pxeserver_directory/tftp/bios/

# Copy iPXE boot.ipxe
echo -e "${CYAN}Copying iPXE boot.ipxe to iPXE folder${NOCOLOR}"
cp ./pxefile/menu_examples/boot.ipxe $pxeserver_directory/tftp/ipxe/

# Additional configurations and final steps


echo -e "${GREEN}PXE server setup completed successfully.${NOCOLOR}"
echo -e "${YELLOW}PXE server Prox ready, please set dhcp next boot to /ipxe/boot.ipxe and tftp to the ip of this server...${NOCOLOR}"
