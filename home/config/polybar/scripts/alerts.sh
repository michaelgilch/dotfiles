#!/usr/bin/env bash
dir="$HOME/.local/share/polybar-alerts"
[ -d "$dir" ] || exit 0

parts=()
for f in "$dir"/*.alert; do
    [ -f "$f" ] || continue
    IFS='|' read -r color msg < "$f"
    [ -n "$msg" ] || continue
    parts+=("%{F${color}}${msg}%{F-}")
done

[ ${#parts[@]} -eq 0 ] && echo "" && exit 0

sep="  |  "
result=""
for i in "${!parts[@]}"; do
    if [ "$i" -eq 0 ]; then
        result="${parts[$i]}"
    else
        result="${result}${sep}${parts[$i]}"
    fi
done

printf '%s' "$result"
