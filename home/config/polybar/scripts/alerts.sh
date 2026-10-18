#!/usr/bin/env bash
dir="$HOME/.local/share/polybar-alerts"
mkdir -p "$dir"

# repo-check alert: re-derive from report.json every refresh so the count
# stays in sync with the latest report (timed fetch, manual run, or menu
# re-check) and clears itself when all repos go clean.
repo-check-alert 2>/dev/null || true

parts=()
for f in "$dir"/*.alert; do
    [ -f "$f" ] || continue
    IFS='|' read -r color msg < "$f"
    [ -n "$msg" ] || continue
    parts+=("%{F${color}}${msg}%{F-}")
done

[ ${#parts[@]} -eq 0 ] && echo "" && exit 0

sep="  "
result=""
for i in "${!parts[@]}"; do
    if [ "$i" -eq 0 ]; then
        result="${parts[$i]}"
    else
        result="${result}${sep}${parts[$i]}"
    fi
done

printf '%s' "$result"
