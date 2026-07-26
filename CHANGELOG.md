# Changelog

All notable changes to Game Film Player are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-26

### Added

- Native macOS video player for local film study
- Open local video files via system file picker
- Play / pause with spacebar
- ±5 second skip via buttons, arrow keys, or double-click on video sides
- Frame-by-frame stepping with `,` and `.` keys and toolbar buttons
- Variable playback speed from 0.1× to 3.0×
- Hold-to-boost temporary speed (2× / 3×) on video press-and-hold
- Cursor-anchored pinch-to-zoom (1×–5×) with drag-to-pan
- Timeline scrubber with timecodes
- Custom app icon
- MIT license and open-source documentation

### Technical

- SwiftUI + AVFoundation with custom `AVPlayerLayer` view
- Sandboxed app with security-scoped file access
- GitHub Actions CI for macOS builds

[1.0.0]: https://github.com/bilalsattar24/game-film-player-mac/releases/tag/v1.0.0
