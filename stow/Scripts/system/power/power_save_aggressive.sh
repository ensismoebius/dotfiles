#!/bin/bash
#
# Script: power_save_aggressive.sh
# Description: Aplica configurações agressivas de economia de energia no sistema.
#              Destinado a sistemas Arch Linux com Wayland/GNOME.
#
# WARNING: Este script aplica configurações EXTREMAS de economia de energia.
#          Isso pode resultar em redução significativa de performance e
#          desativação de funcionalidades. Use com cautela.
#

echo "=== Iniciando Otimização Agressiva de Energia ==="

# 1. Parar e desabilitar serviços não essenciais
echo "[1/7] Parando e desabilitando serviços desnecessários..."
services=(httpd bluetooth iwd cups avahi-daemon)
for svc in "${services[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        echo "  - Parando e desabilitando $svc..."
        sudo systemctl stop "$svc"
        sudo systemctl disable "$svc"
    else
        echo "  - Serviço $svc já inativo ou não encontrado."
    fi
done

# 2. Fechar processos gráficos/background desnecessários
echo "[2/7] Fechando processos GNOME/Wayland não essenciais (gnome-software, tracker, evolution, nm-applet)..."
pkill -f "gnome-software" || true
pkill -f "tracker" || true           # tracker-miner-fs, tracker-store
pkill -f "evolution" || true         # se não usar email
pkill -f "nm-applet" || true         # se usar apenas CLI network

# 3. Reduzir frequência da CPU para o governor 'powersave'
echo "[3/7] Aplicando governor 'powersave' em todas as CPUs..."
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "powersave" | sudo tee "$cpu" > /dev/null
done

# 4. Ajustes com TLP e Powertop
echo "[4/7] Verificando e aplicando configurações TLP e Powertop..."
if ! command -v tlp &> /dev/null; then
    echo "  - TLP não encontrado. Instalando..."
    sudo pacman -S --noconfirm tlp tlp-rdw
fi
echo "  - Habilitando e iniciando TLP..."
sudo systemctl enable tlp --now

if ! command -v powertop &> /dev/null; then
    echo "  - Powertop não encontrado. Instalando..."
    sudo pacman -S --noconfirm powertop
fi
echo "  - Executando 'powertop --auto-tune'..."
sudo powertop --auto-tune

# 5. Suspender módulos de kernel não essenciais
echo "[5/7] Suspendendo módulos de kernel ociosos (kvm_intel, kvm_amd, r8169, b43, b44)..."
modules=(kvm_intel kvm_amd r8169 b43 b44)
for mod in "${modules[@]}"; do
    if lsmod | grep -q "^$mod"; then
        echo "  - Descarregando módulo $mod..."
        sudo modprobe -r "$mod"
    else
        echo "  - Módulo $mod já descarregado ou não encontrado."
    fi
done

# 6. Desativar estados de CPU C-state de baixa energia (kworkers)
echo "[6/7] Desativando estados de CPU C-state de baixa energia para kworkers..."
for k in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
    echo 1 | sudo tee "$k" > /dev/null
done

# 7. Ajustar timeout de tela e hibernação
echo "[7/7] Configurando timeout de tela e hibernação..."
gsettings set org.gnome.desktop.session idle-delay 300      # 5 min
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 600   # 10 min
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 300   # 5 min

echo "=== Otimização Agressiva de Energia Concluída ==="

