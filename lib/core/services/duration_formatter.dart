/// Duration name formatter with localization support.
///
/// This utility formats duration values with localized units.
/// It's designed to work independently of Flutter's BuildContext,
/// making it suitable for use in service layers.
///
/// To add a new language:
/// 1. Add unit translations to the _timeUnits map below
/// 2. Update lib/core/config/supported_locales.dart
/// 3. Update lib/core/services/service_localizations.dart
/// 4. Create corresponding ARB file
class DurationFormatter {
  final String _locale;

  DurationFormatter(this._locale);

  /// Get language code from locale string.
  String get _languageCode {
    if (_locale.contains('_') || _locale.contains('-')) {
      return _locale.split(RegExp('[_-]')).first;
    }
    return _locale;
  }

  /// Centralized time unit translations.
  ///
  /// Add new language translations here when extending language support.
  static const Map<String, Map<String, String>> _timeUnits = {
    'en': {
      'seconds': 's',
      'minutes': 'min',
      'hours': 'h',
    },
    'zh': {
      'seconds': '秒',
      'minutes': '分钟',
      'hours': '小时',
    },
    // Add more languages here:
    // 'ja': {
    //   'seconds': '秒',
    //   'minutes': '分',
    //   'hours': '時間',
    // },
    // 'ko': {
    //   'seconds': '초',
    //   'minutes': '분',
    //   'hours': '시간',
    // },
    // 'es': {
    //   'seconds': 's',
    //   'minutes': 'min',
    //   'hours': 'h',
    // },
    // 'fr': {
    //   'seconds': 's',
    //   'minutes': 'min',
    //   'hours': 'h',
    // },
    // 'de': {
    //   'seconds': 's',
    //   'minutes': 'Min',
    //   'hours': 'Std',
    // },
    // 'ru': {
    //   'seconds': 'с',
    //   'minutes': 'мин',
    //   'hours': 'ч',
    // },
  };

  /// Get unit translation, falling back to English if not found.
  String _getUnit(String unitKey) {
    final langUnits = _timeUnits[_languageCode];
    if (langUnits != null && langUnits.containsKey(unitKey)) {
      return langUnits[unitKey]!;
    }
    // Fallback to English
    return _timeUnits['en']![unitKey] ?? unitKey;
  }

  /// Format duration in seconds to a human-readable string with localized units.
  ///
  /// Examples:
  /// - Chinese: "12 秒", "2 分钟", "1 小时"
  /// - English: "12 s", "2 min", "1 h"
  String format(int seconds) {
    if (seconds < 60) {
      return '$seconds ${_getUnit('seconds')}';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes ${_getUnit('minutes')}';
    } else {
      final hours = seconds ~/ 3600;
      return '$hours ${_getUnit('hours')}';
    }
  }
}
