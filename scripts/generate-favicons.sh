#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$SCRIPT_DIR/../frontend/public"

# Find the logo — prefer .png, fall back to .jpg
if [ -f "$SCRIPT_DIR/seed-images/logo.png" ]; then
  SRC="$SCRIPT_DIR/seed-images/logo.png"
elif [ -f "$SCRIPT_DIR/seed-images/logo.jpg" ]; then
  SRC="$SCRIPT_DIR/seed-images/logo.jpg"
else
  echo "ERROR: No logo.png or logo.jpg found in $SCRIPT_DIR/seed-images/"
  exit 1
fi

echo "==> Generating favicons from $(basename "$SRC")..."

# Working copy so we don't modify the source
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 180x180 Apple Touch Icon
cp "$SRC" "$TMP/source"
sips -z 180 180 "$TMP/source" --setProperty format png --out "$OUT/apple-touch-icon.png" 2>/dev/null
echo "  - apple-touch-icon.png (180x180)"

# 192x192 Android / PWA
cp "$SRC" "$TMP/source192"
sips -z 192 192 "$TMP/source192" --setProperty format png --out "$OUT/favicon-192.png" 2>/dev/null
echo "  - favicon-192.png (192x192)"

# 32x32 for favicon.ico
cp "$SRC" "$TMP/source32"
sips -z 32 32 "$TMP/source32" --setProperty format png --out "$TMP/favicon-32.png" 2>/dev/null

if command -v magick &> /dev/null; then
  magick "$TMP/favicon-32.png" "$OUT/favicon.ico"
  echo "  - favicon.ico (32x32, via ImageMagick)"
elif command -v convert &> /dev/null; then
  convert "$TMP/favicon-32.png" "$OUT/favicon.ico"
  echo "  - favicon.ico (32x32, via convert)"
else
  cp "$TMP/favicon-32.png" "$OUT/favicon.ico"
  echo "  - favicon.ico (32x32 PNG — install ImageMagick for proper ICO)"
fi

# Remove old Astro default
rm -f "$OUT/favicon.svg"

echo "==> Done!"
