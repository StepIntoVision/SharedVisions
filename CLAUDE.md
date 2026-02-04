# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SharedVisions is a visionOS 2.0 application for Apple Vision Pro that provides immersive video experiences with synchronized 3D animated objects and particle effects. The app plays 360° video as a skybox while overlaying time-triggered RealityKit primitives with particle systems.

## Build Commands

```bash
# Generate Xcode project from project.yml (if modified)
xcodegen generate

# Build from command line
xcodebuild -scheme SharedVisions -configuration Debug -destination 'platform=visionOS Simulator,name=Apple Vision Pro'

# Open in Xcode (typical workflow)
open SharedVisions.xcodeproj
```

Requirements: Xcode 16.0+, visionOS 2.0 SDK, Swift 6.0

## Architecture

### Multi-Window SwiftUI App
The app manages three separate scenes in `SharedVisionsApp.swift`:
- **Main Window** (`id: "main"`): Documentary info display with "Begin Experience" button
- **Timecode Window** (`id: "timecode"`): Overlay controls during immersive playback
- **Immersive Space** (`id: "ImmersiveVideo"`): Full 360° RealityKit experience

### State Management
Single `VideoPlayerModel` (ObservableObject) shared via `@EnvironmentObject` across all views:
- Manages AVPlayer and time observation (30fps updates)
- Publishes animation states: `showOrb`, `orbProgress`, `showCube`, `cubeProgress`, etc.
- Each animated primitive has a visibility flag and progress value (0→1)

### Time-Based Animation System
All animations are driven by video playback time, not frame timers:
- 10-20s: Red Orb (rises + approaches, fire particles)
- 20-30s: Blue Cube (orbits user, ice sparkles)
- 30-40s: Green Cylinder (bounces + pulses, spiral particles)
- 40-70s: Purple Cone (multi-phase: spiral → hold → X-rotate, electric particles)

### RealityView Update Pattern
`ImmersiveView.swift` uses RealityKit's reactive update closure:
```swift
RealityView { content in
    // Initial setup: create entities, add to content
} update: { content in
    // Per-frame: read videoModel state, update positions/rotations/scales
}
```

### Multi-Phase Animation Example
The cone demonstrates chained animation phases (see `VideoPlayerModel.swift:150-195` and `ImmersiveView.swift:90-132`):
- Phase 1: Primary animation with `coneProgress`
- Phase 2: Hold at final position (`coneHolding = true`)
- Phase 3: Secondary animation with `coneSecondaryProgress`

Each phase has independent progress values for smooth choreography.

## Key Patterns

### Video Loading Priority
`VideoPlayerModel.setupPlayer()` tries sources in order:
1. Bundle resources (test.aivu, .mov, .mp4, .m4v)
2. Documents directory (sideloaded content)
3. Apple sample HLS video (fallback)

### Particle System Control
Particles are configured at entity creation time in `ImmersiveView`. The `updateParticleEmission()` helper pauses/resumes emission based on playback state.

### Window Lifecycle
Exit is triggered via `videoModel.shouldExitExperience`, observed in `SharedVisionsApp.swift` to coordinate window transitions (dismiss immersive → show main).

## File Reference

| File | Purpose |
|------|---------|
| `Sources/SharedVisionsApp.swift` | App entry point, window management |
| `Sources/VideoPlayerModel.swift` | Central state, AVPlayer, animation timing |
| `Sources/ImmersiveView.swift` | RealityKit scene, skybox, animated primitives |
| `Sources/ContentView.swift` | Main window UI |
| `Sources/TimecodeView.swift` | Playback controls overlay |
| `project.yml` | XcodeGen configuration |
