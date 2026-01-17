#!/usr/bin/env sh
# Persist theme env vars for login shells
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=Breeze
export GTK_THEME=WhiteSur-Dark-pink-nord

# Also export for nautilus forks/desktop launchers that respect Exec env
export XDG_CURRENT_DESKTOP=GNOME
