#!/bin/bash
#
# Script: power_save_soft.sh
# Description: Aplica configurações suaves de economia de energia no sistema.
#              Destinado a sistemas Arch Linux com Wayland/GNOME, mantendo boa usabilidade.
#

echo "=== Iniciando Otimização Suave de Energia ==="

# 1. Parar serviços não essenciais (focando em manter a funcionalidade principal)
echo "[1/5] Parando serviços desnecessários, mantendo Bluetooth e Wi-Fi..."
services=(httpd cups avahi-daemon) # Bluetooth e iwd não são desabilitados para manter funcionalidade
for svc in "${services[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        echo "  - Parando $svc..."
        sudo systemctl stop "$svc"
        # Não desabilita para permitir fácil reativação manual
    else
        echo "  - Serviço $svc já inativo ou não encontrado."
    fi
done

# 2. Fechar processos gráficos/background desnecessários (mantendo nm-applet para rede)
echo "[2/5] Fechando processos GNOME/Wayland não essenciais (gnome-software, tracker, evolution)..."
pkill -f "gnome-software" || true
pkill -f "tracker" || true           # tracker-miner-fs, tracker-store
pkill -f "evolution" || true         # se não usar email
# nm-applet é mantido para gerenciamento de rede via GUI

# 3. Reduzir frequência da CPU para o governor 'powersave'
echo "[3/5] Aplicando governor 'powersave' em todas as CPUs..."
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "powersave" | sudo tee "$cpu" > /dev/null
done

# 4. Ajustes com TLP e Powertop
echo "[4/5] Verificando e aplicando configurações TLP e Powertop..."
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

# 5. Suspender módulos de kernel não essenciais (mantendo kvm_amd para virtualização)
echo "[5/5] Suspendendo módulos de kernel ociosos (r8169, b43, b44)..."
modules=(r8169 b43 b44) # kvm_amd e kvm_intel são mantidos para evitar impacto em virtualização
for mod in "${modules[@]}"; do
    if lsmod | grep -q "^$mod"; then
        echo "  - Descarregando módulo $mod..."
        sudo modprobe -r "$mod"
    else
        echo "  - Módulo $mod já descarregado ou não encontrado."
    fi
done

echo "=== Otimização Suave de Energia Concluída ==="