#!/bin/bash
# Package dist/Vois.app into a styled drag-to-Applications DMG (background
# image, arrow, 128pt icons at fixed positions).
# Usage: scripts/make-dmg.sh [output.dmg]   (default: dist/Vois.dmg)
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${1:-dist/Vois.dmg}"
VOL="Vois"
[ -d dist/Vois.app ] || { echo "error: dist/Vois.app missing — run scripts/bundle.sh first" >&2; exit 1; }
[ -f assets/dmg-background.png ] || swift scripts/gen-dmg-bg.swift

STAGE=$(mktemp -d)
RW=$(mktemp -u).dmg
trap 'rm -rf "$STAGE" "$RW"' EXIT
cp -R dist/Vois.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
mkdir "$STAGE/.background"
cp assets/dmg-background.png "$STAGE/.background/background.png"

# Read-write image first so Finder view options can be baked in.
hdiutil create -volname "$VOL" -srcfolder "$STAGE" -ov -format UDRW "$RW" -quiet
MOUNT=$(hdiutil attach "$RW" -readwrite -noautoopen | awk -F'\t' '/\/Volumes\//{print $3; exit}')

osascript <<EOF
tell application "Finder"
    tell disk "$VOL"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- window content 660x400, matching assets/dmg-background.png points
        set the bounds of container window to {200, 140, 860, 540}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to POSIX file "$MOUNT/.background/background.png"
        set position of item "Vois.app" of container window to {165, 190}
        set position of item "Applications" of container window to {495, 190}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

sync
hdiutil detach "$MOUNT" -quiet
rm -f "$OUT"
hdiutil convert "$RW" -format UDZO -o "$OUT" -quiet
echo "Created $OUT"
