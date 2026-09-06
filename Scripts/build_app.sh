#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🔨 Building Skiller in release mode..."
swift build -c release

APP_NAME="Skiller"
TARGET_DIR="/Applications"
APP_BUNDLE="$TARGET_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean up any old dist folder to prevent duplicate apps being indexed by macOS
rm -rf "$DIR/dist"

echo "📦 Installing $APP_NAME to $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

BIN_PATH="$(swift build -c release --show-bin-path)/Skiller"
cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# SwiftPM resolves Bundle.module relative to the application bundle.
RESOURCE_BUNDLE="$(swift build -c release --show-bin-path)/Skiller_Skiller.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    ditto "$RESOURCE_BUNDLE" "$APP_BUNDLE/Skiller_Skiller.bundle"
fi

# Copy Icon
if [ -f "$DIR/Sources/Skiller/Resources/AppIcon.icns" ]; then
    cp "$DIR/Sources/Skiller/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    if [ -d "$APP_BUNDLE/Skiller_Skiller.bundle" ]; then
        cp "$DIR/Sources/Skiller/Resources/AppIcon.icns" "$APP_BUNDLE/Skiller_Skiller.bundle/AppIcon.icns"
    fi
fi
if [ -f "$DIR/Sources/Skiller/Resources/AppIcon.png" ]; then
    cp "$DIR/Sources/Skiller/Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"
    if [ -d "$APP_BUNDLE/Skiller_Skiller.bundle" ]; then
        cp "$DIR/Sources/Skiller/Resources/AppIcon.png" "$APP_BUNDLE/Skiller_Skiller.bundle/AppIcon.png"
    fi
fi
if [ -f "$DIR/Sources/Skiller/Resources/MenuBarIcon.png" ]; then
    cp "$DIR/Sources/Skiller/Resources/MenuBarIcon.png" "$RESOURCES_DIR/MenuBarIcon.png"
    if [ -d "$APP_BUNDLE/Skiller_Skiller.bundle" ]; then
        cp "$DIR/Sources/Skiller/Resources/MenuBarIcon.png" "$APP_BUNDLE/Skiller_Skiller.bundle/MenuBarIcon.png"
    fi
fi

# Create Info.plist
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.skiller.app</string>
    <key>CFBundleName</key>
    <string>Skiller</string>
    <key>CFBundleDisplayName</key>
    <string>Skiller</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ Successfully installed $APP_BUNDLE!"

# Set the Finder kHasCustomIcon flag via NSWorkspace.setIcon
# This is the critical step that makes the transparent icon float without a squircle.
echo "🎨 Setting Finder custom icon flag on $APP_BUNDLE..."
swift -e "
import Cocoa
let appPath = \"$APP_BUNDLE\"
let icnsPath = appPath + \"/Contents/Resources/AppIcon.icns\"
if let img = NSImage(contentsOfFile: icnsPath) {
    let ok = NSWorkspace.shared.setIcon(img, forFile: appPath, options: [])
    print(ok ? \"   ✅ kHasCustomIcon flag set\" : \"   ❌ Failed to set icon\")
} else {
    print(\"   ❌ Could not load icns\")
}
"

# Force register with macOS LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE"

echo "🚀 You can launch it using: open \"$APP_BUNDLE\""
