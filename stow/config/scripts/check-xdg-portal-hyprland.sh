#!/usr/bin/env bash
# Check for xdg-desktop-portal-hyprland and show service status guidance
# Generated: 2026-01-18

set -euo pipefail

echo "Checking for xdg-desktop-portal-hyprland"

if command -v xdg-desktop-portal-hyprland >/dev/null 2>&1; then
  echo "xdg-desktop-portal-hyprland binary present: $(command -v xdg-desktop-portal-hyprland)"
else
  echo "xdg-desktop-portal-hyprland not found in PATH." >&2
fi

if command -v systemctl >/dev/null 2>&1; then
  echo "Checking user service status (if systemd user is active)"
  systemctl --user status xdg-desktop-portal-hyprland || echo "Service not active or not installed (check package manager)"
else
  echo "systemctl not available; cannot query service status in this environment"
fi

echo "If missing, install via your package manager (example for Arch):"
echo "  sudo pacman -S xdg-desktop-portal-hyprland"
echo "Then enable/start user service:"
echo "  systemctl --user enable --now xdg-desktop-portal-hyprland"
