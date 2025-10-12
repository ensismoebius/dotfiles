#! /bin/bash
pactl set-source-mute $(pactl get-default-source) 0
pactl set-source-volume $(pactl get-default-source) 25%
