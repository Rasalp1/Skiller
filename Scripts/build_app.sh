#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🔨 Building SkillsManagerApp in release mode..."
swift build -c release

APP_NAME="SkillsManager"
DIST_DIR="$DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating macOS App Bundle at $APP_BUNDLE..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

BIN_PATH="$(swift build -c release --show-bin-path)/SkillsManagerApp"
cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# SwiftPM resolves Bundle.module relative to the application bundle.
RESOURCE_BUNDLE="$(swift build -c release --show-bin-path)/SkillsManagerApp_SkillsManagerApp.bundle"
ditto "$RESOURCE_BUNDLE" "$APP_BUNDLE/SkillsManagerApp_SkillsManagerApp.bundle"

# Copy Icon
if [ -f "$DIR/Sources/SkillsManagerApp/Resources/AppIcon.icns" ]; then
    cp "$DIR/Sources/SkillsManagerApp/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    cp "$DIR/Sources/SkillsManagerApp/Resources/AppIcon.icns" "$APP_BUNDLE/SkillsManagerApp_SkillsManagerApp.bundle/AppIcon.icns"
fi
if [ -f "$DIR/Sources/SkillsManagerApp/Resources/AppIcon.png" ]; then
    cp "$DIR/Sources/SkillsManagerApp/Resources/AppIcon.png" "$RESOURCES_DIR/AppIcon.png"
    cp "$DIR/Sources/SkillsManagerApp/Resources/AppIcon.png" "$APP_BUNDLE/SkillsManagerApp_SkillsManagerApp.bundle/AppIcon.png"
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
    <string>com.skillsmanager.app</string>
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

echo "✅ Successfully built $APP_BUNDLE!"
echo "🚀 You can launch it using: open \"$APP_BUNDLE\""
