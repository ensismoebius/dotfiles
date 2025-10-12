#!/bin/bash

declare -A monitors

# percorre cada monitor
while read -r monitor; do
  # aqui assumimos que o hyprctl já retorna strings "WIDTHxHEIGHT@REFRESH"
  readarray -t modes < <(hyprctl monitors -j | jq -r --arg monitor "$monitor" \
    '.[] | select(.name == $monitor) | .availableModes[]' | sed 's/Hz//g' )
  
  monitors["$monitor"]="${modes[*]}"
done < <(hyprctl monitors -j | jq -r '.[].name')

yadMonitors=()
declare -A yadModes

# preenche arrays para yad
for m in "${!monitors[@]}"; do
  yadMonitors+=("$m")
  yadModes[$m]=""
  
  for mode in ${monitors[$m]}; do
    yadModes[$m]+="${m},${mode}!"
  done
done

# monta o comando yad dinamicamente
yad_cmd="yad --form --title='Seleção de modos' "

for monitor in "${yadMonitors[@]}"; do
  modos="${yadModes[$monitor]}"
  modos="${modos%!}"  # remove último "!" extra
  yad_cmd+="--field=\"$monitor:CB\" \"$modos\" "
done

# executa o yad
res=$(eval "$yad_cmd") || exit
res="${res%"|"}"

# Itera pelos elementos separados por pipe
IFS='|' read -ra elements <<< "$res"

for elem in "${elements[@]}"; do
  eval "hyprctl keyword monitor $elem,auto,1"
done

# hyprctl keyword monitor HDMI-A-1,1440x900@60,auto,1 
# echo $res

