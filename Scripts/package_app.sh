#!/bin/zsh
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "usage: ./Scripts/package_app.sh [version]" >&2
  exit 1
fi

VERSION="${1:-v0.1.0}"
MARKETING_VERSION="${VERSION#v}"
ARCH="$(uname -m)"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BIN_DIR="$(cd "$ROOT_DIR" && swift build -c release --show-bin-path)"
APP_NAME="TokenSaver.app"
APP_DIR="$DIST_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCE_DIR="$CONTENTS_DIR/Resources"
PLIST_PATH="$CONTENTS_DIR/Info.plist"
PKGINFO_PATH="$CONTENTS_DIR/PkgInfo"
EXECUTABLE_SOURCE="$BIN_DIR/TokenSaverApp"
EXECUTABLE_DEST="$MACOS_DIR/TokenSaverApp"
ZIP_NAME="TokenSaver-${VERSION}-macos-${ARCH}.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
CHECKSUM_PATH="$ZIP_PATH.sha256"

mkdir -p "$MACOS_DIR" "$RESOURCE_DIR"

cd "$ROOT_DIR"
swift build -c release

cp -f "$EXECUTABLE_SOURCE" "$EXECUTABLE_DEST"
chmod 755 "$EXECUTABLE_DEST"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>TokenSaver</string>
  <key>CFBundleExecutable</key>
  <string>TokenSaverApp</string>
  <key>CFBundleIdentifier</key>
  <string>com.hjsthejoker.tokensaver</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>TokenSaver</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${MARKETING_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${MARKETING_VERSION}</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.developer-tools</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

printf 'APPL????' > "$PKGINFO_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

echo "App bundle: $APP_DIR"
echo "Zip asset: $ZIP_PATH"
echo "Checksum: $CHECKSUM_PATH"
