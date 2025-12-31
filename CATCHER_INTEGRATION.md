# Catcher Integration

This document describes the integration of Catcher 2 error tracking into the GridTimer app, following the implementation pattern from the Sanmill project.

## Overview

Catcher 2 is an error tracking library that catches and reports crashes and exceptions in Flutter applications. It helps users send detailed error reports to developers.

## Features

- **Automatic Error Catching**: Catches uncaught errors and exceptions
- **Multiple Report Handlers**: Console, File, and Email handlers
- **Platform Support**: Enabled on Android, disabled on iOS (due to App Store restrictions), desktop platforms use silent mode
- **Multiple Build Modes**: Different configurations for debug, release, and profile builds

## Files Added/Modified

### New Files

1. **`lib/core/config/environment_config.dart`**
   - Defines compile-time environment configuration
   - Controls whether catcher is enabled (default: true)
   - Can be overridden with: `flutter run --dart-define=catcher=false`

2. **`lib/core/config/constants.dart`**
   - Defines app constants including:
     - Crash log file name
     - Recipient emails for error reports

3. **`lib/core/services/catcher_service.dart`**
   - Initializes Catcher with platform-specific configurations
   - Sets up report handlers (Console, File, Email)
   - Defines behavior for debug, release, and profile modes

### Modified Files

1. **`pubspec.yaml`**
   - Added `catcher_2: 2.1.5`
   - Added `flutter_email_sender: 8.0.0`

2. **`lib/main.dart`**
   - Added necessary imports
   - Integrated catcher initialization in main()
   - Set up PlatformDispatcher error handler
   - Added Catcher2.navigatorKey to MaterialApp

## Platform Behavior

### Android
- **Debug Mode**: Shows error page with details + Console + File + Email handlers
- **Release Mode**: Shows error page + File + Email handlers
- **Profile Mode**: Shows error page with details + Console + File + Email handlers

### iOS
- Catcher is **disabled** (App Store restrictions on crash reporting)

### Desktop (Windows/Linux/macOS) & Web
- Uses **SilentReportMode** (no UI shown to user)
- Errors are logged but don't interrupt user experience

## Configuration

### Email Recipients

Update the email address in `lib/core/config/constants.dart`:

```dart
static const List<String> recipientEmails = <String>[
  "your-support@example.com",  // Change this!
];
```

### Crash Log Location

On Android, crash logs are saved to:
- `{ExternalStorageDirectory}/GridTimer-crash-logs.txt`

On other platforms:
- Current directory (`./GridTimer-crash-logs.txt`)

## Build Options

### Enable/Disable Catcher

```bash
# Enable catcher (default)
flutter run

# Disable catcher
flutter run --dart-define=catcher=false

# Build release with catcher enabled
flutter build apk --dart-define=catcher=true
```

### Dev Mode

```bash
# Enable dev mode (shows debug banner)
flutter run --dart-define=dev_mode=true
```

### Test Mode

```bash
# Enable test mode
flutter run --dart-define=test=true
```

## User Experience

When an error occurs on Android:

1. User sees an error report page with details
2. User can choose to:
   - Send error report via email
   - Close the dialog and continue using the app
3. Error is automatically saved to a file for later retrieval

## Testing

To test catcher functionality:

1. Navigate to **Settings Page** in the app
2. Scroll to the **Debug Tools** section
3. Tap on **"Error Test (Debug)"**
4. This will throw a test exception and trigger Catcher's error reporting UI

Note: The error test button is only visible when Catcher is enabled (EnvironmentConfig.catcher = true)

## Notes

- Catcher is only initialized once at app startup
- All uncaught errors and exceptions are automatically captured
- The crash log file persists across app sessions
- Users can manually send crash reports via email at any time

## Reference

This implementation follows the pattern used in:
- **Sanmill Project**: `D:\Repo\Sanmill\src\ui\flutter_app`

