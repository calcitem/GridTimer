import 'dart:ui';

import '../../l10n/app_localizations.dart';

/// Localization helper for service layer (domain-independent).
///
/// This class provides localized strings for infrastructure services
/// that cannot access Flutter's BuildContext or AppLocalizations.
/// It uses the generated AppLocalizations directly to ensure consistency
/// with the UI.
///
/// To add a new language:
/// 1. Create corresponding ARB file (lib/l10n/arb/app_<code>.arb)
/// 2. Run ./tool/gen.sh to regenerate localization files
/// 3. Update lib/core/config/supported_locales.dart (for language selection UI)
class ServiceLocalizations {
  final AppLocalizations _l10n;

  ServiceLocalizations(String localeName)
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

  /// Get localized "Time is up!" notification body text.
  String get timeIsUp => _l10n.timeIsUp;

  /// Get localized "Stop" button text.
  String get stop => _l10n.actionStop;

  /// Get localized app title.
  String get appTitle => _l10n.appTitle;

  /// Get localized "Running" status text.
  String get running => _l10n.timerRunning;

  /// Get localized "tap to open" text for widgets.
  String get tapToOpen => _l10n.widgetTapToOpen;

  /// Get localized test message for TTS.
  String get ttsTestMessage => _l10n.ttsTestMessage;

  /// Get localized "time is up" suffix for TTS.
  ///
  /// Example: "Timer 1 time is up" or "计时器 1 时间到"
  String timeIsUpSuffix(String timerName) {
    return _l10n.timeUpTts(timerName);
  }

  /// Get localized "timer ringing" count text for widgets.
  String timersRinging(int count) {
    return _l10n.widgetTimersRinging(count);
  }

  /// Get localized "timer active" count text for widgets.
  String timersActive(int count) {
    return _l10n.widgetTimersActive(count);
  }
}
