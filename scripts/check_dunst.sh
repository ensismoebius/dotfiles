#!/bin/bash

# Get notification count from makoctl
COUNT=$(makoctl list | grep -c "^[0-9]")

if [ "$(makoctl mode | grep -c "do-not-disturb")" -gt 0 ]; then
    echo '{"text": "", "tooltip": "Notifications paused (DND)"}'
else
    if [ "$COUNT" -gt 0 ]; then
        echo "{\"text\": \" ($COUNT)\", \"tooltip\": \"$COUNT notifications waiting\"}"
    else
        echo '{"text": "", "tooltip": "No notifications"}'
    fi
fi
