#!/bin/bash
#
# Script: power_save_ultimate.sh
# Description: Aplica configurações EXTREMAS de economia de energia no sistema.
#              Destinado a sistemas Arch Linux com Wayland/Hyprland.
#
# WARNING: Este script aplica configurações que podem resultar em instabilidade do sistema,
#          redução drástica de performance e desativação de funcionalidades cruciais (Wi-Fi, Bluetooth).
#          Use com EXTREMA CAUTELA e esteja ciente dos impactos na usabilidade.
#

echo "=== Iniciando Otimização ULTRA Agressiva de Energia ==="

# 1. Gerenciamento de Aplicações e Serviços
echo "[1/9] Verificando e parando serviços específicos (httpd, mariadb)..."
if systemctl is-active --quiet httpd; then
    echo "  - Parando httpd..."
    sudo systemctl stop httpd
else
    echo "  - Serviço httpd já inativo ou não encontrado."
fi
if systemctl is-active --quiet mariadb; then
    echo "  - Parando mariadb..."
    sudo systemctl stop mariadb
else
    echo "  - Serviço mariadb já inativo ou não encontrado."
fi

# 2. CPU em modo powersave
echo "[2/9] Configurando CPU para 'powersave' governor..."
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "powersave" | sudo tee "$cpu" > /dev/null
done

# 3. GPU dedicada para mínima energia
echo "[3/9] Tentando configurar GPU dedicada para mínima energia (se aplicável - AMD)..."
if lspci | grep -q "AMD"; then
    echo "  - Tentando definir 'battery' para power_dpm_state..."
    echo "battery" | sudo tee /sys/class/drm/card*/device/power_dpm_state 2>/dev/null
    # Tenta um perfil de energia mais agressivo, se disponível
    for pprof in /sys/class/drm/card*/device/pp_power_profile_mode; do
        if [ -f "$pprof" ]; then
            echo "  - Tentando definir perfil de energia 'low'..."
            echo "low" | sudo tee "$pprof" 2>/dev/null
            break
        fi
    done
else
    echo "  - Nenhuma GPU AMD detectada ou método de controle não aplicável."
fi

# 4. Backlight mínimo
echo "[4/9] Reduzindo brilho da tela ao mínimo (para valor 1)..."
for b in /sys/class/backlight/*/brightness; do
    echo 1 | sudo tee "$b" > /dev/null
done

# 5. Wi-Fi e Bluetooth off
echo "[5/9] Desligando Wi-Fi e Bluetooth..."
nmcli radio wifi off
rfkill block bluetooth
echo "  - Wi-Fi e Bluetooth desativados."

# 6. Suspender kworkers e módulos ociosos
echo "[6/9] Desativando estados de CPU C-state de baixa energia para kworkers e descarregando módulos ociosos..."
for k in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
    echo 1 | sudo tee "$k" > /dev/null
done

modules=(kvm_intel kvm_amd r8169 b43 b44) # Adicione outros módulos que podem ser descarregados
for mod in "${modules[@]}"; do
    if lsmod | grep -q "^$mod"; then
        echo "  - Descarregando módulo $mod..."
        sudo modprobe -r "$mod"
    else
        echo "  - Módulo $mod já descarregado ou não encontrado."
    fi
done

# 7. USB Autosuspend
echo "[7/9] Habilitando autosuspend para dispositivos USB (se possível)..."
for i in /sys/bus/usb/devices/*/power/autosuspend; do
    echo "1" | sudo tee "$i" 2>/dev/null
done
for i in /sys/bus/usb/devices/*/power/control; do
    echo "auto" | sudo tee "$i" 2>/dev/null
done
echo "  - Autosuspend USB configurado."

# 8. SATA/NVMe Power Management
echo "[8/9] Configurando gerenciamento de energia para SATA/NVMe (min_power/auto)..."
for disk in /sys/block/sd*/device; do
    echo "min_power" | sudo tee "$disk"/scsi_disk/power_policy 2>/dev/null
done
for disk in /sys/class/nvme/*/power_state; do
    echo "auto" | sudo tee "$disk" 2>/dev/null
done
echo "  - Gerenciamento de energia SATA/NVMe configurado."

# 9. TLP + Powertop tuning
echo "[9/9] Aplicando TLP e Powertop auto-tune..."
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

echo "=== Otimização ULTRA Agressiva de Energia CONCLUÍDA ==="
echo "Configurações extremas de energia aplicadas. Verifique a funcionalidade dos seus dispositivos."
