#!/bin/bash

# GridTimer initialization script
# This script sets up the project for first-time build

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== GridTimer Initialization ==="
echo ""

echo "Step 0: Generate Git information files..."
GIT_INFO_PATH="${SCRIPT_DIR}/assets/files"
GIT_BRANCH_FILE="${GIT_INFO_PATH}/git-branch.txt"
GIT_REVISION_FILE="${GIT_INFO_PATH}/git-revision.txt"

mkdir -p "${GIT_INFO_PATH}" || true

# Handle both branch and tag/detached HEAD scenarios
if git -C "${SCRIPT_DIR}" symbolic-ref --short HEAD > "${GIT_BRANCH_FILE}" 2>/dev/null; then
    # Successfully got branch name
    :
else
    # In detached HEAD state (tag checkout), try to get tag name or commit hash
    if TAG_NAME=$(git -C "${SCRIPT_DIR}" describe --exact-match --tags HEAD 2>/dev/null); then
        echo "${TAG_NAME}" > "${GIT_BRANCH_FILE}"
    else
        # Fallback to commit hash
        git -C "${SCRIPT_DIR}" rev-parse --short HEAD > "${GIT_BRANCH_FILE}"
    fi
fi
git -C "${SCRIPT_DIR}" rev-parse HEAD > "${GIT_REVISION_FILE}"

echo "Generated git-branch.txt and git-revision.txt"
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
