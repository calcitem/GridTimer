/// Duration name formatter with localization support.
///
/// This utility formats duration values with localized units.
/// It's designed to work independently of Flutter's BuildContext,
/// making it suitable for use in service layers.
class DurationFormatter {
  final String _locale;

  DurationFormatter(this._locale);

  /// Format duration in seconds to a human-readable string with localized units.
  ///
  /// Examples:
  /// - Chinese: "12 秒", "2 分钟", "1 小时"
  /// - English: "12 s", "2 min", "1 h"
  String format(int seconds) {
    if (seconds < 60) {
      return '$seconds ${_getSecondsUnit()}';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes ${_getMinutesUnit()}';
    } else {
      final hours = seconds ~/ 3600;
      return '$hours ${_getHoursUnit()}';
    }
  }

  String _getSecondsUnit() {
    if (_locale.startsWith('zh')) {
      return '秒';
    }
    // Add more languages here as needed
    return 's'; // Default to English
  }

  String _getMinutesUnit() {
    if (_locale.startsWith('zh')) {
      return '分钟';
    }
    // Add more languages here as needed
    return 'min'; // Default to English
  }

  String _getHoursUnit() {
    if (_locale.startsWith('zh')) {
      return '小时';
    }
    // Add more languages here as needed
    return 'h'; // Default to English
  }
}
