#!/bin/bash

# Grid Timer code generation script
# Run this after modifying entities or adding new translations
#
# For development, consider using watch mode for incremental builds:
#   dart run build_runner watch --delete-conflicting-outputs
#
# build.yaml is optimized to only scan directories with code generation:
#   - lib/core/domain/entities/** (freezed + json_serializable)
#   - lib/data/models/** (hive_ce_generator)

set -e

echo "=== Running Code Generation ==="

echo "Generating localization..."
flutter gen-l10n

echo "Generating Dart code (Hive, Freezed, JSON)..."
dart run build_runner build --delete-conflicting-outputs

echo "=== Code Generation Complete ==="
