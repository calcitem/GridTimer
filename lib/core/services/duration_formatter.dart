import 'dart:ui';

import '../../l10n/app_localizations.dart';

/// Duration name formatter with localization support.
///
/// This utility formats duration values with localized units.
/// It's designed to work independently of Flutter's BuildContext,
/// making it suitable for use in service layers.
///
/// To add a new language:
/// 1. Create corresponding ARB file
/// 2. Run ./tool/gen.sh to regenerate localization files
/// 3. Update lib/core/config/supported_locales.dart
class DurationFormatter {
  final AppLocalizations _l10n;

  DurationFormatter(String localeName)
    : _l10n = lookupAppLocalizations(_parseLocale(localeName));

  /// Parse locale string to Locale object.
  static Locale _parseLocale(String localeName) {
    String languageCode = localeName;
    String? countryCode;

    if (localeName.contains('_')) {
      final parts = localeName.split('_');
      languageCode = parts[0];
      if (parts.length > 1) countryCode = parts[1];
    } else if (localeName.contains('-')) {
      final parts = localeName.split('-');
      languageCode = parts[0];
      if (parts.length > 1) countryCode = parts[1];
    }

    return Locale(languageCode, countryCode);
  }

  /// Format duration in seconds to a human-readable string with localized units.
  ///
  /// Examples:
  /// - English: "12 s", "2 min", "1 h"
  /// - Chinese: "12 秒" (miǎo), "2 分钟" (fēnzhōng), "1 小时" (xiǎoshí)
  String format(int seconds) {
    if (seconds < 60) {
      return '$seconds ${_l10n.unitSecondsShort}';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes ${_l10n.unitMinutesShort}';
    } else {
      final hours = seconds ~/ 3600;
      return '$hours ${_l10n.unitHoursShort}';
    }
  }
}
