#!/bin/bash

# GridTimer Flutter version setup script
# This script automatically downloads and configures Flutter SDK with Dart 3.8.0+

set -e

# Define Flutter version (using version with Dart 3.8+)
FLUTTER_VERSION="3.38.5"
FLUTTER_CHANNEL="stable"

echo "=== Flutter Version Setup ==="
echo "Target version: Flutter ${FLUTTER_VERSION}"
echo ""

# Detect operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    FLUTTER_TAR="flutter_${OS}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    FLUTTER_TAR="flutter_${OS}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.zip"
else
    echo "Error: Unsupported operating system $OSTYPE"
    exit 1
fi

echo "Detected operating system: ${OS}"

# Set download path
FLUTTER_HOME="${HOME}/flutter-${FLUTTER_VERSION}"
DOWNLOAD_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/${OS}/${FLUTTER_TAR}"

# Check if already downloaded
if [ -d "${FLUTTER_HOME}" ]; then
    echo "Flutter ${FLUTTER_VERSION} already exists at ${FLUTTER_HOME}"
else
    echo "Downloading Flutter ${FLUTTER_VERSION}..."
    echo "Download URL: ${DOWNLOAD_URL}"
    
    # Download Flutter SDK
    if [[ "$OS" == "linux" ]]; then
        wget -q --show-progress "${DOWNLOAD_URL}" -O "/tmp/${FLUTTER_TAR}"
        echo "Extracting Flutter SDK..."
        tar -xf "/tmp/${FLUTTER_TAR}" -C "${HOME}"
        mv "${HOME}/flutter" "${FLUTTER_HOME}"
        rm "/tmp/${FLUTTER_TAR}"
    else
        curl -L "${DOWNLOAD_URL}" -o "/tmp/${FLUTTER_TAR}"
        echo "Extracting Flutter SDK..."
        unzip -q "/tmp/${FLUTTER_TAR}" -d "${HOME}"
        mv "${HOME}/flutter" "${FLUTTER_HOME}"
        rm "/tmp/${FLUTTER_TAR}"
    fi
    
    echo "Flutter SDK downloaded and extracted to ${FLUTTER_HOME}"
fi

# Export Flutter to PATH
export PATH="${FLUTTER_HOME}/bin:${PATH}"

# Verify Flutter version
echo ""
echo "Verifying Flutter installation..."
flutter --version

echo ""
echo "Verifying Dart version..."
dart --version

echo ""
echo "=== Flutter Version Setup Complete ==="
echo ""
echo "Tip: To use this Flutter version in the current session, run:"
echo "  export PATH=${FLUTTER_HOME}/bin:\$PATH"
echo ""
