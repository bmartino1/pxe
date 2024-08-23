#!/bin/sh
# Automate Clonezilla to clone a local NVMe drive to a Samba share

# Define variables
SRC_DEVICE="/dev/nvme0n1"
TARGET_SAMBA_SHARE="/mnt/smb"
IMAGE_PATH="hive-base.img"
LOG_FILE="/var/log/clonezilla.log"

# Create a log file for progress reporting
echo "Starting Clonezilla automation script..." | sudo tee -a $LOG_FILE

# Function to display progress
display_progress() {
    echo "$1" | sudo tee -a $LOG_FILE
}

# Check if mount point exists, otherwise create it
if [ ! -d /mnt/smb ]; then
    sudo mkdir -p /mnt/smb
    sudo chmod 777 /mnt/smb
fi

# Check if Samba share is mounted
if ! mountpoint -q /mnt/smb; then
    display_progress "Mounting Samba share..."
    sudo mount -t cifs -o guest //192.168.201.22/images /mnt/smb
    if [ $? -ne 0 ]; then
        display_progress "Failed to mount Samba share."
        exit 1
    fi
fi

# Log the start of the Clonezilla operation
display_progress "Starting Clonezilla imaging process..."

# Run Clonezilla with logging for progress
sudo ocs-sr --batch --localdev --clone-hidden-data -z1p -i 2000 -j2 -r -s --source $SRC_DEVICE --target $TARGET_SAMBA_SHARE/$IMAGE_PATH >> $LOG_FILE 2>&1

# Check if Clonezilla finished successfully
if [ $? -eq 0 ]; then
    display_progress "Clonezilla imaging completed successfully."
else
    display_progress "Clonezilla imaging encountered errors."
    exit 1
fi

# Optional: Clean up
display_progress "Unmounting Samba share..."
sudo umount /mnt/smb

display_progress "Automation script completed."

# Exit the script
exit 0
