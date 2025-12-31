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
echo "Step 4: Verify generated files..."
# List some expected generated files to confirm they exist
ls -l lib/core/domain/entities/*.freezed.dart 2>/dev/null || echo "Warning: Some freezed files may not be generated"
ls -l lib/core/domain/entities/*.g.dart 2>/dev/null || echo "Warning: Some g.dart files may not be generated"

echo ""
echo "Step 5: Refresh pub cache to ensure analyzer sees generated files..."
flutter pub get

echo ""
echo "Step 6: Clean analysis cache..."
# Remove analysis cache to force re-analysis
rm -rf .dart_tool/analysis_cache 2>/dev/null || true

echo ""
echo "Step 7: Analyze code..."
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



