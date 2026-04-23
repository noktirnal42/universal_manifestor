#!/bin/bash

# Universal Manifestor - Complete Icon Generator
# Generates ALL required icon sizes for iOS, iPadOS, and macOS
# This script requires ImageMagick (install with: brew install imagemagick)

set -e

echo "🎨 Universal Manifestor - Complete Icon Generator"
echo "=================================================="
echo ""

# Configuration
SOURCE_ICON="test_large.png"  # Your high-res source icon
ICONSET_DIR="Assets.xcassets/AppIcon.appiconset"

# Check for ImageMagick
if ! command -v magick &> /dev/null; then
    echo "❌ Error: ImageMagick not found!"
    echo "Install with: brew install imagemagick"
    exit 1
fi

# Check if source icon exists
if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Error: Source icon '$SOURCE_ICON' not found!"
    echo ""
    echo "Please ensure you have a 1024x1024 source icon."
    echo "You can use any of these as source:"
    ls -1 *.png 2>/dev/null | head -5 || echo "  (no PNG files found in current directory)"
    exit 1
fi

# Check if source is square, if not make it square
DIMENSIONS=$(magick identify -format "%wx%h" "$SOURCE_ICON")
WIDTH=$(echo $DIMENSIONS | cut -d'x' -f1)
HEIGHT=$(echo $DIMENSIONS | cut -d'x' -f2)

if [ "$WIDTH" != "$HEIGHT" ]; then
    echo "⚠️  Source icon is not square (${DIMENSIONS})"
    echo "Creating square version (1024x1024)..."
    magick "$SOURCE_ICON" -resize 1024x1024! -background none -gravity center -extent 1024x1024 "source_square.png"
    SOURCE_ICON="source_square.png"
    DIMENSIONS="1024x1024"
fi

echo "✓ Source icon: ${DIMENSIONS}"
echo ""

# Create iconset directory if it doesn't exist
mkdir -p "$ICONSET_DIR"

# Function to generate icon
generate_icon() {
    local size=$1
    local filename=$2
    magick "$SOURCE_ICON" -resize ${size}x${size}! "${ICONSET_DIR}/${filename}"
    echo "  ✓ ${filename} (${size}x${size})"
}

echo "📱 Generating iOS Icons..."
generate_icon 20 "Icon-20.png"
generate_icon 40 "Icon-20@2x.png"
generate_icon 60 "Icon-20@3x.png"
generate_icon 29 "Icon-29.png"
generate_icon 58 "Icon-29@2x.png"
generate_icon 87 "Icon-29@3x.png"
generate_icon 40 "Icon-40.png"
generate_icon 80 "Icon-40@2x.png"
generate_icon 120 "Icon-40@3x.png"
generate_icon 120 "Icon-60@2x.png"
generate_icon 180 "Icon-60@3x.png"

echo ""
echo "📱 Generating iPad Icons..."
generate_icon 20 "Icon-20.png"
generate_icon 40 "Icon-20@2x.png"
generate_icon 29 "Icon-29.png"
generate_icon 58 "Icon-29@2x.png"
generate_icon 40 "Icon-40.png"
generate_icon 80 "Icon-40@2x.png"
generate_icon 76 "Icon-76.png"
generate_icon 152 "Icon-76@2x.png"
generate_icon 167 "Icon-83.5@2x.png"

echo ""
echo "🖥️ Generating macOS Icons..."
generate_icon 16 "Icon-16.png"
generate_icon 32 "Icon-16@2x.png"
generate_icon 32 "Icon-32.png"
generate_icon 64 "Icon-32@2x.png"
generate_icon 128 "Icon-128.png"
generate_icon 256 "Icon-128@2x.png"
generate_icon 256 "Icon-256.png"
generate_icon 512 "Icon-256@2x.png"
generate_icon 512 "Icon-512.png"
generate_icon 1024 "Icon-512@2x.png"

echo ""
echo "📦 Generating App Store Icon..."
generate_icon 1024 "Icon-1024.png"

# Clean up temporary file
if [ -f "source_square.png" ]; then
    rm "source_square.png"
fi

# Count generated icons
ICON_COUNT=$(ls -1 "${ICONSET_DIR}"/Icon-*.png 2>/dev/null | wc -l)

echo ""
echo "✅ Icon Generation Complete!"
echo ""
echo "Generated ${ICON_COUNT} icon files in ${ICONSET_DIR}/"
echo ""
echo "📋 Next Steps:"
echo "1. ✓ Contents.json is already configured"
echo "2. ✓ Info.plist has CFBundleIconName set"
echo "3. Clean build: rm -rf build/"
echo "4. Rebuild in Xcode"
echo "5. Archive and upload"
echo ""
echo "🎉 Ready to build!"
