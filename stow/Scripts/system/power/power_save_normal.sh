#!/bin/bash
#
# Script: power_save_normal.sh
# Description: Restaura as configurações de energia para um estado "normal" ou padrão.
#              Reverte muitas das otimizações agressivas e ultra agressivas.
#

echo "=== Restaurando Configurações Normais de Energia ==="

# 1. Habilitar e iniciar serviços essenciais que podem ter sido desabilitados
echo "[1/8] Habilitando e iniciando serviços comuns (Bluetooth, iwd, CUPS, Avahi)..."
# Usamos `is-enabled` para não habilitar serviços que não estavam habilitados antes
services=(bluetooth iwd cups avahi-daemon)
for svc in "${services[@]}"; do
    if systemctl is-enabled --quiet "$svc"; then
        echo "  - Habilitando e iniciando $svc..."
        sudo systemctl start "$svc"
        sudo systemctl enable "$svc"
    elif ! systemctl is-enabled --quiet "$svc" && systemctl is-active --quiet "$svc"; then
        # If it's active but not enabled, just start it
        echo "  - Iniciando $svc (já ativo, não habilitado automaticamente)."
        sudo systemctl start "$svc"
    else
        echo "  - Serviço $svc não estava habilitado ou ativo, ignorando."
    fi
done

# Nota: Para serviços como httpd ou mariadb, o usuário pode precisar reativá-los manualmente
# se eles faziam parte de uma configuração específica e foram desativados.
# Ex: sudo systemctl start httpd && sudo systemctl enable httpd

# 2. Restaurar governor da CPU para 'ondemand' (comum em sistemas desktop)
echo "[2/8] Restaurando governor da CPU para 'ondemand'..."
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "ondemand" | sudo tee "$cpu" > /dev/null
done

# 3. Recarregar módulos de kernel que podem ter sido descarregados
echo "[3/8] Recarregando módulos de kernel comuns (kvm_intel, kvm_amd, r8169)..."
modules=(kvm_intel kvm_amd r8169) # b43, b44 são mais específicos de hardware, pode não ser universal
for mod in "${modules[@]}"; do
    if ! lsmod | grep -q "^$mod"; then
        echo "  - Carregando módulo $mod..."
        sudo modprobe "$mod"
    else
        echo "  - Módulo $mod já carregado."
    fi
done

# 4. Reabilitar estados de CPU C-state de baixa energia para kworkers (se foram desabilitados)
echo "[4/8] Reabilitando estados de CPU C-state para kworkers..."
for k in /sys/devices/system/cpu/cpu*/cpuidle/state*/disable; do
    echo 0 | sudo tee "$k" > /dev/null
done

# 5. Restaurar timeouts de tela e hibernação para valores mais longos/padrão GNOME
echo "[5/8] Restaurando timeouts de tela e hibernação para valores padrão..."
gsettings set org.gnome.desktop.session idle-delay 900       # 15 min
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1800 # 30 min
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 900 # 15 min
# Estas são heurísticas. O usuário pode precisar ajustar para seus próprios padrões.

# 6. Reabilitar Wi-Fi e Bluetooth (se foram desativados)
echo "[6/8] Reativando Wi-Fi e Bluetooth..."
nmcli radio wifi on || true
rfkill unblock bluetooth || true
echo "  - Wi-Fi e Bluetooth reativados (se disponíveis)."

# 7. Desabilitar autosuspend para dispositivos USB
echo "[7/8] Desabilitando autosuspend para dispositivos USB..."
for i in /sys/bus/usb/devices/*/power/autosuspend; do
    echo "2" | sudo tee "$i" 2>/dev/null # -1 for disabled, 2 for never autosuspend
done
for i in /sys/bus/usb/devices/*/power/control; do
    echo "on" | sudo tee "$i" 2>/dev/null
done
echo "  - Autosuspend USB desabilitado."

# 8. Restaurar gerenciamento de energia para SATA/NVMe (se foi alterado)
echo "[8/8] Restaurando gerenciamento de energia para SATA/NVMe..."
for disk in /sys/block/sd*/device; do
    echo "max_performance" | sudo tee "$disk"/scsi_disk/power_policy 2>/dev/null
done
for disk in /sys/class/nvme/*/power_state; do
    echo "active" | sudo tee "$disk" 2>/dev/null
done
echo "  - Gerenciamento de energia SATA/NVMe restaurado."


echo "=== Restauração para Configurações Normais de Energia Concluída ==="
