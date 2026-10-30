# Launchboard

A native macOS 14+ app launcher that replaces Launchpad with a visual, organized, keyboard-first app library. Built for power users managing 30–80+ applications.

## Overview

Launchboard scans your Applications folders, organizes apps into manual and smart groups, and lets you launch anything in under two keystrokes. All data stays local — no network calls, no accounts, no cloud sync.

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI | SwiftUI (primary), AppKit (sidebar material, menu bar, hotkey bridge) |
| Persistence | SwiftData |
| State | `@Observable` (Swift 5.9 macro) |
| Minimum OS | macOS 14 Sonoma |
| Dependencies | None (zero third-party) |
| Package | Swift Package Manager + thin Xcode app target |

## Project Structure

```
Sources/
├── LaunchboardKit/          # Testable library: models, services, design system
│   ├── Models/              # SwiftData @Model types
│   ├── Services/            # AppScannerActor, SearchIndex, GlobalHotkeyService
│   └── DesignSystem/        # Tokens (Color/Font/Spacing/Radius/Shadow), Modifiers
└── Launchboard/             # App executable: entry point, views, view models
    ├── App/                 # @main, AppState
    └── Views/               # RootView, Components, Library, Settings, Onboarding, Modals
Tests/
└── LaunchboardTests/        # Unit tests for LaunchboardKit
```

## Build

```bash
# Build everything
swift build

# Run tests
swift test

# Open in Xcode
open Package.swift
```

Requires Xcode 15+ and macOS 14 SDK.

## Architecture

**MVVM**: Views are dumb (read from environment, fire intents). ViewModels are `@Observable` classes. Models are SwiftData `@Model` types. `AppState` is the single root environment object injected at the `WindowGroup` level.

**Module split**: `LaunchboardKit` is a pure library that can be unit-tested without launching the app. The `Launchboard` executable is a thin shell that wires views and the model container together.

## Keyboard Contract

| Shortcut | Action |
|---|---|
| ⌥ Space | Global invoke (configurable) |
| ⌘N | New group |
| ⌘D | Add to favorites |
| ⌘\ | Toggle grid / list |
| ⌘F | Focus search |
| Arrow keys | Navigate grid |
| Return | Launch selected app |
| Esc | Clear search |

## Performance Budgets

- App scan: < 1s for 200 apps
- Search results: < 50ms
- Cold launch to window: < 200ms
- Memory: < 80MB resident with 200 apps loaded

## Out of Scope (V1)

iCloud sync · widgets · Shortcuts integration · iOS companion · Homebrew Cask discovery · custom theming beyond system light/dark
