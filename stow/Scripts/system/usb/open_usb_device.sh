#!/bin/bash

# Directory where udiskie typically mounts removable devices
MOUNT_BASE="/run/media/$(whoami)"

# Check if the mount directory exists and has content
if [ -d "$MOUNT_BASE" ] && [ -n "$(ls -A "$MOUNT_BASE")" ]; then
    # Get the path of the first mounted device
    DEVICE_PATH=$(ls -A "$MOUNT_BASE" | head -n 1)
    # Open the device with the default file manager
    xdg-open "$MOUNT_BASE/$DEVICE_PATH"
fi
