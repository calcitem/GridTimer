#!/bin/bash

# GridTimer initialization script
# This script sets up the project for first-time build

set -e

echo "=== GridTimer Initialization ==="
echo ""

echo "Step 1: Flutter pub get..."
flutter pub get

echo ""
echo "Step 2: Generate localization files..."
flutter gen-l10n

echo ""
echo "Step 3: Run code generation (Hive adapters, Freezed, etc.)..."
dart run build_runner build --delete-conflicting-outputs

echo ""
echo "Step 4: Analyze code..."
flutter analyze

echo ""
echo "=== Initialization Complete ==="
echo ""
echo "You can now:"
echo "  - Run on device: flutter run"
echo "  - Build APK: flutter build apk --release"
echo "  - Build AAB: flutter build appbundle --release"
echo ""
echo "Note: Make sure to add audio files to:"
echo "  - assets/sounds/"
echo "  - android/app/src/main/res/raw/"
echo ""

