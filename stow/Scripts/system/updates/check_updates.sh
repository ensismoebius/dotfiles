#!/bin/bash
# Check for system, AUR, and Flatpak updates with error handling

err() { echo "Error: $1" >&2; } # Function to print errors to stderr
updates=0

if command -v yay &> /dev/null; then
	# yay -Qu lists both repo and AUR updates
	updates=$((updates + $(yay -Qu | wc -l)))
else
	err "yay not found." # Arch + AUR updates
fi

if command -v flatpak &> /dev/null; then
	updates=$((updates + $(flatpak remote-ls --updates | wc -l)))
else
	err "flatpak not found." # Flatpak updates
fi

echo " $updates"
