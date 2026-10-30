# Launchboard

A native macOS app launcher. Organize, search, and launch your installed apps
from one glass-styled window, keyboard first. All data stays on your Mac.

Designed as a high-fidelity interactive prototype, then built natively in
SwiftUI from that handoff.

## Repo layout

| Path | What it is |
|---|---|
| `Launchboard/` | The app. Xcode project generated from `project.yml`, SwiftUI, MVVM. |
| `design_handoff_launchboard/` | The hi-fi prototype (HTML) and the developer handoff spec it was built from. |
| `Docs/` | Accessibility and performance audits from the first build, and App Store listing copy. |
| `archive/v1/` | The first build's engine, tests and release scripts, kept for reference. See its README. |

## Build

Requires macOS 14 or later and Xcode 15 or later.

```bash
open Launchboard/Launchboard.xcodeproj
```

If you change `project.yml`, regenerate the project with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd Launchboard && xcodegen
```

## History

Launchboard started as a Swift package build (v1) with a full test suite,
accessibility and performance audits, and a release pipeline. The interface was
then redesigned as a hi-fi prototype and rebuilt in this project (v2). The two
were consolidated into this repo, with v1 kept under `archive/v1/`.
