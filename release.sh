#!/bin/bash

# GridTimer Release Script
# Usage:
#   ./release.sh       - Bump patch version (1.0.0 -> 1.0.1)
#   ./release.sh -y    - Bump minor version (1.0.0 -> 1.1.0)
#   ./release.sh -x    - Bump major version (1.0.0 -> 2.0.0)

set -e

# Get current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Only allow release from master or main branch
if [ "$CURRENT_BRANCH" != "master" ] && [ "$CURRENT_BRANCH" != "main" ]; then
  echo "Error: Release is only allowed from 'master' or 'main' branch."
  echo "Current branch: $CURRENT_BRANCH"
  exit 1
fi

echo "Current branch: $CURRENT_BRANCH"

# Check if the latest tag follows vX.Y.Z format
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LATEST_TAG" ]; then
  echo "Warning: No tags found in the repository."
else
  echo "Latest tag: $LATEST_TAG"
  # Check if tag matches vX.Y.Z format (X, Y, Z are digits)
  if ! echo "$LATEST_TAG" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Error: The latest tag '$LATEST_TAG' does not follow the vX.Y.Z format."
    echo "Expected format: vX.Y.Z (e.g., v1.2.3)"
    exit 1
  fi
  echo "Tag format check passed: $LATEST_TAG follows vX.Y.Z format"
fi

# Configuration
YAML_FILE=pubspec.yaml

CHANGELOG_DIRS=(
  "fastlane/metadata/android/en-US/changelogs"
  "fastlane/metadata/android/zh-CN/changelogs"
)

# Determine SED command based on OS
SED=sed
if [ "$(uname)" == "Darwin" ]; then
  SED=gsed
fi

# Check for uncommitted changes
if ! git diff --quiet HEAD; then
  echo "Warning: There are uncommitted changes in the repository."
  read -p "Do you want to continue? (y/n): " continue_choice
  if [ "$continue_choice" != "y" ]; then
    echo "Aborting release."
    exit 1
  fi
fi

# Run flutter analyze
echo ""
echo "Running flutter analyze..."
flutter analyze
if [ $? -ne 0 ]; then
  echo "Error: Flutter analyze failed. Fix issues before releasing."
  exit 1
fi

# Read current version from pubspec.yaml
# version: 1.0.0+1
VERSION_LINE=$($SED -n '/^version:/p' $YAML_FILE)
echo "VERSION_LINE = $VERSION_LINE"

# 1.0.0+1
FULL_VERSION=$(echo "$VERSION_LINE" | cut -d ' ' -f 2)
echo "FULL_VERSION = $FULL_VERSION"

# 1.0.0
VERSION=$(echo "$FULL_VERSION" | cut -d "+" -f 1)
echo "VERSION = $VERSION"
OLD_VERSION=$VERSION
echo "OLD_VERSION = $OLD_VERSION"

# Parse version numbers
MAJOR_NUMBER=$(echo "$VERSION" | cut -d "." -f 1)
MINOR_NUMBER=$(echo "$VERSION" | cut -d "." -f 2)
PATCH_NUMBER=$(echo "$VERSION" | cut -d "." -f 3)

echo ""
echo "Current version:"
echo "  MAJOR = $MAJOR_NUMBER"
echo "  MINOR = $MINOR_NUMBER"
echo "  PATCH = $PATCH_NUMBER"

OLD_PATCH_NUMBER=$PATCH_NUMBER

# Determine version bump type
arg=${1#-}
arg=${arg#-}

if [ "$arg" == "x" ]; then
  ((MAJOR_NUMBER+=1))
  MINOR_NUMBER=0
  PATCH_NUMBER=0
  BUMP_TYPE="major"
elif [ "$arg" == "y" ]; then
  ((MINOR_NUMBER+=1))
  PATCH_NUMBER=0
  BUMP_TYPE="minor"
else
  ((PATCH_NUMBER+=1))
  BUMP_TYPE="patch"
fi

echo ""
echo "Bumping $BUMP_TYPE version..."
echo "New version:"
echo "  MAJOR = $MAJOR_NUMBER"
echo "  MINOR = $MINOR_NUMBER"
echo "  PATCH = $PATCH_NUMBER"

# 1.0.1
NEW_VERSION="${MAJOR_NUMBER}.${MINOR_NUMBER}.${PATCH_NUMBER}"
echo ""
echo "NEW_VERSION = $NEW_VERSION"

# Get build number from total commit count (same as version.sh)
BUILD_NUMBER=$(git rev-list HEAD | wc -l | awk '{print $1}')
echo "BUILD_NUMBER = $BUILD_NUMBER (total commits)"

# 1.0.1+2
NEW_FULL_VERSION="$NEW_VERSION+$BUILD_NUMBER"
echo "NEW_FULL_VERSION = $NEW_FULL_VERSION"

# Modify pubspec.yaml
echo ""
echo "Updating $YAML_FILE..."
$SED -i "s/^version: .*/version: $NEW_FULL_VERSION/" $YAML_FILE

# Create changelog files
echo ""
echo "Creating changelog files..."
CHANGELOG_CONTENT_EN="v$NEW_VERSION

This update includes various improvements and bug fixes to make the app better for you."

CHANGELOG_CONTENT_ZH="v$NEW_VERSION

此更新包括各种改进和错误修复，以使应用更好用。"

for DIR in "${CHANGELOG_DIRS[@]}"; do
  mkdir -p "$DIR"
  if [[ $DIR == *"zh-CN"* ]]; then
    echo "$CHANGELOG_CONTENT_ZH" > "$DIR/${BUILD_NUMBER}.txt"
    echo "  Created: $DIR/${BUILD_NUMBER}.txt (Chinese)"
  else
    echo "$CHANGELOG_CONTENT_EN" > "$DIR/${BUILD_NUMBER}.txt"
    echo "  Created: $DIR/${BUILD_NUMBER}.txt (English)"
  fi
done

# Show changes
echo ""
echo "=== Changes Summary ==="
git diff --stat
echo ""
git diff $YAML_FILE

# Git operations
echo ""
echo "=== Git Operations ==="
git status -s
git add .
git commit -m "GridTimer v$NEW_VERSION ($BUILD_NUMBER)" -m "Official release version of GridTimer v$NEW_VERSION"

# Create tag (delete existing if present)
git tag -d "v$NEW_VERSION" 2>/dev/null || true
git tag -a "v$NEW_VERSION" -m "GridTimer v$NEW_VERSION ($BUILD_NUMBER)" -m "Official release version of GridTimer v$NEW_VERSION"

# Show the latest commit details
echo ""
echo "=== Latest Commit ==="
git show --stat

# Prompt the user for confirmation
echo ""
read -p "Do you want to push the changes and tag to origin/$CURRENT_BRANCH? (y/n): " choice

if [ "$choice" == "y" ]; then
  git push origin "v$NEW_VERSION" -f
  git push origin "$CURRENT_BRANCH"
  echo ""
  echo "Changes have been pushed to origin/$CURRENT_BRANCH"
  echo "Tag v$NEW_VERSION has been pushed"
else
  echo ""
  echo "Push skipped. To push later, run:"
  echo "  git push origin v$NEW_VERSION"
  echo "  git push origin $CURRENT_BRANCH"
fi

echo ""
echo "=== Release Complete ==="
echo "Version: v$NEW_VERSION ($BUILD_NUMBER)"
echo ""
echo "Next steps:"
echo "  1. Run ./tool/build-release.sh to build the AAB"
echo "  2. Upload to Play Console"
echo "  3. Update CHANGELOG.md if needed"
echo ""
