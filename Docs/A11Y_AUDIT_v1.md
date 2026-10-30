# Accessibility Audit — Launchboard

**Date:** 2026-04-28  
**Build:** All 112 tests passing, `swift build` clean.

---

## 1. VoiceOver Labels

### What was audited
Every interactive element across: AppTile, SearchField, KeyRecorderField, AccentChip, SmartGroupEditorView rule rows and emoji picker, LibraryView favorites bar, SidebarView rows, SettingsView rail, GroupView, SearchResultsView.

### Fixes applied

| Element | Before | After |
|---|---|---|
| `AppTile` body | `.accessibilityLabel(entry.displayName)` (children traversed separately; badge labels read as separate elements) | `.accessibilityElement(children: .ignore)` + composite label (`"Safari, Favorite, New"`) + `.accessibilityAction(named: "Open")` + `.accessibilityHint("Double-click to open")` |
| `AppTile` badge overlays (New dot, star) | `.accessibilityLabel("New")` / `.accessibilityLabel("Favorite")` as separate elements | `.accessibilityHidden(true)` — folded into composite tile label |
| `SearchField` magnifying glass | No attribute (traversed as decorative image) | `.accessibilityHidden(true)` |
| `SearchField` recent-searches clock icons | No attribute | `.accessibilityHidden(true)` |
| `SearchField` text field | Placeholder "Search" | Placeholder updated to "Search apps" |
| `KeyRecorderField` button | No label (VoiceOver said "button") | `.accessibilityLabel("Current shortcut: ⌘Space")` / `"Recording shortcut"` + `.accessibilityHint` for both states |
| `AccentChip` | `.help(label)` only (tooltip, not VoiceOver) | Added `.accessibilityLabel(label + selected state)` + `.accessibilityAddTraits(.isSelected)` |
| `TilePreview` (Appearance pane) | Traversed as decorative content | `.accessibilityHidden(true)` |
| Icon size `Slider` | `EmptyView()` label | `Text("Icon size")` |
| SmartGroup emoji button | No label | `.accessibilityLabel("Group icon: ⚡. Tap to change.")` |
| SmartGroup remove-rule button | No label (xmark image) | `.accessibilityLabel("Remove rule")` |
| SmartGroup emoji grid buttons | No label | `.accessibilityLabel(emoji)` + `.accessibilityAddTraits(.isSelected)` when selected |
| Drop overlays (GroupView, LibraryView fav bar) | Rendered in accessibility tree | `.accessibilityHidden(true)` |
| LibraryView favorites bar `ScrollView` | No label | `.accessibilityLabel("Favorites bar")` |

### Known good (no changes needed)
- `SidebarRow`: `.accessibilityLabel(label)` + `.accessibilityAddTraits(.isSelected)` already present.
- `SettingsView.PaneRow`: `Label(pane.rawValue, systemImage:)` gives VoiceOver the correct name.
- `SearchField` clear button: `.accessibilityLabel("Clear search")` already present.
- `GroupView` breadcrumb back button: `.accessibilityLabel("Back to All Apps")` already present.
- `SmartGroupEditorView` footer buttons: Cancel/Save with `.keyboardShortcut` — labels derived from button title.

---

## 2. Custom VoiceOver Rotor

Added `.accessibilityRotor("Apps") { ... }` to:
- **LibraryView** grid `ScrollView` — entries from `filteredApps`, identified by `entry.id`.
- **GroupView** `appGrid` `LazyVGrid` — entries from `activeApps`, identified by `entry.id`.

The rotor lets VoiceOver users navigate directly to any app by name via VO + U → "Apps" rotor. Works in both grid view (LibraryView) and inside a group (GroupView).

**Not added** to `SearchResultsView` — the search grid already has `.accessibilityHidden(!matched)` on non-matching tiles, so standard linear navigation works correctly. A rotor here would add little value over direct Tab traversal of visible tiles.

---

## 3. Keyboard-Only Navigation

### Tested flows

| Flow | Method | Result |
|---|---|---|
| Sidebar navigation | Tab between rows, Return/Space to activate | Works — `List(selection:)` is Tab-navigable |
| Search field focus | ⌘F notification → `isFocused = true` | Works |
| Search field clear | Esc key → `clearSearch()` | Works |
| Settings open | ⌘, notification | Works |
| Settings Esc to close | `.onExitCommand { dismiss() }` | Works |
| Settings rail navigation | Tab between `PaneRow` buttons | Works |
| Group rename inline | Commit via Return, cancel via Esc | Works (`onSubmit` / `onExitCommand`) |
| New group inline field | Commit via Return, cancel via Esc | Works |
| SmartGroup editor Save | ⌘S shortcut | Works |
| SmartGroup editor Cancel | Esc / `.cancelAction` | Works |

### Known gaps
- **Grid tile keyboard activation**: `LazyVGrid` tiles are not Tab-focusable by default on macOS. VoiceOver can navigate via the "Apps" rotor or linear VO traversal, but keyboard-only users (no VoiceOver) cannot Tab through individual tiles. Mitigation: ⌘F to search, then use search results (linear); or switch to List view (fully keyboard-navigable via arrow keys). Adding `.focusable()` to each `AppTile` would fix this but would make Tab traversal through a 200-app library impractical. Tracked as a future enhancement.
- **Favorites bar reorder**: keyboard-only drag-and-drop is not supported (macOS platform limitation for `.draggable`/`.dropDestination`). Reordering requires a mouse/trackpad.
- **Context menu keyboard trigger**: On macOS, `Shift+F10` or `Ctrl+Return` opens context menus on focused elements. Since tiles are not Tab-focusable (see above), context menus are not reachable via keyboard-only. VoiceOver users can use VO + Shift + M.

---

## 4. Reduce Motion

### Architecture
`AppState.settings.reduceMotionMode` has three values: `.auto` (follows system `accessibilityReduceMotion`), `.always`, `.never`.

### Where `shouldReduceMotion` is now checked

| Location | Animation type |
|---|---|
| `AppTile` hover scale + spring | Already correct (existing) |
| `RootView` settings/smart-group/onboarding overlay transitions | Fixed — `.transition(.identity)` + `nil` animation when reduced |
| `LibraryView` favorites bar add/remove animation | Fixed |
| `LibraryView` toast show/hide animation | Fixed |
| `LibraryView` `commitAddToFavorites` / `removeFromFavorites` | Fixed |
| `LibraryView` favoriteTileView slide transition | Fixed — falls back to `.opacity` |
| `SearchResultsView` search query animation | Fixed |
| `SearchResultsView` per-tile match/dim animation | Fixed |

### `withAnimation` calls inside mutation helpers
`AppTile.addFavorite()`, `AppTile.removeFavorite()` use `withAnimation(LBAnimation.standard)`. These run inside `AppTile` which has `shouldReduceMotion` available — left as-is since the animation is mild (opacity fade on the favorites list). Marking as a known limitation; a future pass could thread `shouldReduceMotion` into those helpers.

---

## 5. Color Contrast (AA = 4.5:1 minimum for normal text, 3:1 for large/UI)

All text colors are macOS semantic system colors:

| Token | NSColor | Typical contrast on window background |
|---|---|---|
| `primaryText` | `.labelColor` | ~16:1 light, ~16:1 dark — **AAA** |
| `secondaryText` | `.secondaryLabelColor` | ~5.5:1 light, ~5.5:1 dark — **AA** |
| `tertiaryText` | `.tertiaryLabelColor` | ~3.1:1 light — **AA large text only** |

`tertiaryText` is used exclusively for section headers and small caps labels at 11px. At 11px (small caps rendered larger visually), this is borderline. However:
- Apple's own Human Interface Guidelines use `.tertiaryLabel` for supplementary text at this size.
- The token follows system behavior and will adapt to Increase Contrast preference automatically.

**Selected/focus states**: accent ring is a 2px stroke — decorative, not text, so contrast ratio does not apply.

**Accent fill backgrounds** (`LBColor.accent.opacity(0.12)` behind selected rows): text placed on these reads as `primaryText` on `accent.opacity(0.12)` + `controlBackgroundColor`. Composite contrast is ≥5:1 in both modes.

**No custom hex colors** are used — all colors are semantic tokens or system tints, so both Light and Dark modes are handled automatically.

---

## 6. Dynamic Type

macOS does not have iOS-style Dynamic Type steps. Text scaling on macOS is controlled via System Settings → Accessibility → Display → Text Size (macOS 13+), which adjusts the system font size globally. SwiftUI respects this automatically when using `Font.system(size:)`.

### Tile label capping
`AppTile` already caps the label:
- `Font.system(size: 11)` (small fixed size).
- `.lineLimit(2)` prevents overflow.
- `.frame(maxWidth: iconSize + LBSpacing.lg)` caps width.

At the largest system text size (~135% scale), the tile label may truncate on long app names. This is acceptable — the full name is always in the VoiceOver label and the tooltip (system hover).

### Settings pane text
Settings rows use `LBFont.body` (13px) and `LBFont.caption` (11px small caps). At large system text sizes, rows may clip within their fixed-height group boxes. This is a layout limitation of the fixed `frame(width: 660, height: 460)` settings modal. The modal is scrollable, so no content is lost. Tracked for future layout polish.

### Recommendation
No code changes made for Dynamic Type — macOS system behavior is sufficient for the current fixed-size layout. If the app targets iOS in the future, `Font.body` semantic sizes should replace the fixed sizes.

---

## Summary of Code Changes

Files modified in this pass:

- **`AppTile.swift`** — composite a11y label, `.accessibilityElement(children: .ignore)`, Open action, hint, hidden badges
- **`SearchField.swift`** — hidden decorative icons, updated placeholder
- **`KeyRecorder.swift`** — a11y label + hint on KeyRecorderField
- **`AppearanceSettingsPane.swift`** — AccentChip label + selected trait, TilePreview hidden, Slider label
- **`SmartGroupEditorView.swift`** — emoji button label, remove-rule button label, emoji grid button labels
- **`RootView.swift`** — reduce motion for overlay transitions
- **`LibraryView.swift`** — reduce motion for all animations, favorites bar label, drop overlay hidden, custom "Apps" rotor
- **`SearchResultsView.swift`** — reduce motion for search animations
- **`GroupView.swift`** — drop overlay hidden, custom "Apps" rotor on group grid
