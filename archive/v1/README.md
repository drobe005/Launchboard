# Launchboard v1 (archived)

The first build of Launchboard, kept here for reference after v1 and v2 were
consolidated into this repo. The app in the root of this repo (v2) is the
current version. Nothing in this folder is part of the v2 build.

## What v1 was

A Swift Package Manager app with a testable engine library (`LaunchboardKit`)
and a thin SwiftUI app target. It used SwiftData for storage and had zero
third-party dependencies. See `ORIGINAL_README.md` for the full v1 overview and
keyboard contract.

## What is kept

| Path | What it is |
|---|---|
| `Sources/LaunchboardKit/` | The v1 engine: SwiftData models, app scanner, search index, smart group evaluator, FSEvents watcher, icon cache, global hotkey service, design tokens. Includes the last local changes that ported the v2 dark glass tokens into v1. |
| `Tests/LaunchboardTests/` | The v1 test suite (112 tests at the time of the audits). |
| `scripts/release.sh`, `scripts/notarize-setup.sh` | Build, sign, notarize and package for Developer ID distribution. Written against the v1 package layout, so paths need updating before use with v2. Contains no credentials. |
| `scripts/generate_icons.swift`, `scripts/generate_screenshots.swift` | Icon and App Store screenshot generators. |
| `../../Docs/A11Y_AUDIT_v1.md`, `../../Docs/PERF_AUDIT_v1.md` | Accessibility and performance audits run against v1. |
| `../../Docs/APP_STORE_METADATA.md` | App Store listing copy. |

The v1 app views, assets and placeholder screenshots were not kept.

## Running the v1 tests

```bash
cd archive/v1
swift test
```

`Package.swift` here builds only the engine and its tests.

## Why this exists

The plan for later is to move the v2 interface onto this engine: v1's models,
services and tests with v2's glass UI. Until then, this folder keeps that work
from being lost.
