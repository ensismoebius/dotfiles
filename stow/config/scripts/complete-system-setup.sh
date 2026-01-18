#!/usr/bin/env bash
set -euo pipefail

echo "Complete system setup: install portal, enable service, remove ml4w flatpaks, reload Hyprland"

logfile="$(pwd)/complete-system-setup.log"
echo "Log: $logfile"

detect_pm() {
  if command -v pacman >/dev/null 2>&1; then echo pacman
  elif command -v apt >/dev/null 2>&1; then echo apt
  elif command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v zypper >/dev/null 2>&1; then echo zypper
  else echo none
  fi
}

PM=$(detect_pm)
echo "Detected package manager: $PM" | tee -a "$logfile"

install_portal() {
  case "$PM" in
    pacman)
      sudo pacman -S --noconfirm xdg-desktop-portal-hyprland | tee -a "$logfile" ;;
    apt)
      sudo apt update && sudo apt install -y xdg-desktop-portal-hyprland | tee -a "$logfile" ;;
    dnf)
      sudo dnf install -y xdg-desktop-portal-hyprland | tee -a "$logfile" ;;
    zypper)
      sudo zypper install -y xdg-desktop-portal-hyprland | tee -a "$logfile" ;;
    *)
      echo "No supported package manager found. Please install xdg-desktop-portal-hyprland manually." | tee -a "$logfile" ;;
  esac
}

enable_portal() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user enable --now xdg-desktop-portal-hyprland | tee -a "$logfile" || echo "Enable failed; check user/systemd session" | tee -a "$logfile"
  else
    echo "systemctl not available; cannot enable portal service" | tee -a "$logfile"
  fi
}

remove_flatpak_ml4w() {
  echo "Removing com.ml4w.* flatpaks (user scope)" | tee -a "$logfile"
  user_refs=$(flatpak list --app --columns=ref --user 2>/dev/null | tr -d '\r' | grep '^com\.ml4w' || true)
  for r in $user_refs; do
    echo "Uninstalling user ref: $r" | tee -a "$logfile"
    flatpak uninstall --user --delete-data --noninteractive "$r" | tee -a "$logfile" || echo "Failed to uninstall $r (user)" | tee -a "$logfile"
  done

  echo "Removing com.ml4w.* flatpaks (system scope)" | tee -a "$logfile"
  system_refs=$(flatpak list --app --columns=ref --system 2>/dev/null | tr -d '\r' | grep '^com\.ml4w' || true)
  for r in $system_refs; do
    echo "Uninstalling system ref: $r" | tee -a "$logfile"
    sudo flatpak uninstall --system --delete-data --noninteractive "$r" | tee -a "$logfile" || echo "Failed to uninstall $r (system)" | tee -a "$logfile"
  done

  echo "Post-uninstall flatpak list (user):" | tee -a "$logfile"
  flatpak list --app --columns=application,ref --user | tee -a "$logfile"
  echo "Post-uninstall flatpak list (system):" | tee -a "$logfile"
  flatpak list --app --columns=application,ref --system | tee -a "$logfile"
}

reload_hypr() {
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl dispatch reload | tee -a "$logfile" || echo "hyprctl reload failed" | tee -a "$logfile"
  else
    echo "hyprctl not found; cannot reload Hyprland" | tee -a "$logfile"
  fi
}

echo "Starting system operations (may prompt for sudo)" | tee -a "$logfile"
install_portal
enable_portal
remove_flatpak_ml4w
reload_hypr

echo "Complete. See $logfile for details." | tee -a "$logfile"
