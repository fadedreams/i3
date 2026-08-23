#!/usr/bin/env bash
#
# both-monitors.sh
#
# Enables BOTH the laptop panel and the external monitor together,
# extending the desktop (external monitor placed to the right of laptop).
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

if [ -z "$LAPTOP" ]; then
    echo "Could not detect laptop panel output. Aborting."
    exit 1
fi

if [ -z "$EXTERNAL" ]; then
    echo "No external monitor detected. Enabling laptop panel only."
    xrandr --output "$LAPTOP" --auto --primary
    notify-send -t 2000 "Display" "No external monitor found, laptop panel ($LAPTOP) active" 2>/dev/null || true
    exit 0
fi

echo "Enabling both: laptop ($LAPTOP) + external ($EXTERNAL), extended layout"

# Laptop panel stays primary, external monitor extends to the right of it.
# Change --right-of to --left-of / --above / --below if you prefer a
# different physical arrangement, or use --same-as "$LAPTOP" for mirroring.
xrandr --output "$LAPTOP" --auto --primary --output "$EXTERNAL" --auto --right-of "$LAPTOP"

notify-send -t 2000 "Display" "Extended: $LAPTOP + $EXTERNAL" 2>/dev/null || true
