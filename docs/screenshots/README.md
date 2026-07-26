# Screenshots

These images are used in the project README.

| File | Description |
|------|-------------|
| `welcome.png` | Empty state before a video is opened |
| `playback.png` | Playback with controls and optional speed boost |

## Updating screenshots

For the most accurate README images, replace these files with real captures from the app.

### Option 1 — macOS screenshot (recommended)

1. Build and run the app in Xcode (`⌘R`).
2. Resize the window to roughly **960×640** for consistency.
3. Press `⌘⇧4`, then `Space`, and click the Game Film Player window.
4. Save as `welcome.png` or `playback.png` in this folder.

### Option 2 — Script

From the repo root, after granting **Screen Recording** permission to Terminal if prompted:

```bash
./scripts/capture-screenshot.sh welcome
./scripts/capture-screenshot.sh playback
```

The script captures the frontmost Game Film Player window.
