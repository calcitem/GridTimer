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
- **Debug Mode**: Shows error dialog with details + Console + File + Email handlers
- **Release Mode**: Shows error dialog + File + Email handlers  
- **Profile Mode**: Shows error dialog with details + Console + File + Email handlers
- After accepting the error dialog, the system's email app will open automatically to send the error report

### iOS
- Catcher is **disabled** (App Store restrictions on crash reporting)

### Desktop (Windows/Linux/macOS) & Web
- Uses **SilentReportMode** (no UI shown to user)
- Errors are logged but don't interrupt user experience

## Email Handler Configuration

The `EmailManualHandler` is configured with the following parameters:
- **enableDeviceParameters**: Include device information (model, OS version, etc.)
- **enableStackTrace**: Include full stack trace of the error
- **enableCustomParameters**: Include custom parameters defined in the app
- **enableApplicationParameters**: Include app version and build information
- **sendHtml**: Send email in HTML format for better readability
- **emailTitle**: Subject line of the error report email
- **emailHeader**: Header text shown in the email body

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

1. User sees an error report dialog with details
2. User can choose to:
   - **Accept**: Opens the system's default email app with pre-filled error report
   - **Cancel**: Dismisses the dialog and continues using the app
3. Error is automatically saved to a file for later retrieval
4. If no email app is installed, the system will prompt the user to install one

**Note**: Make sure your device has an email app (Gmail, Outlook, etc.) installed to send error reports.

## Testing

To test catcher functionality:

1. Navigate to **Settings Page** in the app
2. Scroll to the **Debug Tools** section
3. Tap on **"Error Test (Debug)"**
4. This will throw a test exception and trigger Catcher's error reporting UI

Note: The error test button is only visible when Catcher is enabled (EnvironmentConfig.catcher = true)

## Troubleshooting

### Email Dialog Not Appearing

If clicking "Accept" doesn't open an email app:

1. **Check Email App Installation**
   - Ensure an email app (Gmail, Outlook, etc.) is installed on the device
   - Try installing Gmail from Play Store if no email app is available

2. **Check Default Email App**
   - Go to Settings → Apps → Default apps → Email
   - Set a default email application

3. **Check File Logs**
   - Error logs are still saved to file even if email doesn't work
   - Location: `{ExternalStorageDirectory}/GridTimer-crash-logs.txt`
   - Users can manually retrieve and send this file

4. **Alternative on Desktop**
   - Desktop platforms use SilentReportMode
   - Check the crash logs file in the app directory

### Verify Catcher is Working

1. Navigate to Settings → Debug Tools
2. Tap "Error Test (Debug)"
3. You should see a dialog with error details
4. Tap "Accept" to trigger email sending
5. System's email app should open with pre-filled error report

## Notes

- Catcher is only initialized once at app startup
- All uncaught errors and exceptions are automatically captured
- The crash log file persists across app sessions
- Users can manually send crash reports via email at any time
- DialogReportMode is used instead of PageReportMode for better email integration

## Reference

This implementation follows the pattern used in:
- **Sanmill Project**: `D:\Repo\Sanmill\src\ui\flutter_app`

