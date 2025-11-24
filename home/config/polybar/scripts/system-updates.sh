#!/bin/bash

# Check for updates
updates=$(checkupdates 2>/dev/null | wc -l)
aur_updates=$(yay -Qua 2>/dev/null | wc -l)

total=$((updates + aur_updates))

if [ $total -eq 0 ]; then
    echo ""
else
    echo "$total updates"
fi
