# GridTimer Setup Guide

## Prerequisites

1. **Flutter SDK** (≥ 3.0.0)
   - Install from https://flutter.dev/docs/get-started/install
   
2. **Android SDK**
   - Install Android Studio or command-line tools
   - Required: compileSdk 35, targetSdk 35
   
3. **Git** (for cloning)

## Quick Start

### 1. Clone and Initialize

```bash
# Make scripts executable
chmod +x tool/*.sh

# Run initialization
./tool/flutter-init.sh
```

This will:
- Run `flutter pub get`
- Generate localization files
- Generate Hive adapters and Freezed code
- Run code analysis

### 2. Audio Assets (Already Included!)

**Good news:** Audio files are already included!

GridTimer uses **Kenney's Interface Sounds** (CC0 license):
- ✅ `confirmation_001.ogg` - Used for all timer completions
- ✅ Already in `assets/sounds/kenney_interface-sounds/Audio/`
- ✅ Already copied to `android/app/src/main/res/raw/`

**License:** CC0 (Public Domain) - Free to use, no attribution required  
**Source:** https://kenney.nl/assets/interface-sounds

No action needed! The sound files are ready to use.

### 3. Run the App

```bash
# Connect a device or start emulator
flutter devices

# Run in debug mode
flutter run

# Run in release mode
flutter run --release
```

### 4. Build for Release

#### APK (for testing)
```bash
flutter build apk --release
```

#### AAB (for Play Store)
```bash
flutter build appbundle --release
```

The output will be in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## Code Generation

After modifying entities or translations:

```bash
./tool/gen.sh
```

Or manually:
```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure

```
lib/
  ├── app/                    # App-level configuration
  │   └── providers.dart      # Riverpod providers
  ├── core/
  │   └── domain/            # Domain layer (pure Dart)
  │       ├── entities/      # Domain entities (Freezed)
  │       ├── enums.dart     # Enumerations
  │       ├── types.dart     # Type aliases
  │       └── services/      # Service interfaces
  ├── data/                  # Data layer
  │   ├── models/           # Hive models
  │   └── repositories/     # Storage repositories
  ├── infrastructure/        # Infrastructure layer
  │   ├── timer_service.dart
  │   ├── notification_service.dart
  │   ├── audio_service.dart
  │   ├── tts_service.dart
  │   └── permission_service.dart
  ├── presentation/          # Presentation layer
  │   ├── pages/            # Screen pages
  │   └── widgets/          # Reusable widgets
  ├── l10n/                 # Localization files (ARB)
  └── main.dart             # App entry point
```

## Troubleshooting

### Build Runner Conflicts

If you encounter conflicts during code generation:

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Missing Generated Files

Generated files (`.g.dart`, `.freezed.dart`) are not committed to git.
Always run code generation after cloning:

```bash
./tool/flutter-init.sh
```

### Android Build Issues

1. Check Java version (Java 17 required):
   ```bash
   java -version
   ```

2. Check Gradle wrapper:
   ```bash
   cd android
   ./gradlew clean
   ./gradlew build
   ```

3. Verify Android SDK:
   - compileSdk and targetSdk must be 35
   - Check `android/app/build.gradle`

### Permission Issues on Android 14+

The app requires special permissions:
- **POST_NOTIFICATIONS** (Android 13+)
- **SCHEDULE_EXACT_ALARM** (Android 14+, user must grant)
- **USE_FULL_SCREEN_INTENT** (Android 14+, may require Play Console declaration)

Test permissions on Android 14+ devices/emulators.

## Development Workflow

1. **Make changes** to Dart code
2. **Run code generation** if you modified:
   - Entities (Freezed classes)
   - Hive models
   - Translations (ARB files)
3. **Test** on a real device (recommended for notification testing)
4. **Analyze** code before committing:
   ```bash
   flutter analyze
   ```

## Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

## Play Store Submission Checklist

- [ ] targetSdk = 35 ✓
- [ ] Signed AAB built
- [ ] All permissions documented in Play Console
- [ ] Privacy policy URL (if collecting data)
- [ ] Screenshots (4+)
- [ ] App description (en + zh)
- [ ] Audio assets included
- [ ] Tested on Android 14+ device
- [ ] Exact alarm permission guidance tested
- [ ] Full-screen intent declared (if used)

## License

See LICENSE file for details.

## Support

For issues and questions:
1. Check existing GitHub issues
2. Review Android documentation for permission changes
3. Test on physical Android 14+ device

