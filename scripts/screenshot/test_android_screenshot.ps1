# test_android_screenshot.ps1
#
# Automated screenshot capture script for Grid Timer app on Android.
# This script iterates through all supported locales, runs integration tests
# to capture localized screenshots, and pulls them to the local machine.
#
# Usage:
#   .\test_android_screenshot.ps1
#
# Prerequisites:
#   - Android device connected with USB debugging enabled
#   - Flutter SDK installed and in PATH
#   - ADB installed and in PATH

# --- Configuration ---
# Set to $true to use the full list of locales, $false for the short list
$useFullLocaleList = $true

# Short list for quick testing
$localesToTestShort = @(
    "en",
    "de",
    "zh"
)

# Full list of locales supported by Grid Timer
# These match the ARB files in lib/l10n/arb/
$localesToTestFull = @(
    "ar",       # Arabic
    "bn",       # Bengali
    "de",       # German
    "en",       # English
    "es",       # Spanish
    "fr",       # French
    "hi",       # Hindi
    "id",       # Indonesian
    "it",       # Italian
    "ja",       # Japanese
    "ko",       # Korean
    "pt",       # Portuguese
    "pt_BR",    # Portuguese (Brazil)
    "ru",       # Russian
    "th",       # Thai
    "tr",       # Turkish
    "vi",       # Vietnamese
    "zh",       # Simplified Chinese
    "zh_Hant"   # Traditional Chinese
)

# Select which list to use based on the flag
if ($useFullLocaleList) {
    $localesToTest = $localesToTestFull
    Write-Host "Using FULL locale list ($($localesToTest.Count) locales)." -ForegroundColor Yellow
} else {
    $localesToTest = $localesToTestShort
    Write-Host "Using SHORT locale list ($($localesToTest.Count) locales). Set `$useFullLocaleList = `$true for full run." -ForegroundColor Yellow
}

# Timeout settings
$psTimeoutSeconds = 360  # PowerShell job timeout
$flutterTestTimeout = "5m"  # Flutter test internal timeout

# ---------------------------------------------------------
# Define relative paths (script is in scripts/screenshot/)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Join-Path $scriptDir "..\.."
$buildGradlePath = Join-Path $projectRoot "android\app\build.gradle"
$integrationTestPath = Join-Path $projectRoot "integration_test\localization_screenshot_test.dart"
# ---------------------------------------------------------

# Change to project root directory
Push-Location $projectRoot

Write-Host "Project root: $(Get-Location)" -ForegroundColor Cyan
Write-Host "Integration test: $integrationTestPath" -ForegroundColor Cyan

# Check if integration test file exists
if (-not (Test-Path $integrationTestPath)) {
    Write-Host "ERROR: Integration test file not found at: $integrationTestPath" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Check for connected Android devices
Write-Host "Checking for connected Android devices..." -ForegroundColor Cyan
$devices = (& adb devices) | Where-Object { $_ -match "device$" }

if ($devices.Count -eq 0) {
    Write-Host "ERROR: No connected Android devices found. Please ensure your device is connected and USB debugging is enabled." -ForegroundColor Red
    Pop-Location
    exit 1
} elseif ($devices.Count -gt 1) {
    Write-Host "WARNING: Multiple devices found. Please connect only one device or specify with -s." -ForegroundColor Yellow
    & adb devices
    $continue = Read-Host "Continue? (y/n)"
    if ($continue -ne "y") {
        Pop-Location
        exit 1
    }
}

# Attempt to read package name from android/app/build.gradle
if (Test-Path $buildGradlePath) {
    $packageNameLine = Get-Content -Path $buildGradlePath | Where-Object { $_ -match "applicationId" }
    if ($packageNameLine) {
        $packageName = $packageNameLine -replace '.*applicationId\s+"([^"]+)".*', '$1'
    } else {
        Write-Host "No applicationId found in build.gradle. Using default package name." -ForegroundColor Yellow
        $packageName = "com.calcitem.gridtimer"
    }
} else {
    Write-Host "Cannot find build.gradle at path: $buildGradlePath" -ForegroundColor Red
    Write-Host "Using default package name: com.calcitem.gridtimer" -ForegroundColor Yellow
    $packageName = "com.calcitem.gridtimer"
}

Write-Host "Using package name: $packageName" -ForegroundColor Cyan

# Define screenshot directory on device
$targetDir = "/storage/emulated/0/Pictures/GridTimer"
Write-Host "Target screenshot directory on device: $targetDir" -ForegroundColor Cyan

# Clean up old screenshots on device
Write-Host "Cleaning up old screenshots on device ($targetDir)..." -ForegroundColor Cyan
& adb shell "rm -rf $targetDir/*"

# Ensure directory on device
Write-Host "Ensuring screenshot directory exists on device..." -ForegroundColor Cyan
& adb shell "mkdir -p $targetDir"

# Define the local base directory for screenshots
$localBaseDir = "screenshots"

# Ensure the local base directory exists, DO NOT clean it up
Write-Host "Ensuring local base directory exists: $localBaseDir" -ForegroundColor Cyan
if (-not (Test-Path -Path $localBaseDir)) {
    New-Item -Path $localBaseDir -ItemType Directory | Out-Null
}

# ---------------------------------------------------------
# Build and install the app with proper permissions
# ---------------------------------------------------------
Write-Host "`nBuilding debug APK..." -ForegroundColor Cyan
& flutter build apk --debug

Write-Host "`nInstalling app from Flutter project directory..." -ForegroundColor Cyan
& flutter install --debug

# Lists to track success/failure
$failedLocalesPS = [System.Collections.Generic.List[string]]::new()
$successfulLocalesPS = [System.Collections.Generic.List[string]]::new()

# Track pulled screenshots
$localeCountsPulled = @{}
$totalPulled = 0

Write-Host "`nStarting screenshot tests and pulling for specified locales..." -ForegroundColor Cyan
foreach ($locale in $localesToTest) {
    Write-Host "--------------------------------------------------" -ForegroundColor Magenta
    Write-Host "Checking for locale: $locale" -ForegroundColor Magenta
    Write-Host "--------------------------------------------------"

    $localLocaleDir = Join-Path $localBaseDir $locale
    if (Test-Path -Path $localLocaleDir) {
        Write-Host "Skipping $locale - Directory already exists: $localLocaleDir" -ForegroundColor Yellow
        $successfulLocalesPS.Add($locale) # Treat as success or add to a skipped list
        continue
    }

    Write-Host "Running test for locale: $locale (Timeout: $flutterTestTimeout)" -ForegroundColor Magenta

    # Run flutter test with the specified locale
    $testCommandLog = "flutter test integration_test/localization_screenshot_test.dart --dart-define=TEST_LOCALE=$locale --timeout $flutterTestTimeout --no-pub --reporter=compact"
    Write-Host "Executing: $testCommandLog" -ForegroundColor Yellow

    flutter test `
        "integration_test/localization_screenshot_test.dart" `
        --dart-define="TEST_LOCALE=$locale" `
        --timeout $flutterTestTimeout `
        --no-pub `
        --reporter=compact

    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "SUCCESS: Test for locale $locale completed successfully." -ForegroundColor Green
        $successfulLocalesPS.Add($locale)
    } else {
        Write-Host "FAILURE: Test for locale $locale failed (Exit Code: $exitCode). Check logs above." -ForegroundColor Red
        $failedLocalesPS.Add($locale)
        Write-Host "Attempting to pull any generated screenshots for $locale despite test failure..." -ForegroundColor Yellow
    }

    # Pull screenshots for this locale
    Write-Host "Searching for screenshots matching '$locale*.png' in $targetDir on device..." -ForegroundColor Cyan
    $paths = & adb shell "find $targetDir -name '${locale}_*.png' 2>/dev/null || echo ''"
    $localePaths = $paths | Where-Object { $_ -ne "" -and $_ -ne "Not found" }

    if ($localePaths.Count -eq 0) {
        Write-Host "No screenshots found matching '$locale*.png' for this locale run." -ForegroundColor Yellow
    } else {
        Write-Host "Found $($localePaths.Count) screenshots for $locale! Pulling files..." -ForegroundColor Green
        $localLocaleDir = Join-Path $localBaseDir $locale

        if (-not (Test-Path -Path $localLocaleDir)) {
            Write-Host "Creating local directory: $localLocaleDir" -ForegroundColor Cyan
            New-Item -Path $localLocaleDir -ItemType Directory | Out-Null
        }

        $localePulledCount = 0
        foreach ($path in $localePaths) {
            $cleanPath = $path.Trim()
            if ($cleanPath) {
                Write-Host "Pulling: $cleanPath to $localLocaleDir" -ForegroundColor Green
                & adb pull "$cleanPath" $localLocaleDir
                $localePulledCount++
                $totalPulled++
            }
        }

        if ($localeCountsPulled.ContainsKey($locale)) {
            $localeCountsPulled[$locale] += $localePulledCount
        } else {
            $localeCountsPulled[$locale] = $localePulledCount
        }

        Write-Host "Pulled $localePulledCount screenshots for $locale." -ForegroundColor Green
    }
}

Write-Host "--------------------------------------------------" -ForegroundColor Magenta
Write-Host "All locale test runs and pulls completed." -ForegroundColor Magenta
Write-Host "--------------------------------------------------"

# Generate the final log file
Write-Host "Generating final log file..." -ForegroundColor Cyan
$logContent = @()
$logContent += "Screenshot Generation Summary:"
$logContent += "=============================="
$logContent += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$logContent += ""
$logContent += "Tested Locales:"
$logContent += "------------------------------"

foreach ($locale in $localesToTest) {
    $status = if ($failedLocalesPS.Contains($locale)) { "FAILED" } else { "SUCCESS" }
    $pulledCount = if ($localeCountsPulled.ContainsKey($locale)) { $localeCountsPulled[$locale] } else { 0 }
    $logContent += "Locale: $locale - Test Status: $status - Screenshots Pulled: $pulledCount"
}

$logContent += "=============================="
$logContent += "Summary:"
$logContent += "------------------------------"
$logContent += "Successful Locales: $($successfulLocalesPS.Count) ($($successfulLocalesPS -join ', '))"
$logContent += "Failed Locales    : $($failedLocalesPS.Count) ($($failedLocalesPS -join ', '))"
$logContent += "Total Screenshots Pulled: $totalPulled"

$logFilePath = Join-Path $localBaseDir "log.txt"
$logContent | Out-File -FilePath $logFilePath -Encoding utf8

Write-Host "Log file created at $logFilePath" -ForegroundColor Green
Write-Host "DONE! Screenshots are saved in locale-specific subfolders within '$localBaseDir'." -ForegroundColor Green
Write-Host "Summary logged to '$logFilePath'." -ForegroundColor Green

# Return to original directory
Pop-Location

# Optional: Exit with non-zero code if any locale failed
if ($failedLocalesPS.Count -gt 0) {
    Write-Host "Exiting with error code because some locales failed." -ForegroundColor Red
    exit 1
} else {
    exit 0
}
