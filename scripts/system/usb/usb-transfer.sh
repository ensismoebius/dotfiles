#!/bin/bash

# Ensure required tools are installed
command -v dialog >/dev/null 2>&1 || { echo "dialog is required but not installed. Install it first."; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "rsync is required but not installed. Install it first."; exit 1; }
command -v notify-send >/dev/null 2>&1 || { echo "notify-send is required but not installed. Install it first."; exit 1; }
command -v udiskie >/dev/null 2>&1 || { echo "udiskie is required but not installed. Install it first."; exit 1; }

# Global variables
SELECTED_ITEMS=()
TEMP_FILE="/tmp/usb_transfer_selection"
STOP_FILE="/tmp/usb_transfer_stop"
rm -f "$STOP_FILE"  # Clean up stop file at start

# Function to send notifications
send_notification() {
    local title="$1"
    local message="$2"
    notify-send -u normal "$title" "$message"
}

# Function to check if a path is a directory
is_directory() {
    [ -d "$1" ]
}

# Function to select files/directories
select_items() {
    local item
    while true; do
        item=$(dialog --title "Select Files/Directories" \
            --backtitle "USB Transfer Tool" \
            --fselect "$HOME/" 14 70 \
            2>&1 >/dev/tty)
        
        if [ $? -ne 0 ]; then
            break
        fi
        
        if [ -e "$item" ]; then
            SELECTED_ITEMS+=("$item")
            dialog --title "Item Added" \
                --msgbox "Added: $item" 6 60
        else
            dialog --title "Error" \
                --msgbox "Invalid path: $item" 6 60
        fi
        
        dialog --title "Continue?" \
            --yesno "Do you want to select more items?" 6 60
        
        if [ $? -ne 0 ]; then
            break
        fi
    done
}

# Function to display selected items
show_selected_items() {
    local items_list=""
    for item in "${SELECTED_ITEMS[@]}"; do
        items_list+="$item\n"
    done
    
    dialog --title "Selected Items" \
        --msgbox "Selected items:\n$items_list" 15 60
}

# Function to copy files to USB drive
copy_to_usb() {
    local mount_point="$1"
    local drive_name="$2"
    
    for item in "${SELECTED_ITEMS[@]}"; do
        if [ -e "$item" ]; then
            if is_directory "$item"; then
                rsync -a --info=progress2 "$item" "$mount_point/"
            else
                rsync --info=progress2 "$item" "$mount_point/"
            fi
            
            if [ $? -eq 0 ]; then
                send_notification "Transfer Complete" "Files transferred to $drive_name successfully"
            else
                send_notification "Transfer Failed" "Failed to transfer files to $drive_name"
            fi
        fi
    done
}

# Function to monitor USB drives
monitor_usb() {
    while true; do
        if [ -f "$STOP_FILE" ]; then
            break
        fi
        
        # Get list of mounted USB drives
        while IFS= read -r line; do
            if [[ $line =~ /dev/sd[a-z][0-9]+ ]]; then
                device=$(echo "$line" | awk '{print $1}')
                mount_point=$(echo "$line" | awk '{print $2}')
                drive_name=$(lsblk -no label "$device" || basename "$device")
                
                # Check if we have files to copy
                if [ ${#SELECTED_ITEMS[@]} -gt 0 ]; then
                    copy_to_usb "$mount_point" "$drive_name"
                fi
            fi
        done < <(mount | grep '^/dev/sd')
        
        sleep 2
    done
}

# Main menu
main_menu() {
    while true; do
        choice=$(dialog --title "USB Transfer Tool" \
            --backtitle "USB Transfer Tool" \
            --menu "Choose an option:" 15 60 4 \
            1 "Select Files/Directories" \
            2 "Show Selected Items" \
            3 "Start Monitoring USB" \
            4 "Stop and Exit" \
            2>&1 >/dev/tty)
        
        case $choice in
            1)
                select_items
                ;;
            2)
                show_selected_items
                ;;
            3)
                dialog --title "Monitoring" \
                    --msgbox "Monitoring USB drives. Insert a drive to start transfer.\nPress OK to continue in background." 8 60
                monitor_usb &
                ;;
            4)
                touch "$STOP_FILE"
                clear
                exit 0
                ;;
            *)
                clear
                exit 1
                ;;
        esac
    done
}

# Start the application
main_menu