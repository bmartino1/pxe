#!/bin/sh
# Automate image restoration to the local NVMe drive using dd with progress display

# Define variables
# NVME
TARGET_DEVICE="nvme0n1"
# SATA SSD
# TARGET_DEVICE="sda"
# VM vdisk img
#TARGET_DEVICE="vda"
TARGET_SAMBA_SHARE="/home/partimag"
IMAGE_NAME="DD-Hive-Base.img"

# Define log file location in /tmp
LOG_FILE="/tmp/dd_clone.log"

# Create a log file for progress reporting
echo "Starting dd image restoration script..." | sudo tee -a $LOG_FILE

# Function to display progress
display_progress() {
    echo "$1" | sudo tee -a $LOG_FILE
}

# Check if Samba share is mounted #set to your servers IP
echo "Did you set to your server IP"
if ! mountpoint -q $TARGET_SAMBA_SHARE; then
    display_progress "Mounting Samba share..."
    sudo mount -t cifs -o guest //192.168.201.22/images $TARGET_SAMBA_SHARE
    sudo chmod 777 -R $TARGET_SAMBA_SHARE
    sudo chown nobody:nogroup -R $TARGET_SAMBA_SHARE
    if [ $? -ne 0 ]; then
        display_progress "Failed to mount Samba share."
        exit 1
    fi
fi

# Log the start of the dd operation
display_progress "Starting image restoration process using dd..."

# Use dd to restore the image to the target device with progress display (Gave up with OCR comands...
#sudo dd if=$TARGET_SAMBA_SHARE/$IMAGE_NAME of=/dev/$TARGET_DEVICE status=progress conv=fsync | sudo tee -a $LOG_FILE

# Check if dd finished successfully
if [ $? -eq 0 ]; then
    display_progress "Image restoration completed successfully."
    display_progress "Unmounting Samba share..."
    sudo umount $TARGET_SAMBA_SHARE
    display_progress "Image restoration script completed. Rebooting..."
    sudo reboot
else
    display_progress "Image restoration encountered errors."
    exit 0
fi

# Exit the script
exit 0
