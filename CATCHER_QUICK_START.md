# Catcher Quick Start Guide

## 🚀 Quick Setup (Already Done)

Catcher 2 has been integrated into GridTimer. Here's what you need to know:

## ⚙️ Configuration (Required)

**Update Support Email:**

Edit `lib/core/config/constants.dart`:

```dart
static const List<String> recipientEmails = <String>[
  "your-support@example.com",  // ⚠️ Change this!
];
```

## 🧪 Test It Works

1. Run the app: `flutter run`
2. Go to **Settings** → **Debug Tools**
3. Tap **"Error Test (Debug)"**
4. You should see an error dialog
5. Tap **"Accept"**
6. Email app should open with error report

## 📱 Requirements

- **Android**: 
  - Email app must be installed (Gmail, Outlook, etc.)
  - Android 11+ requires queries declaration (already added)
  - May need to reinstall app after adding queries
- **iOS**: Catcher is disabled
- **Desktop**: Logs errors silently (no UI)

## 🔧 Build Options

```bash
# Normal build (catcher enabled)
flutter run

# Disable catcher
flutter run --dart-define=catcher=false

# Release build
flutter build apk
```

## 📊 What Happens When Error Occurs

### On Android:
1. Full error report page appears showing:
   - Error message
   - Complete stack trace
   - Device information
   - Accept and Cancel buttons
2. User taps "Accept"
3. Email app opens with:
   - Pre-filled recipient
   - Full error details
   - Device information
   - Complete stack trace
4. User can add comments and send

### Error Logs Location:
- Android: `/storage/emulated/0/Android/data/com.example.grid_timer/files/GridTimer-crash-logs.txt`
- Desktop: `./GridTimer-crash-logs.txt`

## 🐛 Troubleshooting

**Email doesn't open?**
- Install an email app (Gmail recommended)
- Set default email app in system settings
- **Reinstall the app** (AndroidManifest changes require reinstall)
- Logs are still saved to file

**Error page shows simple dialog instead of full details?**
- Make sure using `PageReportMode()` not `DialogReportMode()`
- Check lib/core/services/catcher_service.dart

**Want to disable catcher?**
```bash
flutter run --dart-define=catcher=false
```

## 📚 More Information

See `CATCHER_INTEGRATION.md` for complete documentation.

## ✅ Integration Status

- ✅ Catcher 2 installed
- ✅ Configuration complete (PageReportMode)
- ✅ Email handler configured
- ✅ Android queries for email added
- ✅ Test button added to Settings
- ✅ All platforms supported
- ⚠️ **Action Required**: Update support email in constants.dart
- ⚠️ **Note**: Reinstall app to apply AndroidManifest changes

