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

3. **`android/app/src/main/AndroidManifest.xml`**
   - Added `<queries>` section for email client intent (required for Android 11+)
   - This allows the app to detect and open email clients

## Platform Behavior

### Android
- **Debug Mode**: Shows full error report page with details + Console + File + Email handlers
- **Release Mode**: Shows full error report page + File + Email handlers  
- **Profile Mode**: Shows full error report page with details + Console + File + Email handlers
- Error page displays complete stack trace, device info, and error details
- After clicking "Accept" button, the system's email app will open automatically to send the error report

### iOS
- Catcher is **disabled** (App Store restrictions on crash reporting)

### Desktop (Windows/Linux/macOS) & Web
- Uses **SilentReportMode** (no UI shown to user)
- Errors are logged but don't interrupt user experience

## Report Mode: PageReportMode

Uses `PageReportMode()` which shows a full-page error report with:
- Complete error message
- Full stack trace
- Device information
- Application information
- "Accept" and "Cancel" buttons

This provides maximum information for debugging compared to simple dialog modes.

## Email Handler Configuration

The `EmailManualHandler` is configured with simple parameters:
- **recipientEmails**: List of support email addresses
- **printLogs**: true (enables console logging for debugging)

When error occurs and user accepts:
1. Error details are formatted automatically
2. System's default email client opens
3. Email is pre-filled with error report
4. User can add comments and send

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

1. User sees a full-page error report with:
   - Error message
   - Complete stack trace
   - Device information
   - Accept and Cancel buttons
2. User can choose to:
   - **Accept**: Opens the system's default email app with pre-filled error report
   - **Cancel**: Closes the error page and continues using the app
3. Error is automatically saved to a file for later retrieval
4. If no email app is installed, the system will prompt the user to install one

**Note**: Make sure your device has an email app (Gmail, Outlook, etc.) installed to send error reports.

**Android 11+ Requirement**: The app declares email client query intent in AndroidManifest.xml to enable email functionality.

## Testing

To test catcher functionality:

1. Navigate to **Settings Page** in the app
2. Scroll to the **Debug Tools** section
3. Tap on **"Error Test (Debug)"**
4. This will throw a test exception and trigger Catcher's error reporting UI

Note: The error test button is only visible when Catcher is enabled (EnvironmentConfig.catcher = true)

## Troubleshooting

### Email App Not Opening

If clicking "Accept" doesn't open an email app:

1. **Check Email App Installation**
   - Ensure an email app (Gmail, Outlook, etc.) is installed on the device
   - Try installing Gmail from Play Store if no email app is available

2. **Check Default Email App**
   - Go to Settings → Apps → Default apps → Email
   - Set a default email application

3. **Android 11+ Requirements**
   - The app must declare email client query in AndroidManifest.xml (already added)
   - Reinstall the app if you just added the queries section

4. **Check File Logs**
   - Error logs are still saved to file even if email doesn't work
   - Location: `{ExternalStorageDirectory}/GridTimer-crash-logs.txt`
   - Users can manually retrieve and send this file

5. **Alternative on Desktop**
   - Desktop platforms use SilentReportMode
   - Check the crash logs file in the app directory

### Verify Catcher is Working

1. Navigate to Settings → Debug Tools
2. Tap "Error Test (Debug)"
3. You should see a full error report page with:
   - Error message at the top
   - Complete stack trace
   - Device information
   - Accept and Cancel buttons at the bottom
4. Tap "Accept" to trigger email sending
5. System's email app should open with pre-filled error report

### Still Not Working?

- Try uninstalling and reinstalling the app (to apply AndroidManifest changes)
- Check if other apps can open email clients
- Enable "printLogs: true" in EmailManualHandler to see console output
- Check Android logcat for error messages

## Notes

- Catcher is only initialized once at app startup
- All uncaught errors and exceptions are automatically captured
- The crash log file persists across app sessions
- Users can manually send crash reports via email at any time
- PageReportMode is used to show complete error details including stack trace
- Android 11+ requires `<queries>` declaration in AndroidManifest.xml for email functionality

## Reference

This implementation follows the pattern used in:
- **Sanmill Project**: `D:\Repo\Sanmill\src\ui\flutter_app`

