#!/bin/bash

# Import environment variables
eval $(systemctl --user show-environment | grep -E '^(WAYLAND_DISPLAY|XDG_SESSION_TYPE)=')

# Ensure correct environment
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
export XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-wayland}
export XDG_CURRENT_DESKTOP=Hyprland

# Kill existing waybar instances
killall waybar

# Start waybar with debug output
exec waybar -l debug