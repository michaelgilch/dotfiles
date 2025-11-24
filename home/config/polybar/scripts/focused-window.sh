#!/bin/bash

# Get the monitor this script is running on from environment
CURRENT_MONITOR="${MONITOR}"

# Get the currently focused window
focused_window=$(xdotool getactivewindow 2>/dev/null)

if [ -z "$focused_window" ]; then
    echo ""
    exit 0
fi

# Get the window's position
window_info=$(xwininfo -id "$focused_window" 2>/dev/null)
if [ -z "$window_info" ]; then
    echo ""
    exit 0
fi

# Extract window position
window_x=$(echo "$window_info" | grep "Absolute upper-left X" | awk '{print $4}')

# Get monitor geometries
monitor_geometry=$(xrandr --query | grep "^$CURRENT_MONITOR connected" | grep -oP '\d+x\d+\+\d+\+\d+')
monitor_x=$(echo "$monitor_geometry" | cut -d'+' -f2)
monitor_width=$(echo "$monitor_geometry" | cut -d'x' -f1)
monitor_end=$((monitor_x + monitor_width))

# Check if window is on this monitor
if [ "$window_x" -ge "$monitor_x" ] && [ "$window_x" -lt "$monitor_end" ]; then
    # Window is on this monitor, show title
    xdotool getwindowname "$focused_window" | cut -c 1-60
else
    # Window is on different monitor, show nothing or last focused
    echo ""
fi
