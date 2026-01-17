#!/usr/bin/env sh
# Apply gsettings for interface to ensure apps like Nautilus pick up the theme
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark-pink-nord" || true
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur-Dark-pink-nord" || true
gsettings set org.gnome.desktop.interface cursor-theme "default" || true
gsettings set org.gnome.desktop.interface font-name "Adwaita Sans 11" || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || true

echo "Applied gsettings for gtk/icon/cursor/font; please restart Nautilus or log out/in."
