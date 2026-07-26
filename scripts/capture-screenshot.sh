#!/usr/bin/env bash
set -euo pipefail

# Capture a screenshot of the Game Film Player window.
# Usage: ./scripts/capture-screenshot.sh [welcome|playback]
#
# Prerequisites:
# - Game Film Player must be running and visible
# - Terminal may need Screen Recording permission (System Settings → Privacy)

NAME="${1:-welcome}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/screenshots/${NAME}.png"

APP_NAME="Game Film Player"

osascript -e "tell application \"$APP_NAME\" to activate" >/dev/null 2>&1 || true
sleep 0.8

WINDOW_ID="$(osascript <<EOF
tell application "System Events"
    tell process "$APP_NAME"
        set frontmost to true
        delay 0.3
        return id of window 1
    end tell
end tell
EOF
)"

if [[ -z "$WINDOW_ID" || "$WINDOW_ID" == "missing value" ]]; then
    echo "Could not find a window for \"$APP_NAME\"."
    echo "Launch the app first, then run this script again."
    exit 1
fi

mkdir -p "$(dirname "$OUT")"
screencapture -x -l"$WINDOW_ID" "$OUT"
echo "Saved $OUT"
