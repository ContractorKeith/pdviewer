#!/bin/bash
# Build, sign, notarize, and package pdviewer as a DMG for GitHub Releases.
#
# Usage:
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE=pdviewer-notary \
#   scripts/release.sh 0.1.0
#
# One-time setup for notarization (stores an app-specific password in the keychain):
#   xcrun notarytool store-credentials pdviewer-notary --apple-id you@example.com --team-id TEAMID
#
# Without SIGN_IDENTITY the app is ad-hoc signed and not notarized (local testing only).
set -euo pipefail

VERSION="${1:?usage: release.sh <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
ARCHIVE="$DIST/pdviewer.xcarchive"
APP="$DIST/pdviewer.app"
DMG="$DIST/pdviewer-$VERSION.dmg"
STAGE="$DIST/dmg-stage"

cd "$ROOT"
rm -rf "$DIST"
mkdir -p "$DIST"

# Stamp the version into project.yml-generated Info.plist via build settings.
xcodegen generate -q
xcodebuild -project pdviewer.xcodeproj -scheme pdviewer -configuration Release \
  -destination 'platform=macOS' -archivePath "$ARCHIVE" \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$(git rev-list --count HEAD)" \
  CODE_SIGN_IDENTITY="${SIGN_IDENTITY:--}" CODE_SIGN_STYLE=Manual \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  archive -quiet

cp -R "$ARCHIVE/Products/Applications/pdviewer.app" "$APP"

if [ -n "${SIGN_IDENTITY:-}" ]; then
  echo "Signing with: $SIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp \
    --entitlements pdviewer/Resources/pdviewer.entitlements \
    --sign "$SIGN_IDENTITY" "$APP"
  codesign --verify --strict --verbose=2 "$APP"
fi

# DMG via hdiutil: no extra tooling needed.
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "pdviewer $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" -quiet
rm -rf "$STAGE"

if [ -n "${SIGN_IDENTITY:-}" ]; then
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "Notarizing (this can take a few minutes)..."
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
  else
    echo "NOTARY_PROFILE not set; skipping notarization."
  fi
fi

shasum -a 256 "$DMG" | tee "$DMG.sha256"
echo "Done: $DMG"
