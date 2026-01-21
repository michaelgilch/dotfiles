#!/bin/bash

new_name=$(echo "" | rofi -dmenu -p "Rename workspace")
if [ -n "$new_name" ]; then
    i3-msg "rename workspace to \"$new_name\""
fi
