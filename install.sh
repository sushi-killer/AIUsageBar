#!/bin/bash
set -euo pipefail

APP_NAME="AI Usage Bar"
ZIP_NAME="AIUsageBar"
REPO="sushi-killer/AIUsageBar"
INSTALL_DIR="/Applications"

echo "Installing $APP_NAME..."

# Get latest release tag
LATEST=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$LATEST" ]; then
  echo "Error: Could not determine latest release."
  exit 1
fi

echo "Latest version: $LATEST"

DOWNLOAD_URL="https://github.com/$REPO/releases/download/v${LATEST}/${ZIP_NAME}-${LATEST}.zip"
TMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Download
echo "Downloading $APP_NAME v$LATEST..."
curl -fsSL -o "$TMP_DIR/$ZIP_NAME.zip" "$DOWNLOAD_URL"

# Extract
echo "Extracting..."
unzip -q "$TMP_DIR/$ZIP_NAME.zip" -d "$TMP_DIR"

# Install
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
  echo "Removing previous installation..."
  rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

echo "Moving to $INSTALL_DIR..."
mv "$TMP_DIR/$APP_NAME.app" "$INSTALL_DIR/"

# Remove quarantine attribute (ad-hoc signed)
xattr -cr "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

echo ""
echo "$APP_NAME v$LATEST installed successfully."
echo "Launching..."
open "$INSTALL_DIR/$APP_NAME.app"
