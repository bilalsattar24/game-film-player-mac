# Native Mac Video Player

A SwiftUI-based macOS app that lets you:

- Open local video files.
- Pinch to zoom anywhere on the video.
- Control playback speed (0.1x to 10x).
- Scrub easily through the video.
- Play and pause the video.

## Getting Started

To run this application, you will need to create an Xcode project and manually add the provided Swift files.

### Prerequisites

- macOS (latest version recommended for SwiftUI features)
- Xcode (latest version recommended)

### Setup Instructions

1.  **Create a New Xcode Project:**

    - Open Xcode.
    - Choose "Create a new Xcode project".
    - Select the "macOS" tab.
    - Choose the "App" template and click "Next".
    - Product Name: `VideoPlayerApp` (or your preferred name).
    - Team: (Your Apple Developer team, or None).
    - Organization Identifier: (e.g., `com.yourname`).
    - Interface: **SwiftUI**.
    - Life Cycle: **SwiftUI App**.
    - Language: **Swift**.
    - **Uncheck** "Use Core Data" and "Include Tests" unless you plan to add them later.
    - Click "Next".
    - Choose the `/Users/bilalsattar/Documents/mac_video_player/CascadeProjects/windsurf-project/` directory as the location to save your project. Ensure the "Create Git repository on my Mac" is checked if you want version control, or uncheck if you're managing it differently.
    - Click "Create".

2.  **Replace `ContentView.swift`:**

    - In the Xcode Project Navigator (left sidebar), find the `ContentView.swift` file that Xcode automatically created.
    - Open it.
    - Delete all of its content.
    - Copy the **entire** code block provided above for `ContentView.swift` (from `import SwiftUI` to the final `}`) and paste it into this file.

3.  **Replace `<YourProjectName>App.swift`:**

    - In the Xcode Project Navigator, find the file named `VideoPlayerAppApp.swift` (or `<YourProductName>App.swift` if you named your project differently). This is the main app entry point.
    - Open it.
    - Delete all of its content.
    - Copy the **entire** code block provided above for `VideoPlayerAppApp.swift` (from `import SwiftUI` to the final `}`) and paste it into this file.

4.  **Build and Run:**

    - Select a macOS target (e.g., "My Mac") from the scheme menu at the top of the Xcode window.
    - Click the "Play" button (or press Command-R) to build and run the application.

5.  **Open a Video:**
    - Once the app launches, click the "Open Video File" button to select a video from your Mac.

## Features

- **File Importing:** Uses `.fileImporter` to select video files.
- **Pinch-to-Zoom:** Use a two-finger pinch gesture on your trackpad over the video area to zoom in and out.
- **Playback Speed Control:** A slider allows adjusting the playback rate from 0.1x to 10.0x.
- **Scrubbing:** A slider shows the current playback time and total duration, allowing you to click or drag to seek to different parts of the video.
- **Play/Pause:** A button to toggle between playing and pausing the video.
- **Time Display:** Shows current time and total duration.

## Troubleshooting

- If you encounter build errors, ensure you have the latest version of Xcode and macOS.
- Double-check that you've correctly copied and pasted the entire code for both Swift files.
