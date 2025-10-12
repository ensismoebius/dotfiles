#!/bin/bash

OUTPUT="hardware_info.txt"

echo "Coletando informações de hardware..."
echo "Arquivo de saída: $OUTPUT"
echo "Data: $(date)" > "$OUTPUT"
echo "===============================" >> "$OUTPUT"

# CPU
echo -e "\n=== CPU (lscpu) ===" >> "$OUTPUT"
lscpu >> "$OUTPUT" 2>/dev/null

# Memória
echo -e "\n=== Memória (free -h) ===" >> "$OUTPUT"
free -h >> "$OUTPUT" 2>/dev/null

echo -e "\n=== Detalhes da RAM (dmidecode) ===" >> "$OUTPUT"
sudo dmidecode -t memory >> "$OUTPUT" 2>/dev/null

# Disco
echo -e "\n=== Partições (lsblk) ===" >> "$OUTPUT"
lsblk >> "$OUTPUT" 2>/dev/null

echo -e "\n=== Uso de disco (df -h) ===" >> "$OUTPUT"
df -h >> "$OUTPUT" 2>/dev/null

echo -e "\n=== Detecção de discos (fdisk -l) ===" >> "$OUTPUT"
sudo fdisk -l >> "$OUTPUT" 2>/dev/null

# GPU
echo -e "\n=== GPU (lspci | grep VGA) ===" >> "$OUTPUT"
lspci | grep VGA >> "$OUTPUT" 2>/dev/null

# Rede
echo -e "\n=== Interfaces de rede (ip a) ===" >> "$OUTPUT"
ip a >> "$OUTPUT" 2>/dev/null

echo -e "\n=== Adaptadores de rede (lspci | grep Ethernet) ===" >> "$OUTPUT"
lspci | grep -i ethernet >> "$OUTPUT" 2>/dev/null

# USB
echo -e "\n=== Dispositivos USB (lsusb) ===" >> "$OUTPUT"
lsusb >> "$OUTPUT" 2>/dev/null

# Informações gerais
echo -e "\n=== lshw ===" >> "$OUTPUT"
sudo lshw -short >> "$OUTPUT" 2>/dev/null

# Opcional: info visual via inxi
if command -v inxi >/dev/null; then
  echo -e "\n=== inxi -Fxz ===" >> "$OUTPUT"
  inxi -Fxz >> "$OUTPUT" 2>/dev/null
fi

echo -e "\nColeta finalizada em: $(date)" >> "$OUTPUT"
echo "Coleta finalizada. Veja o arquivo $OUTPUT"

