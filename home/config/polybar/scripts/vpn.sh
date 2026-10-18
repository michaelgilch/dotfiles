#!/usr/bin/env bash
# VPN and Tailscale indicators for [module/vpn]. Each shows only while its
# connection is up and opens its rofi-netmenu menu on click.

parts=()

# VPN: check for ppp/tun interfaces
for iface in /sys/class/net/ppp* /sys/class/net/tun*; do
    if [ -e "$iface" ]; then
        parts+=("%{F#A3BE8C}%{A1:rofi-netmenu forticlient:}󰌆 VPN%{A}%{F-}")
        break
    fi
done

# Tailscale: lit whenever the backend is up. Turns green and names the node
# when traffic is being routed through an exit node.
ts_status=$(tailscale status --json 2>/dev/null)
if [ -n "$ts_status" ] && \
   [ "$(printf '%s' "$ts_status" | jq -r '.BackendState')" = "Running" ]; then
    ts_exit=$(printf '%s' "$ts_status" | jq -r '.Peer[]? | select(.ExitNode) | .HostName' | head -n1)
    if [ -n "$ts_exit" ]; then
        parts+=("%{F#A3BE8C}%{A1:rofi-netmenu tailscale:}󰖂 TS→${ts_exit}%{A}%{F-}")
    else
        parts+=("%{F#88C0D0}%{A1:rofi-netmenu tailscale:}󰖂 TS%{A}%{F-}")
    fi
fi

# Same two-space separator as alerts.sh
out=""
for p in "${parts[@]}"; do
    out="${out:+$out  }$p"
done
printf '%s\n' "$out"
