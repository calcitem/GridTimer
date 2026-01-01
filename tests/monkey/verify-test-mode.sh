#!/bin/bash

# Verify that test mode is active in the installed app
# This script checks logcat for the test environment flag

echo "Verifying test mode is active..."
echo "This will clear logcat and restart the app to check for test mode logs."
echo ""

# Get package name
PACKAGE="com.calcitem.gridtimer"

# Clear logcat
adb logcat -c

# Force stop app
adb shell am force-stop $PACKAGE

# Start app
adb shell monkey -p $PACKAGE -c android.intent.category.LAUNCHER 1

# Wait a bit for app to start
sleep 2

# Check logcat for test environment flag
echo "Checking logcat for test environment status..."
echo ""

TEST_LOG=$(adb logcat -d | grep "Environment \[test\]")

if [ -z "$TEST_LOG" ]; then
    echo "❌ ERROR: Could not find test environment log."
    echo "   Make sure the app is built with --dart-define=test=true"
    exit 1
fi

echo "$TEST_LOG"

if echo "$TEST_LOG" | grep -q "test\]: true"; then
    echo ""
    echo "✅ SUCCESS: Test mode is ACTIVE"
    echo "   The app is ready for Monkey testing."
    echo "   All URL launches and system settings will be blocked."
elif echo "$TEST_LOG" | grep -q "test\]: false"; then
    echo ""
    echo "❌ WARNING: Test mode is INACTIVE"
    echo "   The app was NOT built with --dart-define=test=true"
    echo "   Please rebuild using: ./tests/monkey/build-test-apk.sh"
    exit 1
else
    echo ""
    echo "⚠️  UNKNOWN: Could not determine test mode status"
    echo "   Please check the log above manually."
fi
