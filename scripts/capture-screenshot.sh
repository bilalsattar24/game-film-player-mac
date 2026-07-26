#!/usr/bin/env bash
set -euo pipefail

# Capture a screenshot of the Game Film Player window.
# Usage: ./scripts/capture-screenshot.sh [welcome|playback]
#
# Prerequisites:
# - Game Film Player must be running and visible
# - Terminal/Cursor may need Screen Recording permission

NAME="${1:-welcome}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/screenshots/${NAME}.png"
APP_NAME="Game Film Player"

osascript -e "tell application \"$APP_NAME\" to activate" >/dev/null 2>&1 || true
sleep 0.6

WINDOW_ID="$(swift -e '
import CoreGraphics
let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let list = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else { exit(1) }
var best: (Int, CGFloat) = (0, 0)
for w in list {
  guard let owner = w[kCGWindowOwnerName as String] as? String, owner == "Game Film Player",
        let layer = w[kCGWindowLayer as String] as? Int, layer == 0,
        let b = w[kCGWindowBounds as String] as? [String: CGFloat],
        let width = b["Width"], let height = b["Height"], width > 200,
        let num = w[kCGWindowNumber as String] as? Int else { continue }
  let area = width * height
  if area > best.1 { best = (num, area) }
}
if best.0 > 0 { print(best.0) }
')"

if [[ -z "$WINDOW_ID" ]]; then
    echo "Could not find a window for \"$APP_NAME\"."
    echo "Launch the app first, then run this script again."
    exit 1
fi

mkdir -p "$(dirname "$OUT")"
screencapture -x -l"$WINDOW_ID" "$OUT"
echo "Saved $OUT (window $WINDOW_ID)"
