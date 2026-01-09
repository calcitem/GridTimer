#!/bin/bash
# Fast Windows Build Script for Grid Timer (Git Bash version)
# This script uses optimized settings for faster incremental builds

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Default values
BUILD_MODE="debug"
CLEAN_BUILD=0
VERBOSE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_MODE="release"
            shift
            ;;
        --profile)
            BUILD_MODE="profile"
            shift
            ;;
        --clean)
            CLEAN_BUILD=1
            shift
            ;;
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --help|-h)
            echo "Usage: fast-build.sh [options]"
            echo ""
            echo "Options:"
            echo "  --debug    Build in debug mode (default)"
            echo "  --release  Build in release mode"
            echo "  --profile  Build in profile mode"
            echo "  --clean    Clean build (removes build cache)"
            echo "  --verbose  Show verbose output"
            echo "  --help     Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./fast-build.sh                    # Debug incremental build"
            echo "  ./fast-build.sh --release          # Release incremental build"
            echo "  ./fast-build.sh --clean --debug    # Clean debug build"
            echo ""
            echo "Tips for faster builds:"
            echo "  1. Run setup-defender-exclusions.ps1 as admin"
            echo "  2. Use SSD for project and Flutter SDK"
            echo "  3. Close unnecessary applications"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo ""
echo "========================================"
echo "  Grid Timer Fast Build"
echo "  Mode: $BUILD_MODE"
echo "  Clean: $CLEAN_BUILD"
echo "========================================"
echo ""

# Clean build if requested
if [[ $CLEAN_BUILD -eq 1 ]]; then
    echo "[1/3] Cleaning build directory..."
    rm -rf "build/windows" 2>/dev/null || true
    rm -rf ".dart_tool/flutter_build" 2>/dev/null || true
else
    echo "[1/3] Skipping clean (incremental build)"
fi

# Set environment for faster builds
echo "[2/3] Setting up build environment..."

# Check if shaders are cached
if [[ -d "build/flutter_assets/shaders" ]]; then
    echo "       - Shader cache found, will use cached shaders"
fi

# Run flutter build
echo "[3/3] Running Flutter build..."
echo ""

BUILD_CMD="flutter build windows --$BUILD_MODE"

if [[ $VERBOSE -eq 1 ]]; then
    BUILD_CMD="$BUILD_CMD -v"
fi

# Measure build time
START_TIME=$(date +%s)

$BUILD_CMD

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "[DONE] Build completed in ${ELAPSED}s"
echo "       Output: build/windows/x64/runner/$BUILD_MODE/grid_timer.exe"
echo ""
