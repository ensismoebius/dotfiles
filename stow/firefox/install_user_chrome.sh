#!/usr/bin/env bash
set -euo pipefail

# Installs symlinks for userChrome.css and userContent.css into the active Firefox profile
# - Finds profile via ~/.mozilla/firefox/profiles.ini (prefers Default=1)
# - Creates profile's chrome/ directory if missing
# - Backs up existing files (non-symlinks) with a timestamp suffix
# - Creates symbolic links from this repo's stow/firefox/chrome/* to the profile chrome/

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_CHROME_DIR="$REPO_DIR/firefox/chrome"
PROFILES_INI="$HOME/.mozilla/firefox/profiles.ini"

# Look for common Firefox profile locations (regular, flatpak, snap)
PROFILE_BASES=("$HOME/.mozilla/firefox" "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" "$HOME/snap/firefox/common/.mozilla/firefox")
FOUND_PROFILES_INI=""

if [ ! -d "$SRC_CHROME_DIR" ]; then
  echo "Source chrome directory not found: $SRC_CHROME_DIR" >&2
  exit 1
fi

# pick the first profiles.ini we find in known base dirs
for base in "${PROFILE_BASES[@]}"; do
  if [ -f "$base/profiles.ini" ]; then
    PROFILES_INI="$base/profiles.ini"
    FOUND_PROFILES_INI=1
    break
  fi
done

if [ -z "$FOUND_PROFILES_INI" ]; then
  echo "Could not find Firefox profiles.ini in standard locations." >&2
  echo "Looked in: ${PROFILE_BASES[*]}" >&2
  exit 1
fi

declare -a profile_paths
default_profile=""
current_path=""

while IFS= read -r line; do
  case "$line" in
    Path=*) current_path="${line#Path=}"; profile_paths+=("$current_path") ;;
    Default=1) default_profile="$current_path" ;;
  esac
done < "$PROFILES_INI"

if [ -z "$default_profile" ]; then
  if [ ${#profile_paths[@]} -eq 0 ]; then
    echo "No Firefox profiles found in profiles.ini" >&2
    exit 1
  fi
  default_profile="${profile_paths[0]}"
  echo "No default profile marked; using first profile: $default_profile"
else
  echo "Using default profile: $default_profile"
fi

PROFILE_DIR="$HOME/.mozilla/firefox/$default_profile"
if [ ! -d "$PROFILE_DIR" ]; then
  echo "Profile directory does not exist: $PROFILE_DIR" >&2
  exit 1
fi

CHROME_DIR="$PROFILE_DIR/chrome"
mkdir -p "$CHROME_DIR"

for src in "$SRC_CHROME_DIR"/*; do
  [ -e "$src" ] || continue
  fname="$(basename "$src")"
  dest="$CHROME_DIR/$fname"

  if [ -L "$dest" ]; then
    # remove stale symlink
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    # backup existing regular file/dir
    bak="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$bak"
    echo "Backed up existing $dest -> $bak"
  fi

  ln -s "$src" "$dest"
  echo "Linked: $dest -> $src"
done

echo "Done. Please restart Firefox to apply the chrome styles."
