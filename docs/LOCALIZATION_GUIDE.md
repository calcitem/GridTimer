# Localization Guide

## Overview

Grid Timer uses a centralized localization architecture that makes adding new language support simple and consistent.

This guide explains how to add new language support to Grid Timer.

## Architecture

Localization texts are divided into two categories:

1. **UI Text**: Uses Flutter ARB files (`lib/l10n/arb/*.arb`)
2. **Service Layer Text**: Uses independent translation maps (not dependent on Flutter BuildContext)

### Why Separate Service Layer Localizations?

Service layer components (notifications, TTS, background tasks) need localized text in scenarios where:
- Application is in early startup phase, `BuildContext` is not yet available
- Background tasks cannot access Flutter UI context
- Following Clean Architecture principles, infrastructure layer should be independent of Flutter

## Adding a New Language

Assume you want to add Japanese support. Follow these steps:

### 1. Configure Supported Language

Edit `lib/core/config/supported_locales.dart`:

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
  // Add Japanese
  SupportedLanguage(
    code: 'ja',
    nativeName: '日本語',
    englishName: 'Japanese',
    ttsLocale: 'ja-JP',
  ),
];
```

### 2. Add Service Layer Translations

#### 2.1 Update ServiceLocalizations

Edit `lib/core/services/service_localizations.dart`:

```dart
static const Map<String, Map<String, String>> _translations = {
  'en': { /* ... */ },
  'zh': { /* ... */ },
  'ja': {
    'timeIsUp': '時間です!',
    'stop': '停止',
    'appTitle': 'グリッドタイマー',
    'running': '実行中',
    'tapToOpen': 'タップして開く',
    'ttsTestMessage': 'タイマー 1 時間です',
    'timerRinging': 'タイマーが鳴っています',
    'timersRinging': 'タイマーが鳴っています',
    'timerActive': 'タイマーが実行中',
    'timersActive': 'タイマーが実行中',
    'timeIsUpTemplate': '{name} 時間です',
  },
};
```

#### 2.2 Update DurationFormatter

Edit `lib/core/services/duration_formatter.dart`:

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

### 3. Create ARB File

Copy `lib/l10n/arb/app_en.arb` to `lib/l10n/arb/app_ja.arb` and translate all strings:

```json
{
  "@@locale": "ja",
  "appTitle": "グリッドタイマー",
  "timerIdle": "待機中",
  "timerRunning": "実行中",
  ...
}
```

### 4. Run Code Generation

```bash
./tool/gen.sh
```

Or manually run:

```bash
flutter gen-l10n
```

### 5. Test

1. Restart the application
2. Go to Settings → Language
3. Select the newly added language
4. Verify that UI text, notifications, and TTS are displayed correctly

## File Locations

| File Type | Path | Purpose |
|-----------|------|---------|
| Language Configuration | `lib/core/config/supported_locales.dart` | Define all supported languages |
| Service Layer Text | `lib/core/services/service_localizations.dart` | Notifications, TTS, Widget text |
| Duration Formatting | `lib/core/services/duration_formatter.dart` | Time unit localization |
| UI Text | `lib/l10n/arb/app_*.arb` | Flutter app UI text |
| Platform Resources (Android) | `android/app/src/main/res/values-*/strings.xml` | Android app name |
| Platform Resources (macOS) | `macos/Runner/*.lproj/InfoPlist.strings` | macOS window title |

## Best Practices

1. **Consistency**: Ensure all translation files use consistent keys
2. **Completeness**: New languages should translate all entries to avoid fallback to English
3. **Testing**:
   - Test UI text rendering
   - Test notification text
   - Test TTS voice announcements
   - Test text display on different screen sizes
4. **Code Generation**: Always run `./tool/gen.sh` after modifying ARB files

## Common Issues

### Q: Why don't ARB file changes take effect?
A: You need to run `./tool/gen.sh` to regenerate localization code.

### Q: What's the difference between service layer text and ARB file text?
A: 
- **ARB Files**: For UI interface text, accessed via `AppLocalizations.of(context)`
- **Service Layer Text**: For background services (notifications, TTS), not dependent on `BuildContext`

### Q: How to test if TTS is using the correct language?
A: 
1. Go to Settings → TTS Settings
2. Click the "Test Voice" button
3. Confirm the announcement is in the correct language

## Future Enhancements

- [ ] Auto-detect system language and set default language
- [ ] Support regional variants (e.g., en-US vs en-GB)
- [ ] Provide translation completeness checking tool
- [ ] Consider using translation management platforms (e.g., Crowdin)

## References

- [Flutter Internationalization](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [ARB File Format](https://github.com/google/app-resource-bundle)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Example: Adding Korean Support

Here's a complete example of adding Korean (ko) support:

**Step 1**: Add to `lib/core/config/supported_locales.dart`
```dart
SupportedLanguage(
  code: 'ko',
  nativeName: '한국어',
  englishName: 'Korean',
  ttsLocale: 'ko-KR',
),
```

**Step 2**: Add to `lib/core/services/service_localizations.dart`
```dart
'ko': {
  'timeIsUp': '시간이 다 되었습니다!',
  'stop': '정지',
  'appTitle': '그리드 타이머',
  'running': '실행 중',
  'tapToOpen': '앱을 열려면 탭하세요',
  'ttsTestMessage': '타이머 1 시간이 다 되었습니다',
  'timerRinging': '타이머가 울리고 있습니다',
  'timersRinging': '타이머가 울리고 있습니다',
  'timerActive': '타이머가 실행 중입니다',
  'timersActive': '타이머가 실행 중입니다',
  'timeIsUpTemplate': '{name} 시간이 다 되었습니다',
},
```

**Step 3**: Add to `lib/core/services/duration_formatter.dart`
```dart
'ko': {
  'seconds': '초',
  'minutes': '분',
  'hours': '시간',
},
```

**Step 4**: Create `lib/l10n/arb/app_ko.arb` with all translations

**Step 5**: Run `./tool/gen.sh`

Done! The Korean language option will now appear in both Settings and TTS Settings pages.
