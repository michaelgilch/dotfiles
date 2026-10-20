#!/usr/bin/env bash
# CPU, memory, root disk and CPU temperature for [module/resources], as one
# line so the section shares a single underline and click area. Runs with
# tail = true and prints a new line every INTERVAL seconds.

INTERVAL=5
# Disk usage changes slowly; refresh it every DISK_EVERY ticks (30s)
DISK_EVERY=6
WARN_TEMP=70

# Polybar doesn't expand ${colors.*} in script output, so the Nord colors
# are written out: frost3, frost4, frost2, frost1, aurora-red
C_CPU="#81A1C1"
C_MEM="#5E81AC"
C_DISK="#88C0D0"
C_TEMP="#8FBCBB"
C_WARN="#BF616A"

# Find the CPU package sensor by type; zone numbers differ between machines
temp_file=""
for zone in /sys/class/thermal/thermal_zone*; do
    if [ "$(cat "$zone/type" 2>/dev/null)" = "x86_pkg_temp" ]; then
        temp_file="$zone/temp"
        break
    fi
done

read_cpu() {
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    cpu_idle=$((idle + iowait))
    cpu_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
}

read_cpu
prev_idle=$cpu_idle
prev_total=$cpu_total
tick=0

while true; do
    sleep "$INTERVAL"

    # CPU: busy share of the time since the last read
    read_cpu
    d_total=$((cpu_total - prev_total))
    d_idle=$((cpu_idle - prev_idle))
    prev_idle=$cpu_idle
    prev_total=$cpu_total
    cpu=0
    [ "$d_total" -gt 0 ] && cpu=$(( (100 * (d_total - d_idle)) / d_total ))

    # Memory: same used figure as internal/memory (total - available)
    mem=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2}
               END {printf "%d", (t - a) * 100 / t}' /proc/meminfo)

    if [ $((tick % DISK_EVERY)) -eq 0 ]; then
        disk=$(df --output=pcent / | tail -n1 | tr -dc '0-9')
    fi
    tick=$((tick + 1))

    out="%{F$C_CPU}󰍛%{F-} $(printf '%2d' "$cpu")%"
    out+="  %{F$C_MEM}%{F-} ${mem}%"
    out+="  %{F$C_DISK}󰋊%{F-} / ${disk}%"

    # Temperature: red text and a red underline for the whole section when hot
    if [ -n "$temp_file" ]; then
        temp=$(( $(cat "$temp_file") / 1000 ))
        if [ "$temp" -ge "$WARN_TEMP" ]; then
            out="%{u$C_WARN}$out  %{F$C_WARN}󰸁 ${temp}°C%{F-}"
        else
            out+="  %{F$C_TEMP}󰔏%{F-} ${temp}°C"
        fi
    fi

    printf '%s\n' "$out"
done
