#!/bin/bash

# Generate API Documentation for stellar-ios-mac-sdk
# This script builds DocC documentation and exports it for web hosting

set -e

echo "Building DocC documentation..."
cd "$(dirname "$0")"

# Clean previous builds
rm -rf stellarsdk/DerivedData/Build/Products/Debug/stellarsdk.doccarchive 2>/dev/null || true
rm -rf api-docs 2>/dev/null || true

# Build documentation
xcodebuild docbuild \
    -scheme stellarsdk \
    -destination 'platform=macOS' \
    -derivedDataPath ./stellarsdk/DerivedData

echo "Documentation built successfully!"
echo "Location: stellarsdk/DerivedData/Build/Products/Debug/stellarsdk.doccarchive"

# Open in Xcode for viewing
echo "Opening documentation in Xcode..."
open -a Xcode ./stellarsdk/DerivedData/Build/Products/Debug/stellarsdk.doccarchive

# Export for static hosting
echo "Exporting for static web hosting..."
xcrun docc process-archive \
    transform-for-static-hosting \
    ./stellarsdk/DerivedData/Build/Products/Debug/stellarsdk.doccarchive \
    --output-path ./api-docs \
    --hosting-base-path /stellar-ios-mac-sdk

# Fix root index.html to use correct base path for GitHub Pages
echo "Fixing root index.html for GitHub Pages..."
sed -i '' -e 's|var baseUrl = "/"|var baseUrl = "/stellar-ios-mac-sdk/"|g' \
    -e 's|href="/favicon.ico"|href="/stellar-ios-mac-sdk/favicon.ico"|g' \
    -e 's|href="/favicon.svg"|href="/stellar-ios-mac-sdk/favicon.svg"|g' \
    -e 's|src="/js/|src="/stellar-ios-mac-sdk/js/|g' \
    -e 's|href="/css/|href="/stellar-ios-mac-sdk/css/|g' \
    ./api-docs/index.html

echo ""
echo "Documentation generated successfully!"
echo ""
echo "To view locally:"
echo "  - Xcode: Already opened"
echo "  - Web: cd api-docs && python3 -m http.server 8080"
echo "         Then visit: http://localhost:8080/documentation/stellarsdk/"
echo ""
echo "To deploy to GitHub Pages:"
echo "  - Copy api-docs/* to your docs/ folder or gh-pages branch"
echo ""
