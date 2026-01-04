/// Localization helper for service layer (domain-independent).
///
/// This class provides localized strings for infrastructure services
/// that cannot access Flutter's BuildContext or AppLocalizations.
/// It supports multiple languages and can be easily extended.
class ServiceLocalizations {
  final String _locale;

  ServiceLocalizations(this._locale);

  /// Get localized "Time is up!" notification body text.
  String get timeIsUp {
    if (_locale.startsWith('zh')) {
      return '时间到!';
    }
    // Add more languages here as needed
    // Example:
    // if (_locale.startsWith('ja')) return '時間です!';
    // if (_locale.startsWith('ko')) return '시간이 다 되었습니다!';
    // if (_locale.startsWith('es')) return '¡Se acabó el tiempo!';
    return 'Time is up!'; // Default to English
  }

  /// Get localized "Stop" button text.
  String get stop {
    if (_locale.startsWith('zh')) {
      return '停止';
    }
    // Add more languages here as needed
    return 'Stop'; // Default to English
  }

  /// Get localized app title.
  String get appTitle {
    if (_locale.startsWith('zh')) {
      return '九宫计时';
    }
    // Add more languages here as needed
    return 'Grid Timer'; // Default to English
  }

  /// Get localized "Running" status text.
  String get running {
    if (_locale.startsWith('zh')) {
      return '运行中';
    }
    // Add more languages here as needed
    return 'Running'; // Default to English
  }

  /// Get localized "time is up" suffix for TTS.
  ///
  /// Example: "Timer 1 time is up" or "计时器 1 时间到"
  String timeIsUpSuffix(String timerName) {
    if (_locale.startsWith('zh')) {
      return '$timerName 时间到';
    }
    // Add more languages here as needed
    return '$timerName time is up'; // Default to English
  }

  /// Get localized "timer ringing" count text for widgets.
  String timersRinging(int count) {
    if (_locale.startsWith('zh')) {
      return '$count 个计时器响铃';
    }
    // Add more languages here as needed
    return count == 1 ? '1 timer ringing' : '$count timers ringing';
  }

  /// Get localized "timer active" count text for widgets.
  String timersActive(int count) {
    if (_locale.startsWith('zh')) {
      return '$count 个计时器运行中';
    }
    // Add more languages here as needed
    return count == 1 ? '1 timer active' : '$count timers active';
  }

  /// Get localized "tap to open" text for widgets.
  String get tapToOpen {
    if (_locale.startsWith('zh')) {
      return '点击打开应用';
    }
    // Add more languages here as needed
    return 'Tap to open app';
  }

  /// Get localized test message for TTS.
  ///
  /// Example: "Timer 1 time is up" or "计时器 1 时间到了"
  String get ttsTestMessage {
    if (_locale.startsWith('zh')) {
      return '计时器 1 时间到了';
    }
    // Add more languages here as needed
    return 'Timer 1 time is up';
  }
}
