#!/bin/bash
# Build Vois.app via xcodebuild (SwiftPM CLI can't compile MLX Metal shaders),
# bundling frameworks, SPM resource bundles, and the Kokoro model.
# Usage: scripts/bundle.sh [Debug|Release]   (default: Release)
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-Release}"
DERIVED=.build/xcode
PRODUCTS="$DERIVED/Build/Products/$CONFIG"
APP=dist/Vois.app

[ -d Models/Kokoro/voices ] || { echo "error: Models/Kokoro missing — run scripts/fetch-model.sh first" >&2; exit 1; }

xcodebuild build -scheme Vois -configuration "$CONFIG" \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$DERIVED" -quiet

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$PRODUCTS/Vois" "$APP/Contents/MacOS/Vois"

# SPM dynamic-library frameworks.
cp -R "$PRODUCTS/PackageFrameworks/"*.framework "$APP/Contents/Frameworks/"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/Vois" 2>/dev/null || true

# SPM resource bundles (KokoroSwift config.json, MLX metallib, etc.).
find "$PRODUCTS" -maxdepth 1 -name "*.bundle" -exec cp -R {} "$APP/Contents/Resources/" \;

# Kokoro model + voices (PRD: bundled, zero network at runtime).
# The .f32 original stays out — only the bf16 weights ship.
mkdir -p "$APP/Contents/Resources/Kokoro"
cp Models/Kokoro/kokoro-v1_0.safetensors "$APP/Contents/Resources/Kokoro/"
cp -R Models/Kokoro/voices "$APP/Contents/Resources/Kokoro/voices"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>Vois</string>
	<key>CFBundleIdentifier</key><string>app.vois.Vois</string>
	<key>CFBundleName</key><string>Vois</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>1.0</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSMinimumSystemVersion</key><string>15.0</string>
	<key>LSUIElement</key><true/>
	<key>NSAppleEventsUsageDescription</key><string>Vois uses AppleScript as a fallback to read your selected text in browsers.</string>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist"

# Ad-hoc signing (replace with Developer ID + notarization for distribution).
find "$APP/Contents/Frameworks" -name "*.framework" -maxdepth 1 -exec codesign --force --sign - {} \;
codesign --force --sign - "$APP"
echo "Built $APP"
