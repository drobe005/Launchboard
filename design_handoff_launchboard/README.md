# Handoff: Launchboard — macOS App Launcher

## Overview
Launchboard is a macOS menu-bar app launcher that lets users organize, search, and launch installed applications from a single glassmorphism-styled window. This handoff covers the complete hi-fi prototype including all screens, components, interactions, and data models needed to implement the app natively.

---

## About the Design Files
The files in this bundle are **high-fidelity design references built in HTML/React** — interactive prototypes showing the intended look, layout, and behavior. They are NOT production code to be shipped as-is.

Your task is to **recreate these designs natively in Swift + SwiftUI** (recommended — see Stack Recommendation below), using SwiftUI's established patterns and Apple's APIs. The HTML prototype serves as the visual and behavioral specification.

---

## Stack Recommendation

### ✅ Recommended: Swift + SwiftUI
**Reasons:**
- Native glassmorphism via `.ultraThinMaterial` / `.regularMaterial` (NSVisualEffectView under the hood)
- `NSWorkspace.shared.open(_:)` for launching apps — no sandbox workarounds needed
- `NSRunningApplication`, `FileManager`, and `Spotlight` (MDQuery) for app discovery
- Global keyboard shortcuts via `NSEvent.addGlobalMonitorForEvents`
- SwiftUI animations match the spring/bounce feel in the prototype
- Ships as a real `.app` bundle — proper menu bar integration, Dock hiding, etc.

**Tradeoffs vs. alternatives:**
| Stack | Native feel | Dev speed | macOS APIs | Verdict |
|---|---|---|---|---|
| Swift + SwiftUI | ★★★★★ | ★★★★ | Full access | ✅ Use this |
| Swift + AppKit | ★★★★★ | ★★★ | Full access | Fallback if SwiftUI hits limits |
| Tauri + React | ★★★ | ★★★★ | Partial (IPC) | Only if team is JS-only |
| Electron | ★★ | ★★★★ | Partial | Heavy, avoid |

**Architecture:** MVVM
- `Models` — plain structs: `AppItem`, `AppGroup`, `FavoritesStore`, `SettingsStore`
- `ViewModels` — `@Observable` classes: `LibraryViewModel`, `GroupViewModel`, `SearchViewModel`
- `Services` — `AppDiscoveryService`, `PersistenceService`
- `Views` — SwiftUI views organized by screen

**Minimum deployment target:** macOS 14.0 (Sonoma) — required for `@Observable`, `.containerRelativeFrame`, and best material support.

**Bundle ID:** `com.yourname.launchboard`

**Entitlements needed:**
```xml
<key>com.apple.security.automation.apple-events</key>
<true/>
```
For global shortcut (Option+Space): use `CGEventTap` or the `KeyboardShortcuts` SPM package.

---

## Fidelity
**High-fidelity.** The prototype is pixel-precise with final colors, typography, spacing, blur radii, gradient directions, shadow values, and interactions. Recreate the UI as close as possible to the reference, applying SwiftUI/AppKit equivalents for all visual properties.

---

## Design Tokens

### Colors
```swift
// Background
let bgBase        = Color(hex: "#0d0d14")       // Deep dark navy
let windowFill    = Color.white.opacity(0.04)   // Glass panel fill
let sidebarFill   = Color.white.opacity(0.03)

// Accent (default blue — user-configurable)
let accent        = Color(red: 0.353, green: 0.510, blue: 1.0)   // #5a82ff
let accentDim     = accent.opacity(0.22)
let accentGlow    = accent.opacity(0.35)

// Text hierarchy
let textPrimary   = Color.white.opacity(0.85)
let textSecondary = Color.white.opacity(0.55)
let textTertiary  = Color.white.opacity(0.28)
let textDisabled  = Color.white.opacity(0.18)

// Borders / dividers
let borderSubtle  = Color.white.opacity(0.06)
let borderMid     = Color.white.opacity(0.10)
let borderActive  = Color(hex: "#5a82ff").opacity(0.50)

// Semantic
let danger        = Color(hex: "#ff6b6b")
let success       = Color(hex: "#34d399")
let warning       = Color(hex: "#fbbf24")
```

### Background Orbs (decorative, animated)
Three blurred ellipses layered behind the window:
```swift
// Orb 1 — top-left
Color(oklch: 0.55, 0.18, hue: 260).opacity(0.35)
// frame: 500×500pt, offset x: -80, y: -100
// Orb 2 — bottom-right  
Color(oklch: 0.50, 0.15, hue: 300).opacity(0.35)
// frame: 400×400pt, offset x: +60, y: +80 from bottom-right
// Orb 3 — center
Color(oklch: 0.52, 0.14, hue: 220).opacity(0.35)
// frame: 300×300pt, centered ~30% from left, 20% from bottom
// All orbs: blur radius 80pt, gentle float animation (translateY ±30pt, 12s infinite)
```

### Typography
```swift
// All Inter or SF Pro (SF Pro preferred for native macOS feel)
let fontTitle     = Font.system(size: 19, weight: .semibold, design: .default)
let fontBody      = Font.system(size: 13, weight: .regular)
let fontBodyMed   = Font.system(size: 13, weight: .medium)
let fontCaption   = Font.system(size: 11, weight: .regular)
let fontLabel     = Font.system(size: 10, weight: .semibold)  // uppercase section labels
let fontAppName   = Font.system(size: 11, weight: .medium)
let fontMono      = Font.system(size: 12, weight: .regular, design: .monospaced)
```

### Spacing
```swift
let spaceXS  =  4.0
let spaceSM  =  8.0
let spaceMD  = 12.0
let spaceLG  = 16.0
let spaceXL  = 24.0
let space2XL = 32.0
```

### Border Radius
```swift
let radiusXS  =  5.0   // kbd chips, small tags
let radiusSM  =  7.0   // buttons, inputs
let radiusMD  =  8.0   // sidebar items, menu items
let radiusLG  = 10.0   // modals, cards
let radiusXL  = 12.0   // app tiles, fav icons
let radius2XL = 16.0   // main window
let radiusIcon = 13.0  // app grid icons (56pt)
```

### Shadows
```swift
// App icon shadow
Shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 6)
// Window outer shadow
Shadow(color: .black.opacity(0.60), radius: 80, x: 0, y: 40)
// Accent glow (modal, buttons)
Shadow(color: accent.opacity(0.35), radius: 12, x: 0, y: 2)
```

### App Icon Gradients (by category)
```swift
let gradients: [String: [Color]] = [
    "c0":  [Color(hex:"#5a82ff"), Color(hex:"#8b5cf6")],  // blue→purple (Figma)
    "c1":  [Color(hex:"#f59e0b"), Color(hex:"#ef4444")],  // amber→red (Photoshop)
    "c2":  [Color(hex:"#10b981"), Color(hex:"#059669")],  // green (Spotify)
    "c3":  [Color(hex:"#06b6d4"), Color(hex:"#3b82f6")],  // cyan→blue (Safari)
    "c4":  [Color(hex:"#ec4899"), Color(hex:"#a855f7")],  // pink→purple (Obsidian)
    "c5":  [Color(hex:"#f97316"), Color(hex:"#eab308")],  // orange→yellow (Illustrator)
    "c6":  [Color(hex:"#14b8a6"), Color(hex:"#0ea5e9")],  // teal→sky (Webflow)
    "c7":  [Color(hex:"#8b5cf6"), Color(hex:"#ec4899")],  // purple→pink (Notion)
    "c8":  [Color(hex:"#22d3ee"), Color(hex:"#4ade80")],  // cyan→green (Tableau)
    "c9":  [Color(hex:"#fb7185"), Color(hex:"#f43f5e")],  // rose→red (Slack)
    "c10": [Color(hex:"#a78bfa"), Color(hex:"#818cf8")],  // violet (Affinity)
    "c11": [Color(hex:"#34d399"), Color(hex:"#059669")],  // emerald (Terminal)
    "c12": [Color(hex:"#fbbf24"), Color(hex:"#f59e0b")],  // gold (Sketch)
    "c13": [Color(hex:"#60a5fa"), Color(hex:"#2563eb")],  // blue (Xcode)
    "c14": [Color(hex:"#e879f9"), Color(hex:"#a21caf")],  // fuchsia (Linear)
]
```

---

## Data Models

```swift
// AppItem.swift
struct AppItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var bundleID: String          // e.g. "com.figma.Desktop"
    var iconData: Data?           // cached NSImage PNG
    var category: AppCategory
    var isFavorite: Bool
    var hasBadge: Bool            // "recently added" indicator
    var gradientKey: String       // "c0"…"c14" — maps to gradient palette
    var dateAdded: Date
    var lastUsed: Date?
}

enum AppCategory: String, CaseIterable, Codable {
    case all = "All"
    case design = "Design"
    case development = "Development"
    case communication = "Communication"
    case media = "Media"
    case productivity = "Productivity"
    case utilities = "Utilities"
}

// AppGroup.swift
struct AppGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String              // SF Symbol name or emoji
    var colorHex: String          // e.g. "#a78bfa"
    var appIDs: [UUID]
    var isSmartGroup: Bool = false
    var smartRules: [SmartRule]?
}

struct SmartRule: Codable {
    var condition: String         // "Category", "Last used", "File size", "Name"
    var op: String                // "is", "is more than", etc.
    var value: String
}

// Settings.swift
struct AppSettings: Codable {
    var theme: AppTheme = .dark
    var accentColorHex: String = "#5a82ff"
    var iconSize: Double = 56
    var showAppNames: Bool = true
    var reduceMotion: Bool = false
    var launchAtLogin: Bool = false
    var showMenuBarIcon: Bool = true
    var recentlyAddedDays: Int = 14
    var defaultView: ViewMode = .grid
    var defaultSort: SortMode = .alphabetical
    var globalShortcut: String = "⌥Space"
}

enum AppTheme: String, Codable { case light, dark, auto }
enum ViewMode: String, Codable { case grid, list }
enum SortMode: String, Codable {
    case alphabetical, recentlyUsed, mostUsed, dateAdded
}
```

### Seed Dataset (mirrors the hi-fi prototype)
```swift
let seedApps: [AppItem] = [
    AppItem(id: UUID(), name: "Figma",       bundleID: "com.figma.Desktop",          category: .design,        isFavorite: true,  hasBadge: false, gradientKey: "c0",  dateAdded: .now),
    AppItem(id: UUID(), name: "Sketch",      bundleID: "com.bohemiancoding.sketch3",  category: .design,        isFavorite: true,  hasBadge: false, gradientKey: "c12", dateAdded: .now),
    AppItem(id: UUID(), name: "Xcode",       bundleID: "com.apple.dt.Xcode",          category: .development,   isFavorite: false, hasBadge: true,  gradientKey: "c13", dateAdded: .now),
    AppItem(id: UUID(), name: "VS Code",     bundleID: "com.microsoft.VSCode",        category: .development,   isFavorite: true,  hasBadge: true,  gradientKey: "c3",  dateAdded: .now),
    AppItem(id: UUID(), name: "Safari",      bundleID: "com.apple.Safari",            category: .utilities,     isFavorite: true,  hasBadge: false, gradientKey: "c6",  dateAdded: .now),
    AppItem(id: UUID(), name: "Spotify",     bundleID: "com.spotify.client",          category: .media,         isFavorite: false, hasBadge: false, gradientKey: "c2",  dateAdded: .now),
    AppItem(id: UUID(), name: "Slack",       bundleID: "com.tinyspeck.slackmacgap",   category: .communication, isFavorite: false, hasBadge: false, gradientKey: "c9",  dateAdded: .now),
    AppItem(id: UUID(), name: "Notion",      bundleID: "notion.id",                   category: .productivity,  isFavorite: true,  hasBadge: false, gradientKey: "c7",  dateAdded: .now),
    AppItem(id: UUID(), name: "Photoshop",   bundleID: "com.adobe.Photoshop",         category: .design,        isFavorite: false, hasBadge: false, gradientKey: "c1",  dateAdded: .now),
    AppItem(id: UUID(), name: "Terminal",    bundleID: "com.apple.Terminal",           category: .development,   isFavorite: false, hasBadge: false, gradientKey: "c11", dateAdded: .now),
    AppItem(id: UUID(), name: "Zoom",        bundleID: "us.zoom.xos",                 category: .communication, isFavorite: true,  hasBadge: false, gradientKey: "c3",  dateAdded: .now),
    AppItem(id: UUID(), name: "Chrome",      bundleID: "com.google.Chrome",           category: .utilities,     isFavorite: true,  hasBadge: false, gradientKey: "c1",  dateAdded: .now),
    AppItem(id: UUID(), name: "Obsidian",    bundleID: "md.obsidian",                 category: .productivity,  isFavorite: false, hasBadge: false, gradientKey: "c4",  dateAdded: .now),
    AppItem(id: UUID(), name: "Linear",      bundleID: "com.linear",                  category: .productivity,  isFavorite: false, hasBadge: false, gradientKey: "c14", dateAdded: .now),
    AppItem(id: UUID(), name: "Affinity",    bundleID: "com.seriflabs.affinitydesigner",category: .design,      isFavorite: false, hasBadge: false, gradientKey: "c10", dateAdded: .now),
]

let seedGroups: [AppGroup] = [
    AppGroup(id: UUID(), name: "Design",        icon: "✦", colorHex: "#a78bfa", appIDs: [/* Figma, Sketch, Photoshop, Affinity IDs */]),
    AppGroup(id: UUID(), name: "Development",   icon: "⌥", colorHex: "#38bdf8", appIDs: [/* Xcode, VS Code, Terminal IDs */]),
    AppGroup(id: UUID(), name: "Communication", icon: "✉", colorHex: "#fb923c", appIDs: [/* Slack, Zoom IDs */]),
    AppGroup(id: UUID(), name: "Media",         icon: "▶", colorHex: "#f43f5e", appIDs: [/* Spotify IDs */]),
    AppGroup(id: UUID(), name: "Utilities",     icon: "⚙", colorHex: "#94a3b8", appIDs: [/* Safari, Chrome IDs */]),
]
```

---

## Screens & Views

### 1. Main Window
- **Size:** 960 × 620 pt, resizable (min 800×500)
- **Window style:** `NSWindow` with `.titled`, `.fullSizeContentView`, `titlebarAppearsTransparent: true`, `titleVisibility: .hidden`
- **Background:** `NSVisualEffectView` with `.sidebar` or `.hudWindow` material + dark appearance override; additionally layer the bg orbs as `Canvas` or `ZStack` behind the blurred glass
- **Border:** 1pt stroke, `Color.white.opacity(0.10)`, `cornerRadius: 16`
- **Outer shadow:** black 60% opacity, radius 80, y+40

#### Title Bar (40pt tall)
- Traffic light dots: left-aligned at x=16, centered vertically
- Title text: `"Launchboard"` centered, `textSecondary`, 13pt medium
- Right side: keyboard shortcut chips `⌥` `Space` in `lb-kbd` style (rounded rect, 22pt tall, `textTertiary`)

#### Sidebar (210pt wide)
- Background: `windowFill` (white 3%)
- Right border: `borderSubtle` (white 6%), 1pt
- **Section labels:** 10pt, semibold, uppercase, 0.08em tracking, `textTertiary`; padding 10pt top, 4pt bottom, 16pt left
- **Sidebar items:** 13pt medium, 6pt vertical padding, 12pt horizontal, 8pt horizontal margin, `radiusMD` corner
  - Default: `textSecondary`
  - Hover: `windowFill` + white 7% bg, `textPrimary`
  - Active: `accentDim` bg, white border `accentDim×1.4`, `textPrimary`
  - Icon: 20×20pt, 5pt corner, colored background at 13% opacity
- **Divider:** 1pt, `borderSubtle`, 8pt vertical margins, 12pt horizontal
- **"Add Group…":** accent-colored text, accent icon
- **Settings** pinned to bottom above safe area

#### Favorites Bar (84pt tall)
- Background: white 1.5%
- Bottom border: `borderSubtle`
- Vertical label "FAVORITES": 9pt, semibold, uppercase, 0.1em tracking, `textTertiary`, rotated 90°
- Fav tiles: 44×44pt icon, 11pt corner, gradient bg, 5pt gap to 9pt name label
  - Hover: white 8% bg, translateY(-2pt)
  - Max 12 tiles

#### App Grid
- Padding: 14pt top/bottom, 16pt horizontal
- Section label: `fontLabel` size 10pt
- Grid: `LazyVGrid` with `adaptive(minimum: 86)`, 6pt gap
- **App Tile:** 56×56pt icon, 13pt corner, gradient bg, 6pt gap to name
  - Hover: white 8% bg, `scaleEffect(1.05)`, translateY(-1pt), spring animation
  - Selected: `accentDim` bg, accent border 1pt
  - Faded (search non-match): opacity 0.2
  - Badge: 11×11pt circle, accent color, 2pt white border ring, top-right of icon, subtle glow shadow
  - Right-click context menu: "Add to Favorites", "Add to Group…", separator, "Hide from Library" (danger/red)
- **App name:** 11pt medium, `textSecondary`; hover → `textPrimary`

#### App Grid — List View
- Rows: 36pt icon (9pt corner), 13pt name + 11pt category, star for favorites
- Row hover: white 6% bg, 8pt corner, 7pt vertical padding, 12pt horizontal

#### Top Bar (52pt tall)
- Background: white 2%, bottom border `borderSubtle`
- **Search field:** flex-1, 32pt tall, 8pt corner, white 7% bg, white 10% border
  - Focus: white 10% bg, accent 50% border, 3pt glow shadow
  - Placeholder: `textTertiary`
  - Clear button (✕) visible when query non-empty
- **View toggle group:** 32×32pt buttons each, grouped in rounded rect, grid icon (⊞) / list icon (≡)
  - Active: `accentDim` + `accentGlow` 30% bg
- **Sort dropdown:** 32pt tall, 12pt font, white 6% bg, white 8% border; dropdown arrow

#### Breadcrumb (shown in Group view)
- 12pt text, 8pt top padding, 16pt horizontal
- Parent link: accent color, clickable
- Separator: `textTertiary`
- Current: `textPrimary`, medium weight
- App count: right-aligned, 11pt, `textTertiary`
- "+ Add Apps" button: small secondary button, opens App Select Modal

#### Keyboard Hint (bottom-right of grid area)
- Fixed position inside the main content area
- `⌘F search · ↵ launch` in `lb-kbd` chips + `textTertiary` label text, 11pt

---

### 2. App Selection Modal
**Trigger:** "Add Group…" in sidebar, "+ Add Apps" in group breadcrumb
- **Size:** 560 × ~580pt
- **Background:** glass modal (see Glass Modal style below)
- **Animation:** scale 0.95→1.0, opacity 0→1, spring easing, 0.25s

#### Header
- Title: 18pt semibold, white; subtitle "N selected" in 12pt `textTertiary`
- Subheading label: 11pt, uppercase, 0.08em tracking, `textTertiary`
- Close button (✕): 28×28pt circle, white 8% bg, white 8% border

#### Search (36pt tall)
- Same style as main search bar; auto-focused on open

#### Category Filter Tabs
- Horizontal scrollable row, 4pt gap
- Tab: 11pt, 500 weight, `whitespace: nowrap`, 4pt vertical / 12pt horizontal padding, 20pt corner
- Default: white 4% bg, white 8% border, `textTertiary`
- Active: accent 25% bg, accent 35% border, white text
- Categories: All · Design · Development · Communication · Media · Productivity · Utilities

#### App Grid
- `LazyVGrid`, `adaptive(minimum: 72)`, 4pt gap, max-height 280pt, scrollable
- App tile: 48×48pt icon (12pt corner), 10pt name below, 8pt corner tile
- Selected state: accent 18% tile bg; checkmark badge (16×16pt circle, accent bg, "✓" white 9pt)
- Hover: white 8% tile bg
- Empty state: centered "No apps match your search" in `textTertiary`

#### Footer
- Top border: `borderSubtle`
- Left: helper text with Esc chip
- Right: Cancel + "Add N App(s)" primary button
- Primary button disabled when 0 selected (or show "Add Apps" in disabled state)

#### Glass Modal Style
```swift
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        .overlay(Color(hex: "#16162a").opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
)
.shadow(color: .black.opacity(0.70), radius: 80, x: 0, y: 40)
.shadow(color: Color(hex: "#5a82ff").opacity(0.08), radius: 120, x: 0, y: 0)
```

---

### 3. Setup / Onboarding Flow (3-Step Modal)
**Trigger:** First launch, or "Setup" nav item
- Same glass modal style, width 560pt
- Step indicator: 3 dots top-right; active dot = 20pt wide, inactive = 6pt, both 6pt tall, 3pt corner

#### Step 1 — Suggested Groups
- Icon: blue ⊞ in colored rounded square
- Body: 13pt `textSecondary` description, 1.6 line-height
- Groups grid: 3 columns, 10pt gap
  - Each card: white 4% bg, white 8% border, 10pt corner, 12pt/14pt padding
  - Group icon + name + app name list in `textTertiary`, 1.7 line-height

#### Step 2 — Pin Favorites
- Icon: gold ★
- App tiles: inline tap-to-toggle; selected = full opacity + checkmark badge; deselected = 35% opacity
- Selected count + max-12 hint

#### Step 3 — Global Shortcut
- Icon: green ⌘
- Shortcut display: `⌥` + `Space` kbd chips, 16pt, 8px/16px padding, centered in accent-bordered container
- "Recording… press your combo now" hint text

#### Footer
- Back / Skip (secondary) · Continue → / Done → (primary)
- Step counter in subtitle "Step N of 3"

---

### 4. Settings
**Access:** Sidebar "Settings" item → replaces main content area (or opens as a sheet)

#### Settings Layout
- Inner sidebar: 160pt, same glass style; tabs: General · Appearance · Library · Shortcuts · About
- Content area: 24pt padding, scrollable

#### General Tab
- Section headers: 10pt uppercase `textTertiary`
- Setting rows: label + optional caption (11pt `textTertiary`) + control, 12pt vertical padding, `borderSubtle` bottom border
- Controls: `lb-toggle` (38×22pt pill), `lb-seg` segmented control, `lb-select` dropdown

#### Appearance Tab
- Theme: Auto / Light / Dark segmented control
- Accent color: 6 color swatches (20×20pt circles); selected = white 2pt ring + 2pt black gap
- Icon size: range slider 40–80pt, thumb = accent colored circle 14pt
- Show app names: toggle
- Reduce motion: toggle

#### Library Tab
- Scan locations list with "Remove" danger buttons
- "+ Add Location…" secondary button
- Callout card: accent-tinted with 💡 hint
- Hidden apps list with "Restore" buttons
- "↻ Rescan Now" primary button + last-scan timestamp

#### Shortcuts Tab
- Global shortcut row with "Record" button and live keybind display
- Conflict banner: danger-tinted card, 12pt text
- In-app shortcuts list (non-editable reference rows)

#### About Tab
- Centered: 72×72pt gradient app icon, app name 20pt bold, version 13pt `textTertiary`
- Description paragraph
- "Check for Updates" button

---

## Interactions & Behavior

### Global
- **⌥ Space** (global hotkey): toggle Launchboard window show/hide; use `CGEventTap` or `KeyboardShortcuts` SPM package
- **Esc**: clear search if active → else close/hide window
- **⌘F**: focus search field
- **↑↓←→**: navigate app grid
- **↵**: launch focused/selected app via `NSWorkspace.shared.open(URL(fileURLWithPath: appPath))`
- **⌘N**: new group
- **⌘D**: add to favorites

### Search
- Live filtering: case-insensitive substring match on app name
- Non-matches: fade to 20% opacity (grid view); hidden (list view)
- Favorites section surfaced first when in "All Apps" view
- Clear button visible when query non-empty; Esc also clears

### App Launching
```swift
// Preferred — uses bundle ID for reliability
NSWorkspace.shared.openApplication(
    at: appURL,
    configuration: NSWorkspace.OpenConfiguration()
)
// Fallback
NSWorkspace.shared.open(appURL)
```
- Show error alert if app no longer found at path
- Optionally hide Launchboard window after launch (user preference)

### Drag & Drop
- Drag app tiles into group in sidebar → add to group
- Drag app tiles between groups → move
- Drag within favorites bar → reorder
- Ghost icon (55% opacity, slight rotation) follows cursor during drag

### App Discovery (AppDiscoveryService)
```swift
// Scan /Applications and ~/Applications using FileManager
// Optionally query Spotlight: MDQueryCreate with kMDItemContentType == "com.apple.application-bundle"
// Extract: display name, bundle ID, icon (NSWorkspace.shared.icon(forFile:))
// Cache results in UserDefaults or a local JSON file
```

### Persistence (PersistenceService)
```swift
// UserDefaults for simple preferences (AppSettings)
// JSON files in Application Support for AppItems, AppGroups, Favorites
// File path: ~/Library/Application Support/Launchboard/
```

---

## Animations

| Element | Property | Value |
|---|---|---|
| App tile hover | scale | 1.0 → 1.05, spring(response: 0.3, damping: 0.7) |
| App tile hover | translateY | 0 → -1pt |
| Fav tile hover | translateY | 0 → -2pt |
| Modal open | scale + opacity | 0.95,0 → 1.0,1.0, spring(response: 0.28, damping: 0.78) |
| Orb float | translateY | 0 → -30pt → 0, easeInOut, 12s infinite |
| Sidebar active | background | cross-fade 0.15s |
| Search focus | border + shadow | 0.2s ease |
| Toggle switch | thumb position | spring(response: 0.25, damping: 0.8) |
| Step dots | width | 6pt → 20pt, spring 0.3s |
| Search fade | opacity | 1.0 → 0.2, 0.15s ease |

---

## Component Checklist
- [ ] `AppIconView` — gradient rect + icon text/image + badge dot
- [ ] `AppTileView` — tile wrapper with hover/selected state
- [ ] `AppListRowView` — list mode row
- [ ] `SidebarView` — full sidebar with sections
- [ ] `SidebarItemView` — individual sidebar row
- [ ] `FavoritesBarView` — horizontal scrollable fav strip
- [ ] `TopBarView` — search + view toggle + sort
- [ ] `AppGridView` — LazyVGrid of AppTileView
- [ ] `BreadcrumbView` — group navigation header
- [ ] `AppSelectModal` — full app selection sheet
- [ ] `SetupModal` — 3-step onboarding
- [ ] `SettingsView` — inner sidebar + tab content
- [ ] `GlassCard` — reusable glass background modifier
- [ ] `KbdChip` — keyboard shortcut badge
- [ ] `SegmentedControl` — custom styled seg control
- [ ] `GlassToggle` — pill toggle switch
- [ ] `AccentSlider` — custom slider with accent thumb
- [ ] `ContextMenuModifier` — right-click menu
- [ ] `BackgroundOrbsView` — animated orb layer

---

## Project Bootstrap Commands

```bash
# In Cursor terminal:
# 1. Create Xcode project
xcodegen generate   # if using XcodeGen
# OR open Xcode → File → New Project → macOS → App
# Name: Launchboard
# Bundle ID: com.yourname.launchboard
# Interface: SwiftUI
# Deployment Target: macOS 14.0

# 2. Add Swift Package dependencies
# In Xcode: File → Add Package Dependencies
# - https://github.com/sindresorhus/KeyboardShortcuts  (global hotkey)
# - https://github.com/sindresorhus/LaunchAtLogin-Modern (launch at login)

# 3. Folder structure
mkdir -p Launchboard/{Models,ViewModels,Views,Services,Utilities,Assets.xcassets}
```

### Recommended Folder Structure
```
Launchboard/
├── LaunchboardApp.swift          # @main, AppDelegate
├── Models/
│   ├── AppItem.swift
│   ├── AppGroup.swift
│   ├── AppSettings.swift
│   └── SeedData.swift
├── ViewModels/
│   ├── LibraryViewModel.swift
│   ├── SearchViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   ├── AppDiscoveryService.swift
│   ├── PersistenceService.swift
│   └── HotkeyService.swift
├── Views/
│   ├── MainWindowView.swift
│   ├── Sidebar/
│   │   ├── SidebarView.swift
│   │   └── SidebarItemView.swift
│   ├── Content/
│   │   ├── TopBarView.swift
│   │   ├── FavoritesBarView.swift
│   │   ├── AppGridView.swift
│   │   ├── AppTileView.swift
│   │   └── AppListRowView.swift
│   ├── Modals/
│   │   ├── AppSelectModal.swift
│   │   └── SetupModal.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       ├── GlassCard.swift
│       ├── KbdChip.swift
│       ├── GlassToggle.swift
│       ├── SegmentedControl.swift
│       └── BackgroundOrbsView.swift
├── Utilities/
│   └── Color+Hex.swift
└── Resources/
    └── Assets.xcassets/
```

---

## Suggested Build Order (Step-by-Step)

1. **Bootstrap** — project + packages + folder structure + `Color+Hex` utility
2. **Models + SeedData** — `AppItem`, `AppGroup`, `AppSettings`, seed arrays
3. **Services** — `PersistenceService` (UserDefaults + JSON), `AppDiscoveryService` (scan `/Applications`)
4. **Window chrome** — `MainWindowView` with titlebar, traffic lights, glass background + orbs
5. **Sidebar** — `SidebarView` with all items, active state, scrollable groups
6. **Top bar + search** — `TopBarView` with working search binding
7. **App grid** — `AppGridView` + `AppTileView` with hover, badge, context menu
8. **Favorites bar** — `FavoritesBarView`
9. **App Select Modal** — `AppSelectModal` with search, category tabs, multi-select
10. **Launch behavior** — `NSWorkspace` open + keyboard shortcuts
11. **Group view** — breadcrumb + filtered grid + drag-drop
12. **Settings** — all 5 tabs with working toggles/sliders/pickers
13. **Setup flow** — `SetupModal` 3-step onboarding
14. **Hotkey service** — global `⌥Space` via `KeyboardShortcuts`
15. **Polish** — animations, transitions, reduced-motion support
16. **Packaging** — app icon, Info.plist entitlements, code signing, `.dmg` via `create-dmg`

---

## Files in This Bundle
| File | Description |
|---|---|
| `Launchboard HiFi Standalone.html` | Full interactive hi-fi prototype — primary visual reference |
| `README.md` | This document — complete implementation spec |

---

## Notes for Claude Code in Cursor
- Always start each session by restating the step objective in 1–2 sentences
- Deliver complete, copy-pasteable code blocks — no partial snippets
- Keep each step small: the app should compile and show visible progress after each step
- When design is ambiguous, match the HTML prototype's visual aesthetic exactly
- Prefer `@Observable` (iOS 17+ / macOS 14+) over `ObservableObject` for ViewModels
- Use `withAnimation(.spring(response: 0.3, dampingFraction: 0.7))` for hover states
- Use `NSVisualEffectView` via `NSViewRepresentable` for true system blur — SwiftUI `.background(.ultraThinMaterial)` alone may not match the depth of the prototype
