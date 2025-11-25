#!/bin/sh
# Screenshot utility for Jay compositor

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
TIMESTAMP="$(date +'%Y-%m-%d-%H-%M-%S')"
FILENAME="${SCREENSHOT_DIR}/scrn-${TIMESTAMP}.png"

# Create screenshot directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"

if [ "$1" = "area" ]; then
    # Screenshot of selected area
    slurp | grim -g - "$FILENAME"
else
    # Full screenshot
    grim "$FILENAME"
fi
