#!/usr/bin/env bash
# Apply theme-related Flatpak overrides for all installed Flatpak apps (user-level)
# Generated: 2026-01-18

set -euo pipefail

THEME=WhiteSur-Dark-pink-nord
QT_THEME=qt6ct
DESKTOP=Hyprland

echo "Applying Flatpak environment overrides for GTK/icon theme: $THEME"

if ! command -v flatpak >/dev/null 2>&1; then
  echo "flatpak not found; install flatpak to apply overrides" >&2
  exit 2
fi

apps=$(flatpak list --app --columns=application 2>/dev/null || true)
if [ -z "$apps" ]; then
  echo "No flatpak apps detected (or user has none installed)."
  echo "You can still use the template in stow/config/.local/share/flatpak/overrides/"
  exit 0
fi

for app in $apps; do
  echo "Overriding $app"
  flatpak override --user --env=GTK_THEME=$THEME --env=GTK_ICON_THEME=$THEME --env=QT_QPA_PLATFORMTHEME=$QT_THEME --env=XDG_CURRENT_DESKTOP=$DESKTOP "$app"
done

echo "Overrides applied. Restart Flatpak apps to pick up changes."
