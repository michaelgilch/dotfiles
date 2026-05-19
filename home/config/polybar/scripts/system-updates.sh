#!/bin/bash

# Explicitly installed package names (covers both repo and AUR packages)
explicit=$(pacman -Qeq 2>/dev/null)

# Available updates
repo_updates=$(checkupdates 2>/dev/null)
aur_updates=$(yay -Qua 2>/dev/null)

# Updates limited to explicitly-installed packages (implicit deps filtered out)
repo_explicit=$(echo "$repo_updates" | awk 'NF{print $1}' | grep -Fxf <(echo "$explicit") | wc -l)
aur_explicit=$(echo "$aur_updates" | awk 'NF{print $1}' | grep -Fxf <(echo "$explicit") | wc -l)

# Total updates, including implicitly-installed dependencies
total=$(($(echo "$repo_updates" | grep -c .) + $(echo "$aur_updates" | grep -c .)))

if [ "$total" -eq 0 ]; then
    echo ""
else
    echo "$repo_explicit·$aur_explicit·$total"
fi
