#!/bin/bash

# Build GridTimer APK with test environment configuration for Monkey testing
# This script builds an APK with test=true flag which disables:
# - URL launching (privacy policy links)
# - System settings opening
# - App exit functionality

set -e

echo "Building GridTimer APK with test environment..."
echo "This will disable URL launching, system settings, and app exit to prevent Monkey test interference."
echo ""

# Build APK with test flag
flutter build apk --dart-define=test=true

echo ""
echo "Build complete!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "To install on device:"
echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "To run Monkey test:"
echo "  ./tests/monkey/monkey.sh"

