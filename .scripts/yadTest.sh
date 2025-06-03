#!/bin/bash

# Function to validate input
validate_age() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 120 ]
}

# Run the form
form_output=$(yad --title="User Registration" \
    --form --width=400 --height=300 \
    --field="Full Name":TXT \
    --field="Age":NUM \
    --field="Gender":CB \
    --field="Subscribe to newsletter?":CHK \
    "" "25" "Male!Female!Other" "TRUE" \
    --center)

# Exit if user cancels
[ $? -ne 0 ] && exit 1

# Parse the output (fields separated by '|')
IFS="|" read -r full_name age gender subscribe <<< "$form_output"

# Validate age
if ! validate_age "$age"; then
    yad --error --text="Invalid age. Must be between 1 and 120." --center
    exit 1
fi

# Show summary
yad --title="Registration Complete" --center --image="dialog-information" \
    --text="<b>Thank you for registering!</b>\n\nName: $full_name\nAge: $age\nGender: $gender\nSubscribed: $subscribe" \
    --button=OK

exit 0

