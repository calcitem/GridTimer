#!/bin/bash

# test_android_screenshot.sh
#
# Automated screenshot capture script for Grid Timer app on Android.
# This script iterates through all supported locales, runs integration tests
# to capture localized screenshots, and pulls them to the local machine.
#
# Usage:
#   ./test_android_screenshot.sh
#
# Prerequisites:
#   - Android device connected with USB debugging enabled
#   - Flutter SDK installed and in PATH
#   - ADB installed and in PATH

# --- Configuration ---

# Set to true to use the full list of locales, false for the short list
use_full_locale_list=true

# Short list for quick testing
locales_to_test_short=(
    "en"
    "de"
    "zh"
)

# Full list of locales supported by Grid Timer
# These match the ARB files in lib/l10n/arb/
locales_to_test_full=(
    "ar"        # Arabic
    "bn"        # Bengali
    "de"        # German
    "en"        # English
    "es"        # Spanish
    "fr"        # French
    "hi"        # Hindi
    "id"        # Indonesian
    "it"        # Italian
    "ja"        # Japanese
    "ko"        # Korean
    "pt"        # Portuguese
    "pt_BR"     # Portuguese (Brazil)
    "ru"        # Russian
    "th"        # Thai
    "tr"        # Turkish
    "vi"        # Vietnamese
    "zh"        # Simplified Chinese
    "zh_Hant"   # Traditional Chinese
)

# Select which list to use based on the flag
if [ "$use_full_locale_list" = true ]; then
    locales_to_test=("${locales_to_test_full[@]}")
    echo -e "\033[1;33mUsing FULL locale list (${#locales_to_test_full[@]} locales).\033[0m"
else
    locales_to_test=("${locales_to_test_short[@]}")
    echo -e "\033[1;33mUsing SHORT locale list (${#locales_to_test_short[@]} locales). Set use_full_locale_list=true for full run.\033[0m"
fi

# Timeout for flutter test itself
flutter_test_timeout="5m"

# ---------------------

# ANSI color codes for output
COLOR_CYAN='\033[1;36m'
COLOR_RED='\033[1;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_GREEN='\033[1;32m'
COLOR_MAGENTA='\033[1;35m'
COLOR_NC='\033[0m' # No Color

# Function for colored output
cecho() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${COLOR_NC}"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root directory
cd "$PROJECT_ROOT" || exit 1

cecho "$COLOR_CYAN" "Project root: $(pwd)"
cecho "$COLOR_CYAN" "Integration test: integration_test/localization_screenshot_test.dart"

# Check if integration test file exists
if [ ! -f "integration_test/localization_screenshot_test.dart" ]; then
    cecho "$COLOR_RED" "ERROR: Integration test file not found!"
    exit 1
fi

# Check for connected Android devices
cecho "$COLOR_CYAN" "Checking for connected Android devices..."
# Get device list, filter for actual devices (excluding header/emulator lines if possible)
devices_output=$(adb devices | grep -w 'device$' | grep -v 'List of devices attached')
device_count=$(echo "$devices_output" | wc -l | tr -d ' ')

if [ "$device_count" -eq 0 ]; then
    cecho "$COLOR_RED" "ERROR: No connected Android devices found. Please ensure your device is connected and USB debugging is enabled."
    exit 1
elif [ "$device_count" -gt 1 ]; then
    cecho "$COLOR_YELLOW" "WARNING: Multiple devices found. Please connect only one device or use -s to specify."
    adb devices
    read -p "Continue? (y/n): " continue_response
    continue_response_lower=$(echo "$continue_response" | tr '[:upper:]' '[:lower:]')
    if [[ "$continue_response_lower" != "y" ]]; then
        exit 1
    fi
fi

# Attempt to read package name from app/build.gradle
package_name_line=$(grep 'applicationId ' android/app/build.gradle 2>/dev/null || true)
if [[ -n "$package_name_line" ]]; then
    package_name=$(echo "$package_name_line" | sed -n 's/.*applicationId\s*"\([^"]*\)".*/\1/p')
else
    package_name=""
fi

# If package name couldn't be extracted, use default
if [ -z "$package_name" ]; then
    package_name="com.calcitem.gridtimer"
    cecho "$COLOR_YELLOW" "Could not parse package name, using default: $package_name"
else
    cecho "$COLOR_CYAN" "Detected package name: $package_name"
fi

# Define the target screenshot directory on device
target_dir="/storage/emulated/0/Pictures/GridTimer"
cecho "$COLOR_CYAN" "Target screenshot directory on device: $target_dir"

# Clean up old screenshots *on device* only once at the beginning
cecho "$COLOR_CYAN" "Cleaning up old screenshots on device ($target_dir)..."
adb shell "rm -rf \"$target_dir\"/*" 2>/dev/null || cecho "$COLOR_YELLOW" "Warning: Failed to remove contents of $target_dir (maybe it didn't exist yet)."

# Create the directory on device if it doesn't exist
cecho "$COLOR_CYAN" "Ensuring screenshot directory exists on device..."
adb shell "mkdir -p \"$target_dir\""

# Define the local base directory for screenshots
local_base_dir="screenshots"

# Ensure the local base directory exists, DO NOT clean it up
cecho "$COLOR_CYAN" "Ensuring local base directory exists: $local_base_dir"
if [ ! -d "$local_base_dir" ]; then
    mkdir -p "$local_base_dir"
fi

# Build and install package before running tests
cecho "$COLOR_CYAN" "Building debug APK..."
flutter build apk --debug

cecho "$COLOR_CYAN" "Installing app with proper permissions..."
flutter install --debug

# Arrays to keep track of failed and successful locales
failed_locales=()
successful_locales=()
# Associative array to store cumulative screenshot counts per locale (pulled files)
# Requires Bash 4.0+
declare -A locale_counts_pulled
total_pulled=0

# --- Loop through locales, run test, and pull screenshots ---
cecho "$COLOR_CYAN" "Starting screenshot tests and pulling for specified locales..."

for locale in "${locales_to_test[@]}"; do
    cecho "$COLOR_MAGENTA" "--------------------------------------------------"
    cecho "$COLOR_MAGENTA" "Running test for locale: $locale (Timeout: $flutter_test_timeout)"
    cecho "$COLOR_MAGENTA" "--------------------------------------------------"

    # Construct the command string for logging
    test_command_log="flutter test integration_test/localization_screenshot_test.dart --dart-define=TEST_LOCALE=$locale --timeout $flutter_test_timeout --no-pub --reporter=compact"
    cecho "$COLOR_YELLOW" "Executing: $test_command_log"

    # Run integration test for the single locale using --dart-define
    flutter test integration_test/localization_screenshot_test.dart --dart-define=TEST_LOCALE="$locale" --timeout "$flutter_test_timeout" --no-pub --reporter=compact
    exit_code=$?

    # Check the exit code of the flutter test command
    if [ $exit_code -eq 0 ]; then
        cecho "$COLOR_GREEN" "SUCCESS: Test for locale $locale completed successfully."
        successful_locales+=("$locale")
    else
        cecho "$COLOR_RED" "FAILURE: Test for locale $locale failed (Exit Code: $exit_code). Check logs above. May have timed out."
        failed_locales+=("$locale")
        cecho "$COLOR_YELLOW" "Attempting to pull any generated screenshots for $locale despite test failure..."
    fi

    # --- Pull screenshots SPECIFICALLY for this locale ---
    cecho "$COLOR_CYAN" "Searching for screenshots matching '${locale}_*.png' in $target_dir on device..."
    paths_str=$(adb shell "find \"$target_dir\" -name '${locale}_*.png' 2>/dev/null") || paths_str=""

    # Check if any paths were found
    if [ -z "$paths_str" ]; then
        cecho "$COLOR_YELLOW" "No screenshots found matching '${locale}_*.png' for this locale run."
        locale_counts_pulled["$locale"]=${locale_counts_pulled["$locale"]:-0}
    else
        # Convert the string list (one path per line) into a Bash array
        readarray -t locale_paths <<< "$paths_str"

        cecho "$COLOR_GREEN" "Found ${#locale_paths[@]} screenshots for $locale! Pulling files..."

        # Define the local target directory for this locale
        local_locale_dir="$local_base_dir/$locale"

        # Create the local locale directory if it doesn't exist
        if [ ! -d "$local_locale_dir" ]; then
            cecho "$COLOR_CYAN" "Creating local directory: $local_locale_dir"
            mkdir -p "$local_locale_dir"
        fi

        # Pull the found files
        locale_pulled_count=0
        for path in "${locale_paths[@]}"; do
            # Trim potential whitespace (like carriage returns from adb shell on some systems)
            path_trimmed=$(echo "$path" | tr -d '\r')
            if [ -n "$path_trimmed" ]; then
                cecho "$COLOR_GREEN" "Pulling: $path_trimmed to $local_locale_dir"
                adb pull "$path_trimmed" "$local_locale_dir"
                pull_exit_code=$?
                if [ $pull_exit_code -eq 0 ]; then
                    locale_pulled_count=$((locale_pulled_count + 1))
                    total_pulled=$((total_pulled + 1))
                else
                    cecho "$COLOR_RED" "Error pulling file: $path_trimmed (Exit code: $pull_exit_code)"
                fi
            fi
        done

        # Update the cumulative count for this locale using associative array
        locale_counts_pulled["$locale"]=$(( ${locale_counts_pulled["$locale"]:-0} + locale_pulled_count ))
        cecho "$COLOR_GREEN" "Pulled $locale_pulled_count screenshots for $locale."
    fi
done

cecho "$COLOR_MAGENTA" "--------------------------------------------------"
cecho "$COLOR_MAGENTA" "All locale test runs and pulls completed."
cecho "$COLOR_MAGENTA" "--------------------------------------------------"

# --- Generate the final log file content ---
cecho "$COLOR_CYAN" "Generating final log file..."
log_file_path="$local_base_dir/log.txt"
# Clear the log file if it exists
> "$log_file_path"

# Function to check if an element exists in an array
containsElement () {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

# Write header to log file
{
    echo "Screenshot Generation Summary:"
    echo "=============================="
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "Tested Locales:"
    echo "------------------------------"
} >> "$log_file_path"

# Write locale results
for locale in "${locales_to_test[@]}"; do
    status="SUCCESS"
    if containsElement "$locale" "${failed_locales[@]}"; then
        status="FAILED"
    fi
    pulled_count=${locale_counts_pulled["$locale"]:-0}
    echo "Locale: $locale - Test Status: $status - Screenshots Pulled: $pulled_count" >> "$log_file_path"
done

# Join array elements into comma-separated strings for the log
successful_locales_str=$(IFS=, ; echo "${successful_locales[*]}")
failed_locales_str=$(IFS=, ; echo "${failed_locales[*]}")
[[ -z "$successful_locales_str" ]] && successful_locales_str="None"
[[ -z "$failed_locales_str" ]] && failed_locales_str="None"

# Write summary to log file
{
    echo "=============================="
    echo "Summary:"
    echo "------------------------------"
    echo "Successful Locales: ${#successful_locales[@]} ($successful_locales_str)"
    echo "Failed Locales    : ${#failed_locales[@]} ($failed_locales_str)"
    echo "Total Screenshots Pulled: $total_pulled"
} >> "$log_file_path"

cecho "$COLOR_GREEN" "Log file created at $log_file_path"

cecho "$COLOR_GREEN" "DONE! Screenshots are saved in locale-specific subfolders within $local_base_dir."
cecho "$COLOR_GREEN" "Summary logged to $log_file_path"

# Exit with non-zero code if any locale failed
if [ ${#failed_locales[@]} -gt 0 ]; then
    cecho "$COLOR_RED" "Exiting with error code because some locales failed."
    exit 1
else
    exit 0
fi
