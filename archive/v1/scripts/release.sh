#!/usr/bin/env bash
# release.sh — Build, sign, notarize, and package Launchboard for Developer ID distribution.
#
# ─── One-time setup (run once per machine, not part of every release) ──────────
#
#  1. Install your Developer ID Application certificate into the login keychain
#     (double-click the .cer from developer.apple.com, or let Xcode manage it).
#
#  2. Store notarytool credentials under a named profile.
#     Option A — Apple ID + app-specific password:
#       xcrun notarytool store-credentials "launchboard-notary" \
#           --apple-id "you@example.com" \
#           --team-id  "XXXXXXXXXX" \
#           --password "@keychain:AC_PASSWORD"
#
#     Option B — App Store Connect API key (preferred for CI):
#       xcrun notarytool store-credentials "launchboard-notary" \
#           --key      "/path/to/AuthKey_XXXXXXXX.p8" \
#           --key-id   "XXXXXXXX" \
#           --issuer   "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#
# ─── Usage ────────────────────────────────────────────────────────────────────
#
#   # Minimal — reads TEAM_ID + DEVELOPER_NAME from environment:
#   TEAM_ID="XXXXXXXXXX" DEVELOPER_NAME="Jane Smith" bash scripts/release.sh
#
#   # Override version / bundle ID:
#   VERSION=1.1 BUILD=2 BUNDLE_ID=com.example.launchboard \
#       TEAM_ID="XXXXXXXXXX" DEVELOPER_NAME="Jane Smith" bash scripts/release.sh
#
# ─── Required environment variables ──────────────────────────────────────────
#   TEAM_ID           10-character Apple team ID
#   DEVELOPER_NAME    Name on your Developer ID cert (as shown in Keychain)
#
# ─── Optional environment variables ──────────────────────────────────────────
#   VERSION           Marketing version, default 1.0
#   BUILD             Build number, default 1
#   BUNDLE_ID         Bundle identifier, default com.launchboard.app
#   NOTARYTOOL_PROFILE Keychain profile name, default launchboard-notary
#   COPYRIGHT         Copyright string, default "© $(year) $DEVELOPER_NAME"
#   SKIP_NOTARIZE     Set to 1 to skip notarization (for local testing)
#   SKIP_DMG          Set to 1 to skip DMG creation
#
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────

VERSION="${VERSION:-1.0}"
BUILD="${BUILD:-1}"
BUNDLE_ID="${BUNDLE_ID:-com.launchboard.app}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-launchboard-notary}"
SKIP_NOTARIZE="${SKIP_NOTARIZE:-0}"
SKIP_DMG="${SKIP_DMG:-0}"

TEAM_ID="${TEAM_ID:?'Set TEAM_ID (10-char Apple team ID, e.g. XXXXXXXXXX)'}"
DEVELOPER_NAME="${DEVELOPER_NAME:?'Set DEVELOPER_NAME (name on your Developer ID cert)'}"
COPYRIGHT="${COPYRIGHT:-© $(date +%Y) ${DEVELOPER_NAME}}"

SIGN_IDENTITY="Developer ID Application: ${DEVELOPER_NAME} (${TEAM_ID})"

APP_NAME="Launchboard"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RELEASE_DIR="$PROJECT_ROOT/release"
STAGING_DIR="$PROJECT_ROOT/.build/app-staging"
APP_BUNDLE="$STAGING_DIR/${APP_NAME}.app"
CONTENTS="$APP_BUNDLE/Contents"
ZIP_PATH="$RELEASE_DIR/${APP_NAME}-${VERSION}.zip"
DMG_PATH="$RELEASE_DIR/${APP_NAME}-${VERSION}.dmg"

ENTITLEMENTS="$PROJECT_ROOT/Sources/Launchboard/Launchboard.entitlements"
INFO_PLIST_TEMPLATE="$PROJECT_ROOT/Sources/Launchboard/Info.plist"
ASSETS_SOURCE="$PROJECT_ROOT/Sources/Launchboard/Assets.xcassets"

# ─── Helpers ──────────────────────────────────────────────────────────────────

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
step() { printf '\n\033[1;36m▸ %s\033[0m\n' "$*"; }
ok()   { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[33m  ⚠ %s\033[0m\n' "$*"; }
die()  { printf '\033[31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ─── Preflight checks ─────────────────────────────────────────────────────────

step "Preflight"

# Xcode CLI tools
if ! xcode-select -p &>/dev/null; then
    die "Xcode Command Line Tools not found. Run: xcode-select --install"
fi
ok "Xcode CLI tools present"

# Signing identity in keychain
if ! security find-identity -v -p codesigning | grep -qF "$SIGN_IDENTITY"; then
    die "Signing identity not found in keychain: \"$SIGN_IDENTITY\"
    Install your Developer ID Application certificate from developer.apple.com
    or via Xcode → Settings → Accounts → Manage Certificates."
fi
ok "Signing identity found: $SIGN_IDENTITY"

# notarytool profile (skip check if SKIP_NOTARIZE=1)
if [[ "$SKIP_NOTARIZE" != "1" ]]; then
    if ! xcrun notarytool history --keychain-profile "$NOTARYTOOL_PROFILE" \
            &>/dev/null 2>&1; then
        die "notarytool profile '${NOTARYTOOL_PROFILE}' not found.
    Run the one-time setup at the top of this script (see comments)."
    fi
    ok "notarytool profile found: $NOTARYTOOL_PROFILE"
fi

# entitlements file
[[ -f "$ENTITLEMENTS" ]] || die "Entitlements not found: $ENTITLEMENTS"
ok "Entitlements file present"

bold "\n  App:        ${APP_NAME} ${VERSION} (${BUILD})"
bold "  Bundle ID:  ${BUNDLE_ID}"
bold "  Identity:   ${SIGN_IDENTITY}"
[[ "$SKIP_NOTARIZE" == "1" ]] && warn "Notarization SKIPPED (SKIP_NOTARIZE=1)"

# ─── Build ────────────────────────────────────────────────────────────────────

step "swift build -c release"
cd "$PROJECT_ROOT"
swift build -c release 2>&1
ok "Build complete"

BUILT_BINARY="$PROJECT_ROOT/.build/release/${APP_NAME}"
[[ -f "$BUILT_BINARY" ]] || die "Expected binary not found: $BUILT_BINARY"
ok "Binary: $BUILT_BINARY ($(file "$BUILT_BINARY" | grep -o 'arm64\|x86_64' | tr '\n' '/' | sed 's|/$||'))"

# ─── Assemble .app bundle ─────────────────────────────────────────────────────

step "Assemble ${APP_NAME}.app"
rm -rf "$STAGING_DIR" && mkdir -p "$STAGING_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

# Executable
cp "$BUILT_BINARY" "$CONTENTS/MacOS/$APP_NAME"
ok "Copied executable"

# Compile asset catalog (app icon + Assets.car) with actool
# actool outputs AppIcon.icns and Assets.car into Contents/Resources/
if [[ -d "$ASSETS_SOURCE" ]]; then
    ACTOOL_LOG=$(mktemp)
    if xcrun actool \
        --compile "$CONTENTS/Resources" \
        --platform macosx \
        --minimum-deployment-target 14.0 \
        --app-icon AppIcon \
        --output-partial-info-plist /tmp/actool-partial.plist \
        "$ASSETS_SOURCE" > "$ACTOOL_LOG" 2>&1; then
        ok "Asset catalog compiled (AppIcon.icns + Assets.car)"
    else
        warn "actool exited non-zero — check $ACTOOL_LOG"
        warn "App will run but may show a generic icon"
    fi
    rm -f "$ACTOOL_LOG"
else
    warn "Assets.xcassets not found at $ASSETS_SOURCE — skipping actool"
fi

# Info.plist (substitute placeholders from template)
PLIST="$CONTENTS/Info.plist"
sed \
    -e "s|__BUNDLE_ID__|${BUNDLE_ID}|g" \
    -e "s|__VERSION__|${VERSION}|g" \
    -e "s|__BUILD__|${BUILD}|g" \
    -e "s|__COPYRIGHT__|${COPYRIGHT}|g" \
    "$INFO_PLIST_TEMPLATE" > "$PLIST"
# Merge actool-generated icon keys if present
if [[ -f /tmp/actool-partial.plist ]]; then
    /usr/libexec/PlistBuddy -x /tmp/actool-partial.plist \
        | grep -A1 'CFBundleIconFile\|CFBundleIconName' \
        | while IFS= read -r line; do
            key=$(echo "$line" | sed 's|.*<key>\(.*\)</key>.*|\1|')
            val=$(echo "$line" | sed 's|.*<string>\(.*\)</string>.*|\1|')
            [[ -n "$key" && -n "$val" ]] && \
                /usr/libexec/PlistBuddy -c "Set :${key} ${val}" "$PLIST" 2>/dev/null || true
        done
    rm -f /tmp/actool-partial.plist
fi
ok "Info.plist written"

# Validate bundle structure
plutil -lint "$PLIST" > /dev/null || die "Info.plist is malformed"
ok "Info.plist is valid XML"

printf '\n  Bundle structure:\n'
find "$APP_BUNDLE" -not -name '.DS_Store' | sort | sed "s|${STAGING_DIR}/||" | sed 's|^|    |'

# ─── Code signing ─────────────────────────────────────────────────────────────

step "Code signing (hardened runtime)"

# Sign the main executable explicitly first if there are no nested bundles;
# then sign the .app bundle which seals the whole tree.
# For apps with nested .framework or .dylib, sign each component before the app.

codesign \
    --sign "$SIGN_IDENTITY" \
    --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --timestamp \
    --force \
    --verbose \
    "$APP_BUNDLE" 2>&1 | grep -E 'replacing|adding|signed|error' || true

ok "Signed $APP_NAME.app"

# Verify
step "Verify signature"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" 2>&1
ok "Signature valid"

# Verify hardened runtime flag is present
HR_FLAGS=$(codesign -dv "$APP_BUNDLE" 2>&1 | grep 'flags=')
if echo "$HR_FLAGS" | grep -q 'runtime'; then
    ok "Hardened runtime confirmed (flags: $HR_FLAGS)"
else
    die "Hardened runtime flag not found in signature. Output: $HR_FLAGS"
fi

# Verify entitlements were embedded
codesign -d --entitlements - "$APP_BUNDLE" 2>/dev/null | grep -q 'app-sandbox' && \
    ok "App Sandbox entitlement embedded" || \
    warn "app-sandbox entitlement not found in embedded entitlements"

# ─── Notarization ─────────────────────────────────────────────────────────────

mkdir -p "$RELEASE_DIR"

if [[ "$SKIP_NOTARIZE" == "1" ]]; then
    warn "Skipping notarization (SKIP_NOTARIZE=1)"
    # Copy the unstapled app to release dir for inspection
    cp -R "$APP_BUNDLE" "$RELEASE_DIR/"
    ok "App (unsigned ticket) copied to $RELEASE_DIR/${APP_NAME}.app"
else
    step "Create ZIP for notarization"
    rm -f "$ZIP_PATH"
    ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
    ok "ZIP: $ZIP_PATH ($(du -sh "$ZIP_PATH" | cut -f1))"

    step "Submit to notarytool (this may take 1–5 minutes)"
    SUBMISSION_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$NOTARYTOOL_PROFILE" \
        --wait \
        --timeout 15m \
        2>&1)
    echo "$SUBMISSION_OUTPUT"

    # Extract submission ID and status for logging
    SUBMISSION_ID=$(echo "$SUBMISSION_OUTPUT" | grep 'id:' | head -1 | awk '{print $2}')
    STATUS=$(echo "$SUBMISSION_OUTPUT" | grep 'status:' | tail -1 | awk '{print $2}')

    if [[ "$STATUS" != "Accepted" ]]; then
        # Fetch the full log for diagnosis
        if [[ -n "$SUBMISSION_ID" ]]; then
            warn "Fetching notarization log for submission $SUBMISSION_ID …"
            xcrun notarytool log "$SUBMISSION_ID" \
                --keychain-profile "$NOTARYTOOL_PROFILE" 2>&1 || true
        fi
        die "Notarization failed with status: ${STATUS}"
    fi
    ok "Notarization accepted (submission: $SUBMISSION_ID)"

    # Clean up ZIP (we notarize the .app, not the ZIP for stapling)
    rm -f "$ZIP_PATH"

    step "Staple ticket to ${APP_NAME}.app"
    xcrun stapler staple "$APP_BUNDLE"
    ok "Ticket stapled"

    step "Validate stapled ticket"
    xcrun stapler validate "$APP_BUNDLE"
    spctl --assess --type execute --verbose "$APP_BUNDLE" 2>&1 && \
        ok "Gatekeeper assessment: accepted" || \
        warn "spctl assessment failed — check manually: spctl --assess --type execute --verbose '$APP_BUNDLE'"

    # Copy final app to release dir
    cp -R "$APP_BUNDLE" "$RELEASE_DIR/"
    ok "App → $RELEASE_DIR/${APP_NAME}.app"
fi

# ─── Create DMG ───────────────────────────────────────────────────────────────

if [[ "$SKIP_DMG" == "1" ]]; then
    warn "Skipping DMG creation (SKIP_DMG=1)"
else
    step "Create ${APP_NAME}-${VERSION}.dmg"

    DMG_STAGING=$(mktemp -d)
    trap 'rm -rf "$DMG_STAGING"' EXIT

    cp -R "$APP_BUNDLE" "$DMG_STAGING/"
    ln -s /Applications "$DMG_STAGING/Applications"

    # Write a minimal background-less DS_Store via AppleScript so the DMG
    # window opens to a sensible size. (Full background images require
    # create-dmg or similar; this keeps the script dependency-free.)
    # Skip if running headless (no window server).
    if [[ -n "${DISPLAY:-}" ]] || pgrep -q Finder 2>/dev/null; then
        osascript - "$DMG_STAGING" <<'APPLESCRIPT' 2>/dev/null || true
on run argv
    set stagingPath to (POSIX file (item 1 of argv)) as alias
    tell application "Finder"
        set win to (open stagingPath)
        set bounds of win to {100, 100, 700, 480}
        set current view of win to icon view
        set icon size of icon view options of win to 100
        close win
    end tell
end run
APPLESCRIPT
    fi

    rm -f "$DMG_PATH"
    hdiutil create \
        -volname "${APP_NAME}" \
        -srcfolder "$DMG_STAGING" \
        -ov \
        -format UDZO \
        -fs HFS+ \
        "$DMG_PATH" > /dev/null
    ok "DMG created: $DMG_PATH ($(du -sh "$DMG_PATH" | cut -f1))"

    step "Sign DMG"
    codesign \
        --sign "$SIGN_IDENTITY" \
        --timestamp \
        --force \
        "$DMG_PATH"
    ok "DMG signed"

    if [[ "$SKIP_NOTARIZE" != "1" ]]; then
        step "Notarize DMG"
        xcrun notarytool submit "$DMG_PATH" \
            --keychain-profile "$NOTARYTOOL_PROFILE" \
            --wait \
            --timeout 15m

        step "Staple DMG"
        xcrun stapler staple "$DMG_PATH"
        ok "DMG ticket stapled"
    fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────────

step "Release artifacts"
printf '\n'
ls -lh "$RELEASE_DIR"/ | grep -v '^total' | sed 's|^|  |'
printf '\n'
bold "  Done. Distribute:"
[[ -f "$RELEASE_DIR/${APP_NAME}.app/Contents/MacOS/${APP_NAME}" ]] && \
    bold "    .app  →  $RELEASE_DIR/${APP_NAME}.app"
[[ -f "$DMG_PATH" ]] && \
    bold "    .dmg  →  $DMG_PATH"
printf '\n'
