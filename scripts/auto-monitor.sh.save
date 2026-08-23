#!/usr/bin/env bash
#
# auto-monitor.sh
#
# Auto-detects connected displays and applies a sensible layout:
#   - Laptop panel only  -> if no external monitor is connected
#   - External only      -> if an external monitor IS connected
#
# Works regardless of exact output names (eDP-1, eDP1, HDMI-1, DP-1, etc.)
# by parsing `xrandr -q` at runtime instead of hardcoding names.

set -euo pipefail

# Find the internal laptop panel (usually eDP* or LVDS*)
LAPTOP=$(xrandr -q | grep -E "^(eDP|LVDS)" | grep " connected" | cut -d' ' -f1 || true)

# Find all *other* connected outputs (potential external monitors)
EXTERNALS=$(xrandr -q | grep " connected" | grep -Ev "^(eDP|LVDS)" | cut -d' ' -f1 || true)

# Pick the first external monitor found (if any)
EXTERNAL=$(echo "$EXTERNALS" | head -n1)

if [ -n "$EXTERNAL" ]; then
    # External monitor connected -> turn off laptop panel, use external
    echo "External monitor detected: $EXTERNAL"

    # Preferred mode is whatever xrandr marks with a '+' (native/preferred)
    xrandr --output "$LAPTOP" --off --output "$EXTERNAL" --auto --primary

    notify-send -t 2000 "Display" "External monitor ($EXTERNAL) active, laptop panel off" 2>/dev/null || true
else
    # No external monitor -> laptop panel only
    echo "No external monitor detected, using laptop panel: $LAPTOP"

    xrandr --output "$LAPTOP" --auto --primary

    notify-send -t 2000 "Display" "Laptop panel ($LAPTOP) active" 2>/dev/null || true
fi
