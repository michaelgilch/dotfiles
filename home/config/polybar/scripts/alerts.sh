#!/usr/bin/env bash
dir="$HOME/.local/share/polybar-alerts"
mkdir -p "$dir"

# VPN alert: check for ppp/tun interfaces
vpn_alert="$dir/vpn.alert"
vpn_connected=false
for iface in /sys/class/net/ppp* /sys/class/net/tun*; do
    [ -e "$iface" ] && vpn_connected=true && break
done
if $vpn_connected; then
    echo "#A3BE8C|%{A1:jg-vpn-popup:}󰌆 VPN%{A}" > "$vpn_alert"
else
    rm -f "$vpn_alert"
fi

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
