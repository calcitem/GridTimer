import 'package:flutter/material.dart';

/// Supported language definition.
class SupportedLanguage {
  /// Language code (e.g., 'en', 'zh').
  final String code;

  /// Native name of the language (e.g., 'English', '简体中文').
  final String nativeName;

  /// English name of the language (for reference).
  final String englishName;

  /// TTS locale code (e.g., 'en-US', 'zh-CN').
  final String ttsLocale;

  const SupportedLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.ttsLocale,
  });

  /// Convert to Flutter Locale.
  Locale get locale => Locale(code);
}

/// Configuration for all supported languages in the app.
class SupportedLocales {
  /// List of all supported languages.
  ///
  /// To add a new language:
  /// 1. Add an entry here
  /// 2. Create corresponding ARB file (lib/l10n/arb/app_<code>.arb)
  /// 3. Update ServiceLocalizations (lib/core/services/service_localizations.dart)
  /// 4. Update DurationFormatter (lib/core/services/duration_formatter.dart)
  /// 5. Run ./tool/gen.sh to regenerate localization files
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
    // Add more languages here:
    // SupportedLanguage(
    //   code: 'ja',
    //   nativeName: '日本語',
    //   englishName: 'Japanese',
    //   ttsLocale: 'ja-JP',
    // ),
    // SupportedLanguage(
    //   code: 'ko',
    //   nativeName: '한국어',
    //   englishName: 'Korean',
    //   ttsLocale: 'ko-KR',
    // ),
    // SupportedLanguage(
    //   code: 'es',
    //   nativeName: 'Español',
    //   englishName: 'Spanish',
    //   ttsLocale: 'es-ES',
    // ),
    // SupportedLanguage(
    //   code: 'fr',
    //   nativeName: 'Français',
    //   englishName: 'French',
    //   ttsLocale: 'fr-FR',
    // ),
    // SupportedLanguage(
    //   code: 'de',
    //   nativeName: 'Deutsch',
    //   englishName: 'German',
    //   ttsLocale: 'de-DE',
    // ),
    // SupportedLanguage(
    //   code: 'ru',
    //   nativeName: 'Русский',
    //   englishName: 'Russian',
    //   ttsLocale: 'ru-RU',
    // ),
  ];

  /// Get language by code.
  static SupportedLanguage? getByCode(String code) {
    try {
      return languages.firstWhere((lang) => lang.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Get language by TTS locale.
  static SupportedLanguage? getByTtsLocale(String ttsLocale) {
    try {
      return languages.firstWhere((lang) => lang.ttsLocale == ttsLocale);
    } catch (_) {
      return null;
    }
  }

  /// Get list of Flutter Locale objects.
  static List<Locale> get flutterLocales =>
      languages.map((lang) => lang.locale).toList();

  /// Get list of TTS locale codes.
  static List<String> get ttsLocales =>
      languages.map((lang) => lang.ttsLocale).toList();

  /// Default language (English).
  static const SupportedLanguage defaultLanguage = SupportedLanguage(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    ttsLocale: 'en-US',
  );

  /// Check if a language code is supported.
  static bool isSupported(String code) {
    return languages.any((lang) => lang.code == code);
  }
}
