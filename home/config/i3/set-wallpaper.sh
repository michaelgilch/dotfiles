#!/bin/bash

WALLPAPER_DIR="$HOME"/.wallpaper/

WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
echo "$WALLPAPER"

feh --bg-fill "$WALLPAPER"


