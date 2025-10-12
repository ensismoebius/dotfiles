#!/bin/bash

# pare imediatamente se qualquer comando falhar
set -e

# caminho do arquivo baixado (ajuste se necessário)
TARBALL=$1
FOLDER="VSCode-linux-x64"
DEST="/opt/vscode"

# descompactar
tar -xvzf "$TARBALL"

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

echo "Instalação concluída com sucesso."
echo "Para rodar com suporte Wayland, execute:"
echo "  code --ozone-platform=wayland --enable-features=WaylandWindowDecorations"

