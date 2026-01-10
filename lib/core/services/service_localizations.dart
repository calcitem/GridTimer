/// Localization helper for service layer (domain-independent).
///
/// This class provides localized strings for infrastructure services
/// that cannot access Flutter's BuildContext or AppLocalizations.
/// It supports multiple languages and can be easily extended.
///
/// To add a new language:
/// 1. Add entries to the _translations map below
/// 2. Update lib/core/config/supported_locales.dart
/// 3. Create corresponding ARB file (lib/l10n/arb/app_<code>.arb)
class ServiceLocalizations {
  final String _locale;

  ServiceLocalizations(this._locale);

  /// Get language code from locale string.
  String get _languageCode {
    if (_locale.contains('_') || _locale.contains('-')) {
      return _locale.split(RegExp('[_-]')).first;
    }
    return _locale;
  }

  /// Centralized translation map.
  ///
  /// Add new language translations here when extending language support.
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'timeIsUp': 'Time is up!',
      'stop': 'Stop',
      'appTitle': 'Grid Timer',
      'running': 'Running',
      'tapToOpen': 'Tap to open app',
      'ttsTestMessage': 'Timer 1 time is up',
      'timerRinging': 'timer ringing',
      'timersRinging': 'timers ringing',
      'timerActive': 'timer active',
      'timersActive': 'timers active',
      'timeIsUpTemplate': '{name} time is up',
    },
    'zh': {
      'timeIsUp': '时间到!',
      'stop': '停止',
      'appTitle': '九宫计时',
      'running': '运行中',
      'tapToOpen': '点击打开应用',
      'ttsTestMessage': '计时器 1 时间到了',
      'timerRinging': '个计时器响铃',
      'timersRinging': '个计时器响铃',
      'timerActive': '个计时器运行中',
      'timersActive': '个计时器运行中',
      'timeIsUpTemplate': '{name} 时间到',
    },
    // Add more languages here:
    // 'ja': {
    //   'timeIsUp': '時間です!',
    //   'stop': '停止',
    //   'appTitle': 'グリッドタイマー',
    //   'running': '実行中',
    //   'tapToOpen': 'タップして開く',
    //   'ttsTestMessage': 'タイマー 1 時間です',
    //   'timerRinging': 'タイマーが鳴っています',
    //   'timersRinging': 'タイマーが鳴っています',
    //   'timerActive': 'タイマーが実行中',
    //   'timersActive': 'タイマーが実行中',
    //   'timeIsUpTemplate': '{name} 時間です',
    // },
  };

  /// Get translation for a key, falling back to English if not found.
  String _translate(String key) {
    final langTranslations = _translations[_languageCode];
    if (langTranslations != null && langTranslations.containsKey(key)) {
      return langTranslations[key]!;
    }
    // Fallback to English
    return _translations['en']![key] ?? key;
  }

  /// Get localized "Time is up!" notification body text.
  String get timeIsUp => _translate('timeIsUp');

  /// Get localized "Stop" button text.
  String get stop => _translate('stop');

  /// Get localized app title.
  String get appTitle => _translate('appTitle');

  /// Get localized "Running" status text.
  String get running => _translate('running');

  /// Get localized "tap to open" text for widgets.
  String get tapToOpen => _translate('tapToOpen');

  /// Get localized test message for TTS.
  String get ttsTestMessage => _translate('ttsTestMessage');

  /// Get localized "time is up" suffix for TTS.
  ///
  /// Example: "Timer 1 time is up" or "计时器 1 时间到"
  String timeIsUpSuffix(String timerName) {
    final template = _translate('timeIsUpTemplate');
    return template.replaceAll('{name}', timerName);
  }

  /// Get localized "timer ringing" count text for widgets.
  String timersRinging(int count) {
    if (_languageCode == 'zh') {
      // Chinese uses the same form for singular and plural
      return '$count ${_translate('timersRinging')}';
    }
    // English and most other languages
    final key = count == 1 ? 'timerRinging' : 'timersRinging';
    return count == 1 ? '1 ${_translate(key)}' : '$count ${_translate(key)}';
  }

  /// Get localized "timer active" count text for widgets.
  String timersActive(int count) {
    if (_languageCode == 'zh') {
      // Chinese uses the same form for singular and plural
      return '$count ${_translate('timersActive')}';
    }
    // English and most other languages
    final key = count == 1 ? 'timerActive' : 'timersActive';
    return count == 1 ? '1 ${_translate(key)}' : '$count ${_translate(key)}';
  }
}
