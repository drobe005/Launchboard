#!/usr/bin/env bash
# notarize-setup.sh — One-time setup of notarytool credentials.
#
# Run this ONCE on every machine that will run release.sh.
# Credentials are stored in the login keychain, not in any file.
#
# Usage:
#   bash scripts/notarize-setup.sh
#
# You will be prompted for the authentication method and credentials.
set -euo pipefail

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ask()  { printf '\033[36m%s\033[0m ' "$*"; }

bold "────────────────────────────────────────────────────"
bold " Launchboard — notarytool credential setup"
bold "────────────────────────────────────────────────────"
printf '\nThis stores credentials in your login keychain under the\n'
printf 'profile name "launchboard-notary" (used by release.sh).\n\n'

printf 'Choose authentication method:\n'
printf '  1) App Store Connect API key  (recommended for CI + personal accounts)\n'
printf '  2) Apple ID + app-specific password\n\n'
ask "Enter 1 or 2:"
read -r METHOD

case "$METHOD" in
1)
    printf '\nYou need three values from App Store Connect → Users → Keys:\n'
    printf '  • Private key file  (.p8 downloaded when key was created)\n'
    printf '  • Key ID            (10-char alphanumeric)\n'
    printf '  • Issuer ID         (UUID shown at the top of the Keys page)\n\n'
    ask "Path to .p8 file:"
    read -r KEY_PATH
    KEY_PATH="${KEY_PATH/#\~/$HOME}"  # expand tilde
    [[ -f "$KEY_PATH" ]] || { printf 'File not found: %s\n' "$KEY_PATH"; exit 1; }

    ask "Key ID (e.g. ABCDE12345):"
    read -r KEY_ID

    ask "Issuer ID (UUID, e.g. xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx):"
    read -r ISSUER_ID

    xcrun notarytool store-credentials "launchboard-notary" \
        --key      "$KEY_PATH" \
        --key-id   "$KEY_ID" \
        --issuer   "$ISSUER_ID"
    ;;
2)
    printf '\nYou need:\n'
    printf '  • Your Apple ID email\n'
    printf '  • Your 10-char team ID (developer.apple.com → Membership)\n'
    printf '  • An APP-SPECIFIC password (appleid.apple.com → Sign-In and Security)\n'
    printf '    NOT your regular Apple ID password.\n\n'
    ask "Apple ID email:"
    read -r APPLE_ID

    ask "Team ID (e.g. XXXXXXXXXX):"
    read -r TEAM_ID

    ask "App-specific password (input hidden):"
    read -rs APP_PASSWORD
    printf '\n'

    # Store password in keychain first, then reference it
    security add-generic-password \
        -a "$APPLE_ID" \
        -s "AC_PASSWORD_LAUNCHBOARD" \
        -w "$APP_PASSWORD" \
        -U 2>/dev/null || true

    xcrun notarytool store-credentials "launchboard-notary" \
        --apple-id "$APPLE_ID" \
        --team-id  "$TEAM_ID" \
        --password "@keychain:AC_PASSWORD_LAUNCHBOARD"
    ;;
*)
    printf 'Invalid choice.\n'; exit 1 ;;
esac

printf '\n'
bold "✓ Profile \"launchboard-notary\" stored in keychain."
printf '\nVerify with:\n'
printf '  xcrun notarytool history --keychain-profile launchboard-notary\n\n'
printf 'Then run a release:\n'
printf '  TEAM_ID="XXXXXXXXXX" DEVELOPER_NAME="Your Name" bash scripts/release.sh\n\n'
