#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="Command X.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp AppIcon.icns "$APP/Contents/Resources/"
swiftc main.swift -o "$APP/Contents/MacOS/CommandX" -framework AppKit -framework ApplicationServices -framework ServiceManagement
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleExecutable</key><string>CommandX</string><key>CFBundleIdentifier</key><string>com.commandx.utility</string><key>CFBundleName</key><string>Command X</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>3</string><key>CFBundleIconFile</key><string>AppIcon.icns</string><key>CFBundleShortVersionString</key><string>1.2</string><key>LSUIElement</key><true/></dict></plist>
PLIST
codesign --force --sign - "$APP"
open "$APP"
