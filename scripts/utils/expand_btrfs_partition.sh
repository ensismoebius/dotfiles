#!/bin/bash

set -e

# List all partitions
echo "Available partitions:"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT -p | grep -E 'part|[0-9]$'

echo
read -rp "Enter the full path of the partition to expand (e.g., /dev/vda1): " PART

# Validate input
if [ ! -b "$PART" ]; then
  echo "Error: $PART is not a valid block device"
  exit 1
fi

DISK=$(lsblk -no pkname "$PART" | awk '{print "/dev/" $1}')
START=$(sudo parted "$DISK" unit s print | awk -v part="$PART" '
  BEGIN { start="" }
  $0 ~ part { start=$2 }
  END { gsub("s", "", start); print start }
')

echo
echo "Selected partition: $PART"
echo "Disk: $DISK"
echo "Partition start: $START"
read -rp "Proceed to delete and recreate this partition to use full disk? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

# Run parted steps
sudo parted "$DISK" --script rm 1
sudo parted "$DISK" --script mkpart primary "${START}s" 100%

# Re-read partition table
sudo partprobe "$DISK"
sleep 1

# Resize btrfs filesystem
MOUNTPOINT=$(lsblk -no MOUNTPOINT "$PART")

if [ -z "$MOUNTPOINT" ]; then
  echo "Error: $PART is not mounted. Mount it first and rerun resize manually."
  exit 1
fi

echo "Expanding Btrfs filesystem on $PART mounted at $MOUNTPOINT..."
sudo btrfs filesystem resize max "$MOUNTPOINT"

echo "Done. New usage:"
sudo btrfs filesystem usage "$MOUNTPOINT"

