#!/bin/bash

# GridTimer release build script
# Builds signed AAB for Play Store submission

set -e

echo "=== GridTimer Release Build ==="
echo ""

echo "Step 1: Clean build artifacts..."
flutter clean

echo ""
echo "Step 2: Get dependencies..."
flutter pub get

echo ""
echo "Step 3: Generate code..."
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "Step 4: Analyze code..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "ERROR: Code analysis failed. Fix issues before building release."
    exit 1
fi

echo ""
echo "Step 5: Build AAB for Play Store..."
flutter build appbundle --release

echo ""
echo "=== Build Complete ==="
echo ""
echo "Output location:"
echo "  build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Next steps:"
echo "  1. Test the AAB using bundletool"
echo "  2. Upload to Play Console"
echo "  3. Complete store listing and content rating"
echo ""

