#!/bin/bash
# Toggle Bluetooth power state with error handling
if ! command -v bluetoothctl &> /dev/null; then
  echo "Error: bluetoothctl not found. Please install bluez-utils." >&2
  exit 1
fi

if bluetoothctl show | grep -q "Powered: yes"; then
  bluetoothctl power off || { echo "Failed to power off Bluetooth." >&2; exit 1; }
else
  bluetoothctl power on || { echo "Failed to power on Bluetooth." >&2; exit 1; }
fi
