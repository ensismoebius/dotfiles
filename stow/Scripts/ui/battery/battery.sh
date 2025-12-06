#!/usr/bin/env bash

# Battery discharge monitor with moving average
# Save as: battery-mah-monitor.sh

# Force decimal separator to dot for calculations
export LC_NUMERIC=C

# Configuration
BATTERY="BAT0"
SAMPLE_INTERVAL=1          # seconds between samples
AVG_WINDOW=20              # number of samples for moving average
HISTORY_FILE="/tmp/battery_history.log"

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Initialize variables
declare -a mah_history
declare -a time_history
declare -a discharge_rate_history
last_mah=0
last_time=0
sample_count=0
total_mah_used=0

# Check if battery exists
if [[ ! -d "/sys/class/power_supply/$BATTERY" ]]; then
    echo "Battery $BATTERY not found!"
    echo "Available batteries:"
    ls /sys/class/power_supply/ | grep -E '^BAT'
    exit 1
fi

# Function to format number with locale-appropriate decimal separator
format_number() {
    local number=$1
    local decimals=${2:-2}
    
    # For display, we can use the system's locale
    if [[ "$LANG" =~ "pt_BR" ]] || [[ "$LANG" =~ "pt_PT" ]] || [[ "$LANG" =~ "es_" ]] || [[ "$LANG" =~ "de_" ]] || [[ "$LANG" =~ "fr_" ]]; then
        # Locales that use comma as decimal separator
        echo "$number" | sed 's/\./,/g' | awk -v d="$decimals" '{printf "%.*f", d, $1}'
    else
        # Default: dot as decimal separator
        awk -v d="$decimals" '{printf "%.*f", d, $1}' <<< "$number"
    fi
}

# Function to get current capacity in μAh (returns integer for calculations)
get_current_mah() {
    local energy_wh voltage_v energy_raw
    
    # Try to get energy in Wh (more common)
    if [[ -f "/sys/class/power_supply/$BATTERY/energy_now" ]]; then
        energy_raw=$(cat "/sys/class/power_supply/$BATTERY/energy_now" 2>/dev/null)
        energy_wh=$(echo "scale=6; $energy_raw / 1000000" | bc -l 2>/dev/null || echo "0")
    elif [[ -f "/sys/class/power_supply/$BATTERY/charge_now" ]]; then
        # Some systems report in μAh directly
        charge_raw=$(cat "/sys/class/power_supply/$BATTERY/charge_now" 2>/dev/null)
        # Report μAh directly
        echo "$charge_raw" || echo "0"
        return
    else
        echo "0"
        return
    fi
    
    voltage_raw=$(cat "/sys/class/power_supply/$BATTERY/voltage_now" 2>/dev/null)
    voltage_v=$(echo "scale=6; $voltage_raw / 1000000" | bc -l 2>/dev/null || echo "0")
    
    if [[ "$energy_wh" == "0" ]] || [[ "$voltage_v" == "0" ]]; then
        echo "0"
        return
    fi
    # Calculate μAh: (Wh * 1_000_000) / V
    echo "scale=0; ($energy_wh * 1000000) / $voltage_v" | bc -l 2>/dev/null || echo "0"
}

# Function to get battery status
get_battery_status() {
    cat "/sys/class/power_supply/$BATTERY/status" 2>/dev/null
}

# Function to get design capacity in μAh
get_design_mah() {
    local energy_wh voltage_v energy_raw

    if [[ -f "/sys/class/power_supply/$BATTERY/energy_full_design" ]]; then
        energy_raw=$(cat "/sys/class/power_supply/$BATTERY/energy_full_design" 2>/dev/null)
        energy_wh=$(echo "scale=6; $energy_raw / 1000000" | bc -l 2>/dev/null || echo "0")
    elif [[ -f "/sys/class/power_supply/$BATTERY/charge_full_design" ]]; then
        # Some systems report in μAh directly
        charge_raw=$(cat "/sys/class/power_supply/$BATTERY/charge_full_design" 2>/dev/null)
        # Report μAh directly
        echo "$charge_raw" || echo "0"
        return
    else
        echo "0"
        return
    fi

    voltage_raw=$(cat "/sys/class/power_supply/$BATTERY/voltage_now" 2>/dev/null)
    voltage_v=$(echo "scale=6; $voltage_raw / 1000000" | bc -l 2>/dev/null || echo "0")

    if [[ "$energy_wh" == "0" ]] || [[ "$voltage_v" == "0" ]]; then
        echo "0"
        return
    fi

    # Calculate μAh: (Wh * 1_000_000) / V
    echo "scale=0; ($energy_wh * 1000000) / $voltage_v" | bc -l 2>/dev/null || echo "0"
}

# Function to get percentage
get_percentage() {
    cat "/sys/class/power_supply/$BATTERY/capacity" 2>/dev/null || echo "0"
}

# Function to calculate moving average discharge rate
calculate_discharge_rate() {
    local sum=0
    local count=0
    
    # Calculate average from last AVG_WINDOW samples
    for rate in "${discharge_rate_history[@]: -$AVG_WINDOW}"; do
        sum=$(echo "$sum + $rate" | bc -l 2>/dev/null || echo "0")
        count=$((count + 1))
    done
    
    if [[ $count -gt 0 ]]; then
        echo "scale=2; $sum / $count" | bc -l 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to estimate time remaining
estimate_time_remaining() {
    local current_mah=$1
    local discharge_rate=$2
    
    # Use bc with -l for proper floating point comparison
    if [[ $(echo "$discharge_rate > 0.1" | bc -l 2>/dev/null) -eq 1 ]]; then
        local hours=$(echo "scale=2; $current_mah / $discharge_rate" | bc -l 2>/dev/null || echo "0")
        local int_hours=${hours%.*}
        local frac_hours="0.${hours#*.}"
        local minutes=$(echo "scale=0; $frac_hours * 60" | bc -l 2>/dev/null || echo "0")
        
        # Remove decimal from minutes
        minutes=${minutes%.*}
        
        if [[ $int_hours -gt 0 ]]; then
            printf "%dh %02dm" "$int_hours" "$minutes"
        else
            printf "%dm" "$minutes"
        fi
    else
        printf "∞"
    fi
}

# Clear screen and setup
clear
echo -e "${BOLD}${CYAN}Arch Linux Battery uAh Monitor${NC}"
echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
echo

# Get initial design capacity (in μAh)
design_mah=$(get_design_mah)
design_display=$(format_number "$design_mah" 0)
echo -e "Design capacity: ${GREEN}$design_display μAh${NC}"

# Initial reading
current_mah=$(get_current_mah)
last_mah=$current_mah
start_mah=$current_mah
last_time=$(date +%s.%N)

# Main monitoring loop
while true; do
    # Get current values
    current_mah=$(get_current_mah)
    current_time=$(date +%s.%N)
    status=$(get_battery_status)
    percentage=$(get_percentage)
    
    # Calculate time delta
    time_delta=$(echo "scale=4; $current_time - $last_time" | bc -l 2>/dev/null || echo "1")
    
    # Prevent spurious increases when not charging: keep values monotonic unless Charging
    if [[ "$status" != "Charging" ]] && [[ $(echo "$current_mah > $last_mah" | bc -l 2>/dev/null) -eq 1 ]]; then
        current_mah=$last_mah
    fi
    
    # Calculate discharge rate (μAh per hour)
    if [[ $(echo "$time_delta > 0.1" | bc -l 2>/dev/null) -eq 1 ]] && [[ $(echo "$last_mah != 0" | bc -l 2>/dev/null) -eq 1 ]]; then
        mah_delta=$(echo "scale=4; $last_mah - $current_mah" | bc -l 2>/dev/null || echo "0")
        
        # Only process if we have a measurable change (threshold ~10 μAh)
        if [[ $(echo "scale=4; sqrt($mah_delta^2) > 10" | bc -l 2>/dev/null) -eq 1 ]]; then
            # Store in history arrays
            mah_history+=("$current_mah")
            time_history+=("$current_time")
            
            # Calculate instant discharge rate (μAh/h)
            instant_rate=$(echo "scale=2; ($mah_delta / $time_delta) * 3600" | bc -l 2>/dev/null || echo "0")
            discharge_rate_history+=("$instant_rate")
            
            # Update total mah used if discharging
            if [[ "$status" == "Discharging" ]] && [[ $(echo "$mah_delta > 0" | bc -l 2>/dev/null) -eq 1 ]]; then
                total_mah_used=$(echo "scale=2; $total_mah_used + $mah_delta" | bc -l 2>/dev/null || echo "$total_mah_used")
            fi
            
            # Calculate moving average (μAh/h)
            avg_rate=$(calculate_discharge_rate)
            
            # Estimate time remaining (inputs are in μAh and μAh/h)
            time_remaining=$(estimate_time_remaining "$current_mah" "$avg_rate")
            
            # Format numbers for display (values are already in μAh/μAh-h)
            current_display=$(format_number "$current_mah" 0)
            avg_rate_display=$(format_number "$avg_rate" 0)
            total_used_display=$(format_number "$total_mah_used" 0)
            
            # Clear line and display
            echo -ne "\033[2K\r"
            
            # Color code based on status
            case "$status" in
                "Discharging")
                    status_color=$RED
                        # Show discharge rate with sign
                        if [[ $(echo "$avg_rate > 0" | bc -l 2>/dev/null) -eq 1 ]]; then
                            rate_display=$(printf "%7s" "$avg_rate_display")
                        else
                            rate_display="       0"
                        fi
                    echo -ne "${status_color}▼ ${NC}"
                    ;;
                "Charging")
                    status_color=$GREEN
                    # Calculate charge rate
                    if [[ $(echo "$mah_delta < 0" | bc -l 2>/dev/null) -eq 1 ]]; then
                        charge_rate=$(echo "scale=1; -1 * $instant_rate" | bc -l 2>/dev/null || echo "0")
                        charge_display=$(format_number "$charge_rate" 0)
                        rate_display=$(printf "+%6s" "$charge_display")
                    else
                        rate_display="   +0.0  "
                    fi
                    echo -ne "${status_color}▲ ${NC}"
                    ;;
                "Full")
                    status_color=$BLUE
                    rate_display="   F   "
                    echo -ne "${status_color}■ ${NC}"
                    ;;
                *)
                    status_color=$YELLOW
                    rate_display="   ?   "
                    echo -ne "${status_color}? ${NC}"
                    ;;
            esac
            
            # Display main counter - FIXED printf format
            printf "${BOLD}${CYAN}%9s μAh${NC} ${YELLOW}[%3d%%]${NC}" "$current_display" "$percentage"
            printf " | Rate: ${BOLD}%8s μAh/h${NC}" "$rate_display"
            printf " | Used: ${YELLOW}%7s μAh${NC}" "$total_used_display"
            
            if [[ "$status" == "Discharging" ]] && [[ $(echo "$avg_rate > 100" | bc -l 2>/dev/null) -eq 1 ]]; then
                printf " | Time left: ${GREEN}%s${NC}" "$time_remaining"
            elif [[ "$status" == "Charging" ]] && [[ $(echo "$avg_rate < -100" | bc -l 2>/dev/null) -eq 1 ]]; then
                charge_rate=$(echo "scale=1; -1 * $avg_rate" | bc -l 2>/dev/null || echo "0")
                if [[ $(echo "$charge_rate > 100" | bc -l 2>/dev/null) -eq 1 ]]; then
                    time_to_full=$(estimate_time_remaining "$(echo "$design_mah - $current_mah" | bc -l 2>/dev/null)" "$charge_rate")
                    printf " | Time to full: ${GREEN}%s${NC}" "$time_to_full"
                fi
            fi
            
            # Update last values
            last_mah=$current_mah
            last_time=$current_time
            sample_count=$((sample_count + 1))
            
            # Log to history file (optional)
            if [[ -n "$HISTORY_FILE" ]]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S'),$current_mah,$percentage,$avg_rate,$status" >> "$HISTORY_FILE"
            fi
        fi
    fi
    
    # Sleep
    sleep "$SAMPLE_INTERVAL"
done
