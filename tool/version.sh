#!/bin/bash

# GridTimer version generation script
# Based on Sanmill's version.sh but simplified for Flutter-only project

PUBSPEC_YAML_FILE=pubspec.yaml
GIT_BRANCH=master

# Define sed command, use gsed on macOS
SED=sed
if [ "$(uname)" == "Darwin" ]; then
	SED=gsed
fi

# Create a file with the sorted git commit hashes
git rev-list HEAD | sort > config.git-hash

# Calculate the number of commits in the repository
LOCALVER="$(wc -l config.git-hash | awk '{print $1}')"

# Get the latest git tag
TAG="$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "v1.0.0")"

# Determine the version string based on the number of commits
if [ "$LOCALVER" -gt "1" ] ; then
	VER=$(git rev-list origin/$GIT_BRANCH | sort | join config.git-hash - | wc -l | awk '{print $1}')
	if [ "$VER" != "$LOCALVER" ] ; then
		VER="$VER+$((LOCALVER-VER))"
	fi
	if git status | grep -q "modified:" ; then
		VER="${VER}M"
	fi
	VER="$VER g$(git rev-list HEAD -n 1 | cut -c 1-7)"
	GIT_VERSION="$TAG r$VER"
	APP_VERSION="${TAG:1}+${LOCALVER}"
else
	DATE=$(date +%Y%m%d)
	if [ -n "$GITHUB_RUN_NUMBER" ] ; then
		VER="$GITHUB_RUN_NUMBER"
		GIT_VERSION="$TAG #$VER"
	else
		VER="${DATE:2}"
		GIT_VERSION="$TAG Build $VER"
	fi
	APP_VERSION="${TAG:1}+${VER}"
fi

# Remove the temporary git-hash file
rm -f config.git-hash

# Print the generated version string
echo "App Version: ${APP_VERSION}"
echo "Git Version: ${GIT_VERSION}"
echo

# Remove the version line from the pubspec.yaml file and insert the new version
$SED -i '/^version:/d' ${PUBSPEC_YAML_FILE}
$SED -i "4i\\version: ${APP_VERSION}" ${PUBSPEC_YAML_FILE}

echo "Updated $PUBSPEC_YAML_FILE"
echo
grep '^version:' ${PUBSPEC_YAML_FILE}

