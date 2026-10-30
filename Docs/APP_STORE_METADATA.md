# Launchboard — App Store Metadata

---

## App Name
Launchboard

---

## Subtitle
*(30 characters max — 25 used)*

```
Visual launcher for macOS
```

---

## Description
*(4000 characters max — ~3300 used)*

```
Launchpad is gone. The dock is overcrowded. Spotlight is for finding, not launching.

Launchboard is a focused app launcher that puts every app you own one keystroke away — organized the way you actually think, not by date installed.

────────────────────────────

VISUAL APP GRID

See all your apps at a glance in a clean, scrollable grid. Color-coded tiles make your most-used apps easy to spot. Double-click to launch, drag to organize.

────────────────────────────

FAVORITES BAR

Pin up to 12 apps to a persistent Favorites bar for instant one-click access. Drag to reorder. Works across every view.

────────────────────────────

GROUPS

Create named groups to separate your work apps from your creative tools, your dev environment from your personal stuff. Drag apps in from anywhere — from the grid, the sidebar, even Finder.

────────────────────────────

SMART GROUPS

Smart Groups populate themselves automatically based on rules you define: file size, last opened date, app name, or source (Apple built-in vs third-party). They update live as you install or remove apps.

────────────────────────────

SEARCH THAT ACTUALLY WORKS

Start typing anywhere in the app to instantly filter. Fuzzy matching surfaces apps even when you mistype. Results rank by recency so the things you use most bubble up.

────────────────────────────

MENU-BAR SHORTCUT

Launchboard lives in your menu bar. One global shortcut — yours to configure — brings the grid up wherever you are, then hides it the moment you launch something or press Escape.

────────────────────────────

DESIGNED FOR MACOS

Built with SwiftUI from the ground up for macOS 14 Sonoma and later. NavigationSplitView layout, native drag-and-drop, full keyboard navigation, VoiceOver support, and Reduce Motion respected throughout. Light and dark mode, accent color theming, and Dynamic Type all work as expected.

────────────────────────────

PRIVACY FIRST

Launchboard scans only your /Applications folder (and any folders you add). No analytics. No network requests. All data stored locally in SwiftData — never leaves your Mac.

────────────────────────────

PERFECT FOR:
• Power users who've outgrown the Dock
• Developers juggling multiple toolchains
• Designers with large Creative Suite installs
• Anyone who just wants to find their apps faster
```

---

## Keywords
*(100 characters max — comma-separated, no spaces after commas)*

```
launcher,app,dock,spotlight,productivity,organize,mac,launchpad,apps,workflow
```

*(78 characters — within limit)*

---

## Categories

| Field              | Value        |
|--------------------|--------------|
| Primary Category   | Productivity |
| Secondary Category | Utilities    |

---

## Age Rating
4+ (no objectionable content)

---

## URLs
*(Replace placeholders before submission)*

| Field           | Value                                          |
|-----------------|------------------------------------------------|
| Support URL     | https://launchboard.app/support                |
| Marketing URL   | https://launchboard.app                        |
| Privacy Policy  | https://launchboard.app/privacy                |

---

## Version Release Notes (1.0)

```
Welcome to Launchboard — your visual app launcher for macOS.

• Organize apps into named Groups and automatic Smart Groups
• Pin favorites to the always-visible Favorites bar
• Global menu-bar shortcut with customizable hotkey
• Fuzzy search with instant results
• Full VoiceOver and keyboard navigation support
```

---

## Screenshot captions
*(Shown on App Store product page in supported regions — 255 chars max each)*

| File                        | Caption                                                                                                                                   |
|-----------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| 01_all_apps.png             | All your apps in one clean grid. Favorites pinned at the top. Launch anything in two clicks — or one keystroke.                          |
| 02_design_group.png         | Group apps by project, discipline, or workflow. Drag in apps from anywhere, give the group an emoji, done.                               |
| 03_search_results.png       | Start typing anywhere and results appear instantly. Fuzzy matching means a typo never slows you down.                                    |
| 04_smart_group_editor.png   | Smart Groups auto-populate from rules: file size, last opened, name, or source. They update live as your library changes.                |
| 05_first_time_setup.png     | First launch suggests groups based on your existing apps. Accept, adjust, or skip — you're in control from the start.                   |

---

## App Store Connect checklist

- [ ] Bundle ID: `com.yourteam.launchboard` (update in Xcode project)
- [ ] Version: 1.0 (0)
- [ ] macOS deployment target: 14.0
- [ ] App sandbox: enabled (read-only access to /Applications, user-selected files)
- [ ] Notarization: required for Mac App Store distribution
- [ ] Screenshots uploaded at 2880×1800 (one per screen above)
- [ ] App icon: 1024×1024 PNG supplied in `AppIcon.appiconset` (generated via `swift scripts/generate_icons.swift`)
- [ ] Pricing: set before submission in App Store Connect
- [ ] Copyright: © 2026 [Your Name / Company]
