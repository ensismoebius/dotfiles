dialog --title "Enable ADB over wifi" --msgbox "First of all: Connect your device using an USB cable then close this dialog" 8 100
killall adb
ip=$(adb shell ip addr show wlan0 | grep inet | grep wlan0 | awk '{print $2}' | cut -d/ -f1)
adb shell setprop service.adb.tcp.port 5037
adb tcpip 5037
adb connect $ip:5037
dialog --title "Enable ADB over wifi" --msgbox "You may disconnect the USB cable now if you wish" 8 100
