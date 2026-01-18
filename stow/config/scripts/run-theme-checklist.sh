#!/usr/bin/env bash
set -u

# Interactive helper to finish theme/portal/flatpak/hyprland checklist.
# - Runs from repo path `stow/config/scripts/run-theme-checklist.sh`.
# - Appends outputs to `todo.md` in repo root.
# - Supports DRY_RUN=1 to avoid making changes (useful for testing).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# repo root is three levels up from stow/config/scripts -> ../../..
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TODO_FILE="$REPO_ROOT/todo.md"

DRY_RUN=${DRY_RUN:-0}

timestamp() { date --iso-8601=seconds; }

append_header(){
  cat >> "$TODO_FILE" <<EOF

## **Interactive helper run**
- **Run timestamp:** $(timestamp)

EOF
}

run_and_log(){
  label="$1"; shift
  echo "- **$label**" >> "$TODO_FILE"
  echo '```' >> "$TODO_FILE"
  if [ "$DRY_RUN" = "1" ]; then
    echo "(DRY_RUN=1) Command: $*" >> "$TODO_FILE"
    echo "(DRY_RUN=1) Output omitted or captured locally." >> "$TODO_FILE"
  else
    "$@" 2>&1 | sed 's/^/    /' >> "$TODO_FILE" || true
  fi
  echo '```' >> "$TODO_FILE"
  echo >> "$TODO_FILE"
}

prompt_yesno(){
  local prompt="$1" default="$2"
  if [ "$DRY_RUN" = "1" ]; then
    echo "$prompt -> DRY_RUN => $default"
    [ "$default" = "y" ] && return 0 || return 1
  fi
  while true; do
    read -rp "$prompt [y/N]: " ans || return 1
    case "$ans" in
      [Yy]*) return 0 ;;
      [Nn]*|"") return 1 ;;
    esac
  done
}

echo "Running interactive checklist helper (repo: $REPO_ROOT)"
echo "Appending outputs to: $TODO_FILE"

append_header

# 1) Portal user service
if prompt_yesno "Attempt to enable/start xdg-desktop-portal-hyprland (user service)?" "n"; then
  run_and_log "systemctl --user daemon-reload" systemctl --user daemon-reload
  if [ "$DRY_RUN" = "1" ]; then
    run_and_log "systemctl --user enable --now xdg-desktop-portal-hyprland.service (DRY)" echo
  else
    run_and_log "systemctl --user enable --now xdg-desktop-portal-hyprland.service" systemctl --user enable --now xdg-desktop-portal-hyprland.service
  fi
  run_and_log "systemctl --user status xdg-desktop-portal-hyprland.service" systemctl --user status xdg-desktop-portal-hyprland.service --no-pager || true
  run_and_log "journalctl --user -u xdg-desktop-portal-hyprland (last 200 lines)" journalctl --user -u xdg-desktop-portal-hyprland --no-pager -n 200 || true
  run_and_log "which xdg-desktop-portal-hyprland" which xdg-desktop-portal-hyprland || true
else
  echo "- Skipped portal enable" >> "$TODO_FILE"
fi

# 2) Flatpak removals
run_and_log "flatpak list --app --columns=application,ref --user" flatpak list --app --columns=application,ref --user || true
run_and_log "flatpak list --app --columns=application,ref --system" flatpak list --app --columns=application,ref --system || true

echo "Checking for com.ml4w.* refs..."
ML4W_REFS_USER=$(flatpak list --app --columns=ref --user 2>/dev/null | grep -E '^com\.ml4w\.' || true)
ML4W_REFS_SYSTEM=$(flatpak list --app --columns=ref --system 2>/dev/null | grep -E '^com\.ml4w\.' || true)

if [ -n "$ML4W_REFS_USER" ] || [ -n "$ML4W_REFS_SYSTEM" ]; then
  echo "Found com.ml4w refs (user/system)." >> "$TODO_FILE"
  echo >> "$TODO_FILE"
  if prompt_yesno "Uninstall found com.ml4w.* Flatpaks from user scope?" "n"; then
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      run_and_log "flatpak uninstall --user --delete-data $ref" flatpak uninstall --user --delete-data "$ref" || true
    done <<< "$ML4W_REFS_USER"
  else
    echo "- Skipped user-scope com.ml4w removals" >> "$TODO_FILE"
  fi

  if [ -n "$ML4W_REFS_SYSTEM" ]; then
    if prompt_yesno "Uninstall found com.ml4w.* Flatpaks from system scope (requires sudo)?" "n"; then
      echo "Attempting sudo - will prompt for password if required." >&2
      sudo -v || true
      while IFS= read -r ref; do
        [ -z "$ref" ] && continue
        if [ "$DRY_RUN" = "1" ]; then
          run_and_log "sudo flatpak uninstall --system --delete-data $ref (DRY)" echo
        else
          run_and_log "sudo flatpak uninstall --system --delete-data $ref" sudo flatpak uninstall --system --delete-data "$ref" || true
        fi
      done <<< "$ML4W_REFS_SYSTEM"
    else
      echo "- Skipped system-scope com.ml4w removals" >> "$TODO_FILE"
    fi
  fi
else
  echo "No com.ml4w refs found" >> "$TODO_FILE"
fi

# 3) Reload Hyprland and validate
if prompt_yesno "Run Hyprland config checks and attempt reload?" "n"; then
  run_and_log "hyprctl configerrors" hyprctl configerrors || true
  if [ "$DRY_RUN" = "1" ]; then
    run_and_log "hyprctl dispatch reload (DRY)" echo
  else
    run_and_log "hyprctl dispatch reload" hyprctl dispatch reload || true
    run_and_log "hyprctl reload" hyprctl reload || true
  fi
  run_and_log "hyprctl monitors" hyprctl monitors || true
else
  echo "- Skipped Hyprland reload/checks" >> "$TODO_FILE"
fi

cat >> "$TODO_FILE" <<EOF
- **Helper run completed:** $(timestamp)

EOF

echo "Helper run finished. Appended outputs to $TODO_FILE"

exit 0
