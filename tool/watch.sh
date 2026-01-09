#!/bin/bash

# Start build_runner in watch mode for incremental code generation
# This is more efficient than running `gen.sh` repeatedly during development
#
# Usage: ./tool/watch.sh

set -e

echo "=== Starting build_runner watch mode ==="
echo "Press Ctrl+C to stop"
echo ""

dart run build_runner watch --delete-conflicting-outputs
