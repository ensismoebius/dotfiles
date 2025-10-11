#!/bin/bash

if pgrep -x "nm-applet" > /dev/null
then
    killall -q nm-applet
else
    nm-applet &
fi
