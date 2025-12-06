#!/bin/bash

if hyprctl clients -j | jq -e '.[] | select(.class == "floating-terminal")' > /dev/null; then
    hyprctl dispatch togglespecialworkspace
else
    foot --app-id=floating-terminal
fi
