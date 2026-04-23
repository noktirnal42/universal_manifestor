#!/bin/bash

echo "🎨 Finalizing Universal Manifestor GitHub Repository Setup"
echo "=========================================================="
echo ""

# Directories
PROJECT_DIR="/Users/jeremymcvay/dev/UniversalManifestor"
APPICON_DIR="$PROJECT_DIR/Assets.xcassets/AppIcon.appiconset"
DOCS_ASSETS_DIR="$PROJECT_DIR/docs/assets"

# Check for cropped icon
if [ -f "$PROJECT_DIR/test_large.png" ]; then
    echo "✓ Found test_large.png - checking if it's the cropped icon..."
    
    # Get dimensions
    DIMS=$(magick identify -format "%wx%h" "$PROJECT_DIR/test_large.png")
    echo "  Image dimensions: $DIMS"
    
    # Ask user if this is the correct crop
    read -p "Is this the correctly cropped main app icon? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Copy as the main icon
        cp "$PROJECT_DIR/test_large.png" "$APPICON_DIR/AppIcon.png"
        cp "$PROJECT_DIR/test_large.png" "$APPICON_DIR/AppIcon-macOS.png"
        echo "✓ Set as main app icon"
        
        # Copy to docs/assets
        mkdir -p "$DOCS_ASSETS_DIR"
        cp "$PROJECT_DIR/test_large.png" "$DOCS_ASSETS_DIR/AppIcon.png"
        echo "✓ Copied to docs/assets/"
    fi
fi

# Verify app icons exist
if [ -f "$APPICON_DIR/AppIcon.png" ]; then
    echo "✓ AppIcon.png exists"
else
    echo "✗ AppIcon.png not found - please crop the icon first"
    exit 1
fi

# Clean up test files
echo ""
echo "Cleaning up test files..."
rm -f "$PROJECT_DIR"/test_*.png
rm -f "$PROJECT_DIR"/extract_icons.sh
echo "✓ Cleaned up test files"

# Git setup
echo ""
echo "Preparing for git..."
cd "$PROJECT_DIR"

# Create initial commit
git add .
echo "✓ All files staged for commit"

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Review changes: git status"
echo "2. Commit: git commit -m 'Initial commit: Universal Manifestor app and documentation'"
echo "3. Push: git push origin main"
echo "4. Enable GitHub Pages in repository settings"
echo ""

