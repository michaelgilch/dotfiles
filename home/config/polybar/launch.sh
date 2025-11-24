#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Clear old logs
rm -f /tmp/polybar-*.log

echo "=== POLYBAR LAUNCH DEBUG ===" | tee /tmp/polybar-launch.log

# Your specific monitor names
PRIMARY_MONITOR="DP-1"
SECONDARY_MONITOR="DP-3"

# Check how many monitors are connected
if type "xrandr" >/dev/null 2>&1; then
  MONITOR_COUNT=$(xrandr --query | grep " connected" | wc -l)
  
  echo "Connected monitors: $MONITOR_COUNT" | tee -a /tmp/polybar-launch.log
  xrandr --query | grep " connected" | tee -a /tmp/polybar-launch.log
  echo "" | tee -a /tmp/polybar-launch.log
  
  if [ $MONITOR_COUNT -eq 1 ]; then
    # Single monitor (laptop)
    SINGLE_MON=$(xrandr --query | grep " connected" | cut -d" " -f1)
    echo "==> Single Monitor Mode" | tee -a /tmp/polybar-launch.log
    echo "Launching PRIMARY bar on: $SINGLE_MON" | tee -a /tmp/polybar-launch.log
    MONITOR=$SINGLE_MON polybar --reload primary >>/tmp/polybar-primary.log 2>&1 &
    
  elif [ $MONITOR_COUNT -eq 2 ]; then
    # Dual monitor (desktop)
    echo "==> Dual Monitor Mode" | tee -a /tmp/polybar-launch.log
    echo "Launching PRIMARY bar on: $PRIMARY_MONITOR" | tee -a /tmp/polybar-launch.log
    echo "Launching SECONDARY bar on: $SECONDARY_MONITOR" | tee -a /tmp/polybar-launch.log
    
    MONITOR=$PRIMARY_MONITOR polybar --reload primary >>/tmp/polybar-primary.log 2>&1 &
    MONITOR=$SECONDARY_MONITOR polybar --reload secondary >>/tmp/polybar-secondary.log 2>&1 &
    
  else
    # More than 2 monitors
    echo "==> Multiple Monitor Mode ($MONITOR_COUNT monitors)" | tee -a /tmp/polybar-launch.log
    MONITOR=$PRIMARY_MONITOR polybar --reload primary >>/tmp/polybar-primary.log 2>&1 &
    for monitor in $(xrandr --query | grep " connected" | grep -v "$PRIMARY_MONITOR" | cut -d" " -f1); do
      echo "Launching SECONDARY bar on: $monitor" | tee -a /tmp/polybar-launch.log
      MONITOR=$monitor polybar --reload secondary >>/tmp/polybar-secondary.log 2>&1 &
    done
  fi
  
  echo "" | tee -a /tmp/polybar-launch.log
  sleep 2
  
  echo "=== Running Polybar Processes ===" | tee -a /tmp/polybar-launch.log
  ps aux | grep -E "polybar.*(primary|secondary)" | grep -v grep | tee -a /tmp/polybar-launch.log
  
else
  echo "ERROR: xrandr not available" | tee -a /tmp/polybar-launch.log
  polybar --reload primary >>/tmp/polybar-primary.log 2>&1 &
fi

echo "" | tee -a /tmp/polybar-launch.log
echo "=== Launch Complete ===" | tee -a /tmp/polybar-launch.log

