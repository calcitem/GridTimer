# GridTimer

A 9-grid parallel timer app optimized for seniors with reliable alarm system and minimalist UI.

## Features

- ✅ **9-Grid Parallel Timers**: Run multiple timers simultaneously without interference
- ✅ **Multi-Mode Support**: Save multiple grid configurations and switch between them quickly
- ✅ **Reliable Alerts**: Precise alarms + full-screen notifications that work even on lock screen
- ✅ **Voice Announcements**: Supports Chinese and English TTS voice alerts
- ✅ **State Persistence**: Automatically restores timer state after app is killed or device restarts
- ✅ **Accidental Touch Prevention**: All critical operations require confirmation
- ✅ **Large Fonts**: Clearly visible from 1 meter away
- ✅ **Bilingual Support**: Simplified Chinese + English

## Requirements

- **Flutter SDK**: 3.8.0 or higher
- **Dart SDK**: 3.8.0 or higher
- **Android**: Minimum version determined by Flutter SDK
- **Target SDK**: Android 15 (API 36)
- **Recommended**: Android 13+ for full feature experience (notification permissions, exact alarms)

## Quick Start

### Environment Setup

```bash
# 1. Clone repository
git clone <repository-url>
cd GridTimer

# 2. Install dependencies
flutter pub get

# 3. Generate code (Hive, Freezed, Internationalization)
./tool/gen.sh

# 4. Run application
flutter run
```

### Build Release Version

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release
```

## Project Structure

```
lib/
├── app/              # Application configuration, state management and providers
├── core/             # Core layer
│   ├── config/       # Application configuration and constants
│   ├── domain/       # Domain layer (entities, service interfaces, enums)
│   └── services/     # Core services (error handling, etc.)
├── data/             # Data layer (Hive models and repositories)
├── infrastructure/   # Infrastructure layer (service implementations: notifications, audio, TTS)
├── presentation/     # Presentation layer (pages, dialogs, widgets)
└── l10n/             # Internationalization files (ARB)
```

## Tech Stack

- **Framework**: Flutter 3.8+
- **State Management**: Riverpod
- **Local Storage**: Hive CE
- **Notification System**: flutter_local_notifications
- **Audio Playback**: audioplayers
- **Text-to-Speech**: flutter_tts
- **Architecture Pattern**: Clean Architecture

## Development

### Code Guidelines

- All source code comments MUST be in **English**
- UI text must be internationalized through ARB files
- Follow `analysis_options.yaml` rules

### Run Checks

```bash
# Code analysis
flutter analyze

# Run tests
flutter test

# Code generation
./tool/gen.sh
```

### Monkey Testing

Monkey testing is a stress testing technique that generates random user events to test the app's robustness.

**Build Test Version:**

```bash
# Build APK with test environment configuration
flutter build apk --dart-define=test=true

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Run Monkey Test:**

```bash
# Start monkey testing (generates 10 million random events)
./tests/monkey/monkey.sh

# Stop monkey testing
./tests/monkey/stop-monkey.sh
```

**Important Notes:**

- Test environment (`--dart-define=test=true`) disables:
  - URL launching (privacy policy links)
  - System settings opening (notification, alarm, battery settings)
  - App exit functionality
- These restrictions prevent monkey tests from leaving the app or opening external activities
- Monkey test parameters focus on touch and motion events with 500ms throttle

### Permissions

The app requires the following permissions for reliable operation:

- **Notification Permission** (Android 13+): Display time-up alerts
- **Exact Alarm** (Android 14+): Trigger alerts on time
- **Full Screen Notification**: Display large buttons on lock screen
- **Boot Startup**: Restore timer state after device restart

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

Copyright © 2026 Calcitem Studio

For third-party component license notices, see the [NOTICE](NOTICE) file.

## Contact

For questions or suggestions, please submit an Issue.
