#!/bin/bash

# Get updates
pacman_updates=$(checkupdates 2>/dev/null)
aur_updates=$(yay -Qua 2>/dev/null)

pacman_count=$(echo "$pacman_updates" | grep -v "^$" | wc -l)
aur_count=$(echo "$aur_updates" | grep -v "^$" | wc -l)
total=$((pacman_count + aur_count))

if [ $total -eq 0 ]; then
    notify-send "System Updates" "✓ No updates available" \
        -i software-update-available \
        -u low \
        -t 3000 \
        -a "System Updates"
    exit 0
fi

# Build message
message="<b>Total: $total updates</b>\n"
message+="Official: $pacman_count • AUR: $aur_count\n"

if [ $pacman_count -gt 0 ]; then
    message+="\n<u>Official Packages:</u>\n"
    count=0
    while IFS= read -r line && [ $count -lt 5 ]; do
        pkg=$(echo "$line" | awk '{print $1}')
        old=$(echo "$line" | awk '{print $2}')
        new=$(echo "$line" | awk '{print $4}')
        message+="  <span foreground='#88C0D0'>$pkg</span>  <span foreground='#4C566A'>$old → $new</span>\n"
        count=$((count + 1))
    done <<< "$pacman_updates"
    
    if [ $pacman_count -gt 5 ]; then
        remaining=$((pacman_count - 5))
        message+="  <i>... and $remaining more</i>\n"
    fi
fi

if [ $aur_count -gt 0 ]; then
    message+="\n<u>AUR Packages:</u>\n"
    count=0
    while IFS= read -r line && [ $count -lt 5 ]; do
        pkg=$(echo "$line" | awk '{print $1}')
        old=$(echo "$line" | awk '{print $2}')
        new=$(echo "$line" | awk '{print $4}')
        message+="  <span foreground='#88C0D0'>$pkg</span>  <span foreground='#4C566A'>$old → $new</span>\n"
        count=$((count + 1))
    done <<< "$aur_updates"
    
    if [ $aur_count -gt 5 ]; then
        remaining=$((aur_count - 5))
        message+="  <i>... and $remaining more</i>\n"
    fi
fi

message+="\n<i>Left-click to update</i>"

# Send notification with dunst
notify-send "System Updates Available" "$message" \
    -i software-update-available \
    -u normal \
    -t 15000 \
    -a "System Updates"
