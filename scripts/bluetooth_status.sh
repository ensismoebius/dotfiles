#!/bin/bash

if bluetoothctl show | grep -q "Powered: yes"; then
    echo '{"text": " 󰂯 On", "tooltip": "Bluetooth: On"}'
else
    echo '{"text": " 󰂲 Off", "tooltip": "Bluetooth: Off"}'
fi
