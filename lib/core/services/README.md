# Core Services

This directory contains utility services used across the application.

## DurationFormatter

The `DurationFormatter` class provides localized formatting for timer duration names.

### Adding a New Language

To add support for a new language (e.g., Japanese):

1. **Update `duration_formatter.dart`**:

```dart
String _getSecondsUnit() {
  if (_locale.startsWith('zh')) {
    return '秒';
  } else if (_locale.startsWith('ja')) {
    return '秒';  // Japanese
  } else if (_locale.startsWith('ko')) {
    return '초';  // Korean
  }
  return 's'; // Default to English
}

String _getMinutesUnit() {
  if (_locale.startsWith('zh')) {
    return '分钟';
  } else if (_locale.startsWith('ja')) {
    return '分';  // Japanese
  } else if (_locale.startsWith('ko')) {
    return '분';  // Korean
  }
  return 'min'; // Default to English
}

String _getHoursUnit() {
  if (_locale.startsWith('zh')) {
    return '小时';
  } else if (_locale.startsWith('ja')) {
    return '時間';  // Japanese
  } else if (_locale.startsWith('ko')) {
    return '시간';  // Korean
  }
  return 'h'; // Default to English
}
```

2. **Add corresponding entries to ARB files** (`lib/l10n/app_*.arb`):

The localized units in `DurationFormatter` should match the units defined in ARB files for consistency:

- `seconds`: "秒" (zh), "seconds" (en), "秒" (ja), "초" (ko)
- `minutes`: "分钟" (zh), "minutes" (en), "分" (ja), "분" (ko)
- `hours`: "小时" (zh), "hours" (en), "時間" (ja), "시간" (ko)

### Why Not Use ARB Directly?

The `DurationFormatter` is used in the infrastructure layer (`TimerService`), which:

- Initializes early in the app lifecycle, potentially before `BuildContext` is available
- Should remain independent of Flutter's localization system per Clean Architecture
- Needs to format timer names for notifications and TTS in background contexts

This approach provides:
- ✅ Easy extension for new languages
- ✅ Independence from Flutter UI framework
- ✅ Consistent localization with ARB files (manual sync required)
- ✅ Usable in service layers without `BuildContext`

### Future Improvements

Consider creating a build-time code generator that reads ARB files and auto-generates the `DurationFormatter` methods to eliminate manual synchronization.

