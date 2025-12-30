# GridTimer - Project Structure

## 📁 Complete File Tree

```
GridTimer/
├── android/                           # Android native code
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── kotlin/com/gridtimer/app/
│   │   │   │   └── MainActivity.kt    # Flutter activity
│   │   │   ├── res/
│   │   │   │   ├── raw/               # Notification sounds (*.mp3)
│   │   │   │   ├── values/
│   │   │   │   │   └── styles.xml     # Android themes
│   │   │   │   └── mipmap-*/          # App icons (all densities)
│   │   │   └── AndroidManifest.xml    # Permissions & components
│   │   └── build.gradle               # App-level build config (SDK 35)
│   ├── gradle/wrapper/
│   │   └── gradle-wrapper.properties  # Gradle version
│   ├── build.gradle                   # Project-level build config
│   ├── settings.gradle                # Gradle settings
│   ├── gradle.properties              # Gradle JVM args
│   └── local.properties               # SDK paths (generated)
│
├── assets/
│   └── sounds/                        # Audio assets for Flutter
│       ├── bell_01.mp3
│       ├── bell_02.mp3
│       ├── beep_soft.mp3
│       ├── chime.mp3
│       ├── ding.mp3
│       ├── gentle.mp3
│       └── README.md
│
├── lib/                               # Dart source code
│   ├── app/
│   │   └── providers.dart             # Riverpod provider setup
│   │
│   ├── core/
│   │   └── domain/                    # Domain layer (pure Dart)
│   │       ├── entities/              # Business entities (Freezed)
│   │       │   ├── timer_config.dart
│   │       │   ├── timer_config.freezed.dart
│   │       │   ├── timer_config.g.dart
│   │       │   ├── timer_grid_set.dart
│   │       │   ├── timer_grid_set.freezed.dart
│   │       │   ├── timer_grid_set.g.dart
│   │       │   ├── timer_session.dart
│   │       │   ├── timer_session.freezed.dart
│   │       │   ├── timer_session.g.dart
│   │       │   ├── app_settings.dart
│   │       │   ├── app_settings.freezed.dart
│   │       │   └── app_settings.g.dart
│   │       ├── services/              # Service interfaces
│   │       │   ├── i_timer_service.dart
│   │       │   ├── i_notification_service.dart
│   │       │   ├── i_audio_service.dart
│   │       │   ├── i_tts_service.dart
│   │       │   ├── i_permission_service.dart
│   │       │   ├── i_mode_service.dart
│   │       │   └── i_clock.dart
│   │       ├── enums.dart             # Enumerations
│   │       └── types.dart             # Type aliases
│   │
│   ├── data/                          # Data layer
│   │   ├── models/                    # Hive persistence models
│   │   │   ├── timer_config_hive.dart
│   │   │   ├── timer_config_hive.g.dart
│   │   │   ├── timer_grid_set_hive.dart
│   │   │   ├── timer_grid_set_hive.g.dart
│   │   │   ├── timer_session_hive.dart
│   │   │   ├── timer_session_hive.g.dart
│   │   │   ├── app_settings_hive.dart
│   │   │   └── app_settings_hive.g.dart
│   │   └── repositories/
│   │       └── storage_repository.dart # Hive box management
│   │
│   ├── infrastructure/                # Infrastructure layer
│   │   ├── timer_service.dart         # Core timer logic
│   │   ├── mode_service.dart          # Mode management
│   │   ├── notification_service.dart  # Android notifications
│   │   ├── audio_service.dart         # Audio playback
│   │   ├── tts_service.dart           # Text-to-speech
│   │   └── permission_service.dart    # System permissions
│   │
│   ├── presentation/                  # Presentation layer
│   │   ├── pages/
│   │   │   └── grid_page.dart         # Main grid screen
│   │   └── widgets/
│   │       └── timer_grid_cell.dart   # Single timer cell
│   │
│   ├── l10n/                          # Localization
│   │   ├── app_en.arb                 # English translations
│   │   └── app_zh.arb                 # Chinese translations
│   │
│   └── main.dart                      # App entry point
│
├── tool/                              # Build & setup scripts
│   ├── flutter-init.sh                # Full initialization
│   ├── gen.sh                         # Code generation only
│   └── build-release.sh               # Release build
│
├── .gitignore                         # Git ignore rules
├── analysis_options.yaml              # Dart analyzer config
├── CHANGELOG.md                       # Version history
├── CONTRIBUTING.md                    # Contribution guidelines
├── l10n.yaml                          # Localization config
├── LICENSE                            # Project license
├── PROJECT_STATUS.md                  # Implementation status
├── PROJECT_STRUCTURE.md               # This file
├── pubspec.yaml                       # Flutter dependencies
├── QUICKSTART.md                      # 5-minute setup guide
├── README.md                          # Full PRD documentation
└── SETUP.md                           # Detailed setup guide
```

## 📦 Key Files Explained

### Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Flutter dependencies, assets, localization |
| `l10n.yaml` | Localization generation config |
| `analysis_options.yaml` | Dart linter rules |
| `.gitignore` | Files to exclude from version control |

### Android Configuration

| File | Purpose |
|------|---------|
| `android/app/build.gradle` | compileSdk 35, targetSdk 35, desugaring |
| `android/app/src/main/AndroidManifest.xml` | Permissions, receivers, activities |
| `android/app/src/main/kotlin/.../MainActivity.kt` | Flutter activity entry |

### Domain Layer (Business Logic)

| Directory | Purpose |
|-----------|---------|
| `lib/core/domain/entities/` | Immutable business entities (Freezed) |
| `lib/core/domain/services/` | Service interfaces (dependency inversion) |
| `lib/core/domain/enums.dart` | Enumerations (TimerStatus, etc.) |
| `lib/core/domain/types.dart` | Type aliases (ModeId, TimerId, etc.) |

### Data Layer (Persistence)

| Directory | Purpose |
|-----------|---------|
| `lib/data/models/` | Hive adapters for entities |
| `lib/data/repositories/` | Storage abstraction (Hive boxes) |

### Infrastructure Layer (Services)

| File | Purpose |
|------|---------|
| `timer_service.dart` | Core timer logic, state management, recovery |
| `mode_service.dart` | Mode/preset management |
| `notification_service.dart` | Android notifications, exact alarms |
| `audio_service.dart` | Ringtone playback (audioplayers) |
| `tts_service.dart` | Text-to-speech (flutter_tts) |
| `permission_service.dart` | Permission requests, settings navigation |

### Presentation Layer (UI)

| Directory | Purpose |
|-----------|---------|
| `lib/presentation/pages/` | Full-screen pages |
| `lib/presentation/widgets/` | Reusable UI components |
| `lib/app/providers.dart` | Riverpod provider definitions |

### Localization

| File | Purpose |
|------|---------|
| `lib/l10n/app_en.arb` | English translations |
| `lib/l10n/app_zh.arb` | Chinese translations |

## 🔄 Code Generation Files

These files are generated by `build_runner` and **should NOT be edited manually**:

- `*.freezed.dart` - Generated by Freezed (immutability, copyWith)
- `*.g.dart` - Generated by Hive/JSON serialization
- `lib/generated/` - Generated by flutter gen-l10n

**To regenerate:**
```bash
./tool/gen.sh
```

## 📱 Assets

### Audio Assets (Required)

Must be present in **both locations**:
1. `assets/sounds/*.mp3` - For Flutter AssetSource
2. `android/app/src/main/res/raw/*.mp3` - For Android notifications

### Icons (Required for Release)

App icons must be present in:
```
android/app/src/main/res/mipmap-mdpi/ic_launcher.png
android/app/src/main/res/mipmap-hdpi/ic_launcher.png
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

Use `flutter_launcher_icons` package to generate.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────┐
│          Presentation Layer (UI)            │
│  - Riverpod State Management                │
│  - Flutter Widgets                          │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│       Infrastructure Layer (Services)       │
│  - TimerService, NotificationService, etc.  │
│  - Platform-specific implementations        │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│          Data Layer (Persistence)           │
│  - Hive repositories                        │
│  - Entity <-> Model conversion              │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│        Domain Layer (Business Logic)        │
│  - Entities (Freezed)                       │
│  - Service Interfaces                       │
│  - 100% Flutter-independent                 │
└─────────────────────────────────────────────┘
```

## 📊 File Count Summary

- **Dart files:** ~40 (excluding generated)
- **Generated files:** ~16 (*.freezed.dart, *.g.dart)
- **Android files:** ~10
- **Config files:** ~8
- **Documentation:** ~8
- **Scripts:** 3

## 🎯 Critical Paths

### Timer Flow
```
User taps cell
  → TimerGridCell handles tap
  → Calls TimerService.start()
  → TimerService updates state
  → Schedules notification via NotificationService
  → Persists to Hive via StorageRepository
  → UI updates via Riverpod stream
```

### Notification Flow
```
Notification fires at scheduled time
  → NotificationService emits event
  → TimerService handles time-up event
  → Plays audio via AudioService
  → Speaks TTS via TtsService
  → Updates session to ringing status
  → UI reflects ringing state
```

## 📝 Notes

- All source code comments are in **English** (per PRD requirement)
- UI text uses **ARB localization** (bilingual support)
- **Clean Architecture** strictly enforced
- **Testable** design (domain layer has zero Flutter dependencies)

---

For more details, see:
- **SETUP.md** - Detailed setup instructions
- **PROJECT_STATUS.md** - Implementation checklist
- **QUICKSTART.md** - Quick 5-minute start guide

