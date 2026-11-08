#!/bin/sh

# Get the current window title
TITLE=$(i3-msg -t get_tree | jq -r '.. | select(.focused? and .focused == true) | .name // empty')
TITLE_LEN=${#TITLE}

# Estimate the total width available for i3blocks (adjust multiplier as needed)
# This is tricky as we don't know the exact pixel width easily.
# We estimate based on terminal columns, assuming a monospace font.
# You might need to tweak the 0.8 multiplier depending on your font and bar height.
TOTAL_WIDTH=$(tput cols) # Get terminal width in columns
# BAR_WIDTH=$(printf "%.0f" $(echo "$TOTAL_WIDTH * 0.8" | bc)) # Estimate usable columns

# A simpler approach: Try to get the actual bar width in pixels
BAR_INFO=$(xdotool search --class i3bar getwindowgeometry --shell)
BAR_WIDTH_PIXELS=$(echo "$BAR_INFO" | grep WIDTH | cut -d= -f2)

# Estimate average character width (e.g., 8 pixels for size 10/11 font) - ADJUST THIS!
CHAR_WIDTH=16 
BAR_WIDTH=$((BAR_WIDTH_PIXELS / CHAR_WIDTH))

# Calculate padding needed on each side
PADDING=$(( (BAR_WIDTH - TITLE_LEN) / 2 ))

# Ensure padding isn't negative
[ "$PADDING" -lt 0 ] && PADDING=0

# Create the spacer string
SPACER=$(printf '%*s' "$PADDING")

# Output the correct spacer based on the argument ($1)
if [ "$1" = "left" ]; then
    echo "$SPACER"
elif [ "$1" = "right" ]; then
    # The right spacer might need adjusting if total width isn't perfectly divisible
    # This is a basic implementation; more complex logic could adjust based on parity.
    echo "$SPACER" 
fi

exit 0
