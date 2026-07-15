#!/bin/bash
# Package dist/Vois.app into a drag-to-Applications DMG.
# Usage: scripts/make-dmg.sh [output.dmg]   (default: dist/Vois.dmg)
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${1:-dist/Vois.dmg}"
[ -d dist/Vois.app ] || { echo "error: dist/Vois.app missing — run scripts/bundle.sh first" >&2; exit 1; }

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -R dist/Vois.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$OUT"
hdiutil create -volname "Vois" -srcfolder "$STAGE" -ov -format UDZO "$OUT" -quiet
echo "Created $OUT"
