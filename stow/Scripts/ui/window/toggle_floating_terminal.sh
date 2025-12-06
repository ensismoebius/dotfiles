#!/bin/bash

# TODO: Mark: All windows in the special as floating terminal windows, all windows marked with that class must be moved to the special workspace

# if hyprctl clients -j | jq -e '.[] | select(.class == "floating-terminal")' > /dev/null; then
    hyprctl dispatch togglespecialworkspace
# else
#     foot --app-id=floating-terminal
# fi
