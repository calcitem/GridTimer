#!/bin/bash

# Grid Timer code generation script
# Run this after modifying entities or adding new translations

set -e

echo "=== Running Code Generation ==="

echo "Generating localization..."
flutter gen-l10n

echo "Generating Dart code (Hive, Freezed, JSON)..."
dart run build_runner build --delete-conflicting-outputs

echo "=== Code Generation Complete ==="
