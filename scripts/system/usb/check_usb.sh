#!/bin/bash

# Directory where udiskie typically mounts removable devices
MOUNT_BASE="/run/media/$(whoami)"

# Check if the mount directory exists and has content
if [ -d "$MOUNT_BASE" ] && [ -n "$(ls -A "$MOUNT_BASE")" ]; then
    # Count the number of mounted devices
    COUNT=$(ls -A "$MOUNT_BASE" | wc -l)
    echo "{\"text\": \" $COUNT\", \"tooltip\": \"$COUNT USB device(s) connected\"}"
else
    echo "{\"text\": \" 0\", \"tooltip\": \"No USB device(s) connected\"}"
fi