#!/bin/bash

# Ensure required tools are installed
command -v zenity >/dev/null 2>&1 || { echo "zenity is required but not installed. Install it first."; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "rsync is required but not installed. Install it first."; exit 1; }
command -v notify-send >/dev/null 2>&1 || { echo "notify-send is required but not installed. Install it first."; exit 1; }
command -v udiskie >/dev/null 2>&1 || { echo "udiskie is required but not installed. Install it first."; exit 1; }

# Global variables
SELECTED_ITEMS=()
TEMP_FILE="/tmp/usb_transfer_selection"
STOP_FILE="/tmp/usb_transfer_stop"
PROGRESS_PIPE="/tmp/usb_transfer_progress"
rm -f "$STOP_FILE" # Clean up stop file at start
mkfifo "$PROGRESS_PIPE" 2>/dev/null

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
    local selection
    selection=$(zenity --file-selection --multiple --title="Select Files/Directories" --separator="|")
    
    if [ $? -eq 0 ]; then
        IFS="|" read -ra items <<< "$selection"
        for item in "${items[@]}"; do
            if [ -e "$item" ]; then
                SELECTED_ITEMS+=("$item")
            fi
        done
        
        if [ ${#SELECTED_ITEMS[@]} -gt 0 ]; then
            show_selected_items
        fi
    fi
}

# Function to display selected items
show_selected_items() {
    local items_list=""
    for item in "${SELECTED_ITEMS[@]}"; do
        items_list+="$item\n"
    done
    
    zenity --info \
        --title="Selected Items" \
        --width=400 \
        --text="Selected items:\n$items_list"
}

# Function to copy files to USB drive
copy_to_usb() {
    local mount_point="$1"
    local drive_name="$2"
    local total_size=0
    local current_progress=0
    
    # Calculate total size
    for item in "${SELECTED_ITEMS[@]}"; do
        if [ -e "$item" ]; then
            size=$(du -sb "$item" | cut -f1)
            total_size=$((total_size + size))
        fi
    done
    
    # Show progress dialog
    (
        for item in "${SELECTED_ITEMS[@]}"; do
            if [ -e "$item" ]; then
                if is_directory "$item"; then
                    rsync -a --info=progress2 "$item" "$mount_point/" 2>&1 | \
                    while IFS= read -r line; do
                        if [[ $line =~ ^.+[0-9]+%.+$ ]]; then
                            progress=$(echo "$line" | grep -o '[0-9]\+%' | tr -d '%')
                            echo "$progress"
                            echo "# Copying $(basename "$item")..."
                        fi
                    done
                else
                    rsync --info=progress2 "$item" "$mount_point/" 2>&1 | \
                    while IFS= read -r line; do
                        if [[ $line =~ ^.+[0-9]+%.+$ ]]; then
                            progress=$(echo "$line" | grep -o '[0-9]\+%' | tr -d '%')
                            echo "$progress"
                            echo "# Copying $(basename "$item")..."
                        fi
                    done
                fi
                
                if [ $? -eq 0 ]; then
                    send_notification "Transfer Complete" "Files transferred to $drive_name successfully"
                else
                    send_notification "Transfer Failed" "Failed to transfer files to $drive_name"
                    return 1
                fi
            fi
        done
    ) | zenity --progress \
        --title="Copying Files to $drive_name" \
        --text="Starting transfer..." \
        --percentage=0 \
        --auto-close \
        --auto-kill
}

# Function to monitor USB drives
monitor_usb() {
    local monitoring_pid
    
    # Start monitoring notification
    zenity --notification \
        --text="USB Transfer Tool is monitoring for new drives" \
        --timeout=5 &
    
    (
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
                        # Ask before copying
                        if zenity --question \
                            --title="New USB Drive Detected" \
                            --text="Do you want to copy the selected files to $drive_name?" \
                            --ok-label="Yes" \
                            --cancel-label="No"; then
                            copy_to_usb "$mount_point" "$drive_name"
                        fi
                    fi
                fi
            done < <(mount | grep '^/dev/sd')
            
            sleep 2
        done
    ) &
    monitoring_pid=$!
    
    # Show monitoring status window
    if zenity --question \
        --title="USB Transfer Tool" \
        --text="Monitoring USB drives. Click 'Stop' to end monitoring." \
        --ok-label="Stop" \
        --cancel-label="Keep Running" \
        --width=300; then
        touch "$STOP_FILE"
        kill $monitoring_pid 2>/dev/null
        return 0
    fi
}

# Main menu function
main_menu() {
    while true; do
        action=$(zenity --list \
            --title="USB Transfer Tool" \
            --width=400 \
            --height=300 \
            --text="Choose an action:" \
            --radiolist \
            --column="Select" \
            --column="Action" \
            TRUE "Select Files/Directories" \
            FALSE "Show Selected Items" \
            FALSE "Start Monitoring USB" \
            FALSE "Stop and Exit")
        
        case "$action" in
            "Select Files/Directories")
                select_items
                ;;
            "Show Selected Items")
                show_selected_items
                ;;
            "Start Monitoring USB")
                monitor_usb
                ;;
            "Stop and Exit")
                touch "$STOP_FILE"
                exit 0
                ;;
            *)
                exit 1
                ;;
        esac
    done
}

# Start the application
main_menu