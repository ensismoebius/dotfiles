#!/bin/bash

# This script downloads and installs the latest stable version of Visual Studio Code.

# pare imediatamente se qualquer comando falhar
set -e

# --- Download Section ---
DOWNLOAD_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
TARBALL="vscode-linux-x64-stable.tar.gz"

echo "Downloading the latest version of Visual Studio Code..."
curl -L "$DOWNLOAD_URL" -o "$TARBALL"
echo "Download complete."


# --- Installation Section ---
FOLDER="VSCode-linux-x64"
DEST="/opt/vscode"

echo "Extracting files..."
# descompactar
tar -xvzf "$TARBALL"

echo "Installing to $DEST..."
# mover para /opt
sudo rm -rf "$DEST"
sudo mv "$FOLDER" "$DEST"

# criar link simbólico
sudo ln -sf "$DEST/code" /usr/local/bin/code

# criar entrada no menu
sudo tee /usr/share/applications/vscode.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
Exec=env MOZ_ENABLE_WAYLAND=1 /opt/vscode/code --no-sandbox --unity-launch %F
Icon=/opt/vscode/resources/app/resources/linux/code.png
Type=Application
Categories=Utility;TextEditor;Development;IDE;
StartupNotify=true
StartupWMClass=Code
EOF

echo "Cleaning up downloaded file..."
rm "$TARBALL"


echo "Instalação concluída com sucesso."
echo "Para rodar com suporte Wayland, execute:"
echo "  code --ozone-platform=wayland --enable-features=WaylandWindowDecorations"

