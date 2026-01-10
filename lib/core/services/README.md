# Core Services

This directory contains utility services used across the application.

## Adding a New Language

To add support for a new language (e.g., Japanese), follow these steps:

### 1. Update Supported Locales Configuration

Add the new language to `lib/core/config/supported_locales.dart`:

```dart
static const List<SupportedLanguage> languages = [
  SupportedLanguage(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    ttsLocale: 'en-US',
  ),
  SupportedLanguage(
    code: 'zh',
    nativeName: '简体中文',
    englishName: 'Simplified Chinese',
    ttsLocale: 'zh-CN',
  ),
  SupportedLanguage(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
    ttsLocale: 'ja-JP',
  ),
];
```

### 2. Update ServiceLocalizations

Add translations to `lib/core/services/service_localizations.dart`:

```dart
static const Map<String, Map<String, String>> _translations = {
  'en': { /* ... */ },
  'zh': { /* ... */ },
  'ja': {
    'timeIsUp': '時間です!',
    'stop': '停止',
    'appTitle': 'グリッドタイマー',
    'running': '実行中',
    // ... add all keys
  },
};
```

### 3. Update DurationFormatter

Add time unit translations to `lib/core/services/duration_formatter.dart`:

```dart
static const Map<String, Map<String, String>> _timeUnits = {
  'en': { /* ... */ },
  'zh': { /* ... */ },
  'ja': {
    'seconds': '秒',
    'minutes': '分',
    'hours': '時間',
  },
};
```

### 4. Create ARB File

Create `lib/l10n/arb/app_ja.arb` with all localized strings.

### 5. Run Code Generation

```bash
./tool/gen.sh
```

## Why Not Use ARB Directly?

The `DurationFormatter` and `ServiceLocalizations` are used in the infrastructure layer, which:

- Initializes early in the app lifecycle, potentially before `BuildContext` is available
- Should remain independent of Flutter's localization system per Clean Architecture
- Needs to format timer names for notifications and TTS in background contexts

This approach provides:
- ✅ Easy extension for new languages (single point of configuration)
- ✅ Independence from Flutter UI framework
- ✅ Consistent localization with centralized translation maps
- ✅ Usable in service layers without `BuildContext`

### Future Improvements

Consider creating a build-time code generator that reads ARB files and auto-generates the `DurationFormatter` methods to eliminate manual synchronization.
