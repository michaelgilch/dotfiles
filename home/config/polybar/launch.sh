#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Clear old logs
rm -f /tmp/polybar-*.log

echo "=== POLYBAR LAUNCH DEBUG ===" | tee /tmp/polybar-launch.log

# Get hostname to determine which machine we're on
HOSTNAME=$(hostname)

echo "Hostname: $HOSTNAME" | tee -a /tmp/polybar-launch.log

# Desktop-specific monitor names
PRIMARY_MONITOR="DP-1"
SECONDARY_MONITOR="DP-3"

# Laptop-specific monitor name
LAPTOP_MONITOR="eDP-1"

# Check how many monitors are connected
if type "xrandr" >/dev/null 2>&1; then
  MONITOR_COUNT=$(xrandr --query | grep " connected" | wc -l)
  
  echo "Connected monitors: $MONITOR_COUNT" | tee -a /tmp/polybar-launch.log
  xrandr --query | grep " connected" | tee -a /tmp/polybar-launch.log
  echo "" | tee -a /tmp/polybar-launch.log
  
  # Check if we're on the laptop (single monitor with eDP-1)
  if xrandr --query | grep -q "eDP-1 connected"; then
    echo "==> Laptop Mode (eDP-1 detected)" | tee -a /tmp/polybar-launch.log
    echo "Launching LAPTOP bar on: $LAPTOP_MONITOR" | tee -a /tmp/polybar-launch.log
    MONITOR=$LAPTOP_MONITOR polybar --reload laptop >>/tmp/polybar-laptop.log 2>&1 &
    
  elif [ "$HOSTNAME" = "socrates" ]; then
    # Desktop mode (Socrates)
    if [ $MONITOR_COUNT -eq 2 ]; then
      echo "==> Desktop Dual Monitor Mode" | tee -a /tmp/polybar-launch.log
      echo "Launching PRIMARY bar on: $PRIMARY_MONITOR" | tee -a /tmp/polybar-launch.log
      echo "Launching SECONDARY bar on: $SECONDARY_MONITOR" | tee -a /tmp/polybar-launch.log
      
      MONITOR=$PRIMARY_MONITOR polybar --reload primary >>/tmp/polybar-primary.log 2>&1 &
      MONITOR=$SECONDARY_MONITOR polybar --reload secondary >>/tmp/polybar-secondary.log 2>&1 &
    else
      echo "==> Desktop Single Monitor Mode" | tee -a /tmp/polybar-launch.log
      MONITOR=$PRIMARY_MONITOR polybar --reload primary >>/tmp/polybar-primary.log 2>&1 &
    fi
    
  else
    # Fallback for unknown system
    echo "==> Unknown system, using primary bar" | tee -a /tmp/polybar-launch.log
    SINGLE_MON=$(xrandr --query | grep " connected" | head -n1 | cut -d" " -f1)
    MONITOR=$SINGLE_MON polybar --reload primary >>/tmp/polybar-primary.log 2>&1 &
  fi
  
  echo "" | tee -a /tmp/polybar-launch.log
  sleep 2
  
  echo "=== Running Polybar Processes ===" | tee -a /tmp/polybar-launch.log
  ps aux | grep -E "polybar.*(primary|secondary|laptop)" | grep -v grep | tee -a /tmp/polybar-launch.log
  
else
  echo "ERROR: xrandr not available" | tee -a /tmp/polybar-launch.log
  polybar --reload primary >>/tmp/polybar-primary.log 2>&1 &
fi

echo "" | tee -a /tmp/polybar-launch.log
echo "=== Launch Complete ===" | tee -a /tmp/polybar-launch.log