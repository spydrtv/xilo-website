#!/bin/bash
# Downloads the XILO Music app icon from Cloudinary into assets/icon/
# This must run before: dart run flutter_launcher_icons
# Called automatically by the Primio iOS build pipeline.

set -e

ICON_URL="https://res.cloudinary.com/dtoryfbxl/image/upload/v1775924175/XILO_app_store_1024x1024_uzbqor.png"
DEST="assets/icon/app_icon.png"

mkdir -p assets/icon

echo "Downloading XILO Music app icon..."
curl -fsSL "$ICON_URL" -o "$DEST"
echo "Icon saved to $DEST ($(du -h "$DEST" | cut -f1))"
