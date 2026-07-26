# Contributing to Game Film Player

Thanks for your interest in improving Game Film Player. Contributions of all kinds are welcome — bug reports, feature ideas, documentation, and code.

## Getting started

1. Fork the repository and clone your fork.
2. Open `Game Film Player.xcodeproj` in Xcode.
3. Build and run on **My Mac** (`⌘R`).
4. Create a branch for your change:

```bash
git checkout -b your-name/short-description
```

## Development requirements

- macOS 15.2 or later
- Xcode 16 or later (Swift 5, SwiftUI)
- No third-party dependencies

## Making changes

- Keep pull requests focused — one feature or fix per PR when possible.
- Match existing Swift style and naming in the project.
- Test playback, scrubbing, skip, zoom/pan, and speed controls manually before opening a PR.
- Update the README if you add user-facing behavior or keyboard shortcuts.

## Reporting bugs

Please use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- macOS version
- Xcode version (if building from source)
- Steps to reproduce
- Expected vs. actual behavior
- Video format (if relevant)

## Feature requests

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md). Film-study workflows (slow motion, frame stepping, tagging plays, etc.) are especially welcome.

## Screenshots

If your change affects the UI, consider updating images in `docs/screenshots/`. See `docs/screenshots/README.md` for capture instructions.

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be respectful and constructive.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
