#!/bin/bash

# Universal Manifestor - Branding Asset Setup Script
# This script copies and prepares branding assets for GitHub Pages

echo "🎨 Setting up Universal Manifestor branding assets..."

# Directories
PROJECT_DIR="/Users/jeremymcvay/dev/UniversalManifestor"
DOCS_DIR="$PROJECT_DIR/docs/assets"
APPICON_DIR="$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset"

# Create docs assets directory if it doesn't exist
mkdir -p "$DOCS_DIR"

# Check if the main icon exists
if [ -f "$APPICON_DIR/AppIcon.png" ]; then
    echo "✓ Found AppIcon.png in Assets.xcassets"
    
    # Copy to docs/assets for GitHub Pages
    cp "$APPICON_DIR/AppIcon.png" "$DOCS_DIR/AppIcon.png"
    echo "✓ Copied AppIcon.png to docs/assets/"
else
    echo "✗ AppIcon.png not found in Assets.xcassets"
    echo "  Please ensure you've cropped the main icon and saved it as AppIcon.png"
    exit 1
fi

# Create README for docs
cat > "$DOCS_DIR/README.md" << 'EOF'
# Universal Manifestor - Branding Assets

This directory contains the branding assets used in Universal Manifestor documentation and GitHub Pages.

## Files

- `AppIcon.png` - Main application icon (1024x1024)

## Usage

These assets are automatically copied from the main Assets.xcassets directory.
Do not edit these files directly.

## License

© 2026 Universal Manifestor. All rights reserved.
EOF

echo "✓ Created README.md in docs/assets/"

# Verify GitHub Pages structure
if [ -f "$PROJECT_DIR/docs/index.html" ] && [ -f "$PROJECT_DIR/docs/support.html" ]; then
    echo "✓ GitHub Pages structure is complete"
else
    echo "✗ GitHub Pages files missing"
    exit 1
fi

echo ""
echo "🎉 Branding setup complete!"
echo ""
echo "Next steps:"
echo "1. Commit all files to git"
echo "2. Push to GitHub"
echo "3. Enable GitHub Pages in repository settings"
echo "4. Set Pages source to 'docs' folder"
echo ""
