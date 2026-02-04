# SharedVisions

A visionOS 2.0 application for Apple Vision Pro that delivers immersive video experiences with synchronized 3D animated objects and particle effects.

## Overview

SharedVisions plays 360° video as a skybox while overlaying time-triggered RealityKit primitives with particle systems. The app demonstrates multi-window SwiftUI architecture for visionOS and time-based animation choreography.

## Requirements

- Xcode 16.0+
- visionOS 2.0 SDK
- Swift 6.0
- Apple Vision Pro hardware or simulator

## Building

```bash
# Open in Xcode
open SharedVisions.xcodeproj

# Or build from command line
xcodebuild -scheme SharedVisions -configuration Debug -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

If modifying `project.yml`, regenerate the Xcode project:
```bash
xcodegen generate
```

## Architecture

### Multi-Window Design
- **Main Window**: Documentary info display with "Begin Experience" button
- **Timecode Window**: Overlay controls during immersive playback
- **Immersive Space**: Full 360° RealityKit experience with video skybox

### Time-Based Animation System
All 3D animations are synchronized to video playback time:
- **10-20s**: Red Orb with fire particles
- **20-30s**: Blue Cube with ice sparkles
- **30-40s**: Green Cylinder with spiral particles
- **40-70s**: Purple Cone with electric particles (multi-phase animation)

### State Management
A single `VideoPlayerModel` (ObservableObject) manages:
- AVPlayer and time observation (30fps updates)
- Animation states with visibility flags and progress values (0→1)
- Window lifecycle coordination

## Video Setup

Add your own immersive video file named `test.aivu` to the `Resources/` folder. No video is packaged with the project due to size considerations.

The app loads video in priority order:
1. Bundle resources (test.aivu, .mov, .mp4, .m4v)
2. Documents directory (sideloaded content)
3. Apple sample HLS video (fallback for testing)

## Project Structure

```
SharedVisions/
├── Sources/
│   ├── SharedVisionsApp.swift   # App entry, window management
│   ├── VideoPlayerModel.swift   # Central state, animation timing
│   ├── ImmersiveView.swift      # RealityKit scene, primitives
│   ├── ContentView.swift        # Main window UI
│   └── TimecodeView.swift       # Playback controls overlay
├── Resources/
│   └── SharedVisions.entitlements
└── project.yml                   # XcodeGen configuration
```

## License

Copyright © SideResult Software
