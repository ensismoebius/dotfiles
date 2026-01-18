#!/usr/bin/env sh
# Persist theme env vars for login shells
# Enforced system theme and Qt/Wayland integration for Hyprland
export GTK_THEME=WhiteSur-Dark-pink-nord
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME=qt6ct
# Keep older qt5ct compatibility variable for apps that read it
export QT_QPA_PLATFORMTHEME_FALLBACK=qt5ct
# Desktop env identification for toolkit theme selection
export XDG_CURRENT_DESKTOP=Hyprland

# Note: This file is part of dotfiles/stow. After deploying, ensure login
# shells and display manager sources /etc/profile.d scripts so variables apply.
