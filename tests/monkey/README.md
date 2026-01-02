# Monkey Testing for Grid Timer

## Overview

Monkey testing is an automated stress testing technique that generates random UI events (touches, swipes, etc.) to test app stability and find potential crashes.

## Test Environment Setup

Grid Timer must be built with the **test environment** flag to prevent interference with monkey testing:

```bash
flutter build apk --dart-define=test=true
```

### What Does Test Environment Do?

When `test=true`, the following behaviors are **disabled** to keep the monkey test contained within the app:

1. **URL Launching**: All `launchUrl()` calls are blocked (privacy policy links, etc.)
2. **System Settings**: Cannot open system settings pages (notifications, alarms, battery optimization, TTS settings)
3. **App Exit**: Application exit is prevented (reset settings countdown, privacy policy rejection)

These restrictions ensure monkey testing stays within the app and doesn't trigger external activities that would disrupt the test.

## Running Monkey Test

### Start Test

```bash
./tests/monkey/monkey.sh
```

This script:
- Finds the Android SDK platform-tools (works on Windows/macOS/Linux)
- Runs monkey with 10 million random events
- Uses the following event distribution:
  - 50% touch events (taps)
  - 50% motion events (swipes/drags)
  - 0% trackball/navigation/system keys (to avoid leaving the app)
- 500ms throttle between events (allows UI to respond)

### Stop Test

```bash
./tests/monkey/stop-monkey.sh
```

Or press `Ctrl+C` in the terminal running the monkey script.

## Monitoring

While monkey test is running, you can monitor for crashes:

```bash
# Watch logcat for errors
adb logcat | grep -E "(FATAL|AndroidRuntime|Grid Timer)"

# Check if app is still running
adb shell ps | grep gridtimer
```

## Expected Behavior

In test mode:
- Clicking "View Privacy Policy" → No browser opens, logged to console
- Clicking permission setting buttons → No settings open, logged to console
- Triggering app reset countdown → App doesn't exit after countdown
- Privacy policy rejection → App doesn't close, auto-accepts in test mode

## Best Practices

1. **Install fresh build** before each monkey test session
2. **Monitor device** - ensure it doesn't enter sleep mode
3. **Check logcat** for assertion failures or crashes
4. **Run for extended periods** - let it run overnight to catch rare edge cases
5. **Keep device charged** - monkey tests can run for hours

## Troubleshooting

**Monkey test exits immediately:**
- Check that the app package name is correct: `com.calcitem.gridtimer`
- Ensure the app is installed: `adb shell pm list packages | grep gridtimer`

**Permission Error (INJECT_EVENTS):**
If you see `java.lang.SecurityException: Injecting input events requires the caller ... to have the INJECT_EVENTS permission`:
- **Xiaomi/MIUI Devices**: You must enable **USB debugging (Security settings)** / **USB 调试（安全设置）** in Developer Options. This is required to allow ADB to simulate touch events.
- Note: This setting usually requires a SIM card to be inserted and Wi-Fi to be disabled during activation.

**External apps opening:**
- Verify you built with `--dart-define=test=true`
- Check logcat for "blocked in test environment" messages

**Device becomes unresponsive:**
- Reduce event count or increase throttle time in `monkey.sh`
- Stop the test with `./tests/monkey/stop-monkey.sh`

## Platform Notes

### Windows
- Uses `~/AppData/Local/Android/Sdk/platform-tools`
- Git Bash recommended for running shell scripts

### macOS
- Uses `~/Library/Android/sdk/platform-tools`

### Linux
- Uses `~/Android/sdk/platform-tools`

## See Also

- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Development guidelines
- [EnvironmentConfig](../../lib/core/config/environment_config.dart) - Test mode configuration
