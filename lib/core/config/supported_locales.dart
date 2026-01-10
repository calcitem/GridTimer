import 'package:flutter/material.dart';

/// Supported language definition.
class SupportedLanguage {
  /// Language code (e.g., 'en', 'zh').
  final String code;

  /// Native name of the language in its own script.
  /// Examples: 'English', 'Simplified Chinese (简体中文)', '日本語' (Japanese)
  final String nativeName;

  /// English name of the language (for reference).
  final String englishName;

  /// TTS locale code (e.g., 'en-US', 'zh-CN').
  final String ttsLocale;

  /// Whether this locale requires showing privacy policy on first launch.
  ///
  /// Some regions (e.g., China) have specific legal requirements that mandate
  /// showing privacy policy before app usage.
  final bool requiresPrivacyPolicyOnFirstLaunch;

  /// Privacy policy URL for this locale.
  ///
  /// If null, falls back to the default English privacy policy URL.
  final String? privacyPolicyUrl;

  const SupportedLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.ttsLocale,
    this.requiresPrivacyPolicyOnFirstLaunch = false,
    this.privacyPolicyUrl,
  });

  /// Convert to Flutter Locale.
  Locale get locale {
    // Handle script codes and country codes
    // Examples:
    // - 'zh_Hant' -> Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
    // - 'pt_BR' -> Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR')
    final parts = code.split('_');
    if (parts.length == 2) {
      final secondPart = parts[1];
      // Script codes are 4 letters (e.g., 'Hant', 'Hans')
      // Country codes are 2 letters (e.g., 'BR', 'US', 'TW')
      if (secondPart.length == 4) {
        return Locale.fromSubtags(
          languageCode: parts[0],
          scriptCode: secondPart,
        );
      } else if (secondPart.length == 2) {
        return Locale.fromSubtags(
          languageCode: parts[0],
          countryCode: secondPart,
        );
      }
    }
    return Locale(code);
  }
}

/// Configuration for all supported languages in the app.
class SupportedLocales {
  /// Default privacy policy URL (English).
  static const String defaultPrivacyPolicyUrl =
      'https://calcitem.github.io/GridTimer/privacy-policy';

  /// Chinese privacy policy URL (for both Simplified and Traditional Chinese).
  static const String chinesePrivacyPolicyUrl =
      'https://calcitem.github.io/GridTimer/privacy-policy_zh';

  /// List of all supported languages.
  ///
  /// To add a new language:
  /// 1. Add an entry here (for native name and TTS locale)
  /// 2. Create corresponding ARB file (lib/l10n/arb/app_<code>.arb)
  /// 3. Run ./tool/gen.sh to regenerate localization files
  static const List<SupportedLanguage> languages = [
    SupportedLanguage(
      code: 'ar',
      nativeName: 'العربية',
      englishName: 'Arabic',
      ttsLocale: 'ar-SA',
    ),
    SupportedLanguage(
      code: 'bn',
      nativeName: 'বাংলা',
      englishName: 'Bengali',
      ttsLocale: 'bn-IN',
    ),
    SupportedLanguage(
      code: 'de',
      nativeName: 'Deutsch',
      englishName: 'German',
      ttsLocale: 'de-DE',
    ),
    SupportedLanguage(
      code: 'en',
      nativeName: 'English',
      englishName: 'English',
      ttsLocale: 'en-US',
    ),
    SupportedLanguage(
      code: 'es',
      nativeName: 'Español',
      englishName: 'Spanish',
      ttsLocale: 'es-ES',
    ),
    SupportedLanguage(
      code: 'fr',
      nativeName: 'Français',
      englishName: 'French',
      ttsLocale: 'fr-FR',
    ),
    SupportedLanguage(
      code: 'hi',
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
      ttsLocale: 'hi-IN',
    ),
    SupportedLanguage(
      code: 'id',
      nativeName: 'Bahasa Indonesia',
      englishName: 'Indonesian',
      ttsLocale: 'id-ID',
    ),
    SupportedLanguage(
      code: 'it',
      nativeName: 'Italiano',
      englishName: 'Italian',
      ttsLocale: 'it-IT',
    ),
    SupportedLanguage(
      code: 'ja',
      nativeName: '日本語',
      englishName: 'Japanese',
      ttsLocale: 'ja-JP',
    ),
    SupportedLanguage(
      code: 'ko',
      nativeName: '한국어',
      englishName: 'Korean',
      ttsLocale: 'ko-KR',
    ),
    SupportedLanguage(
      code: 'pt',
      nativeName: 'Português',
      englishName: 'Portuguese',
      ttsLocale: 'pt-PT',
    ),
    SupportedLanguage(
      code: 'pt_BR',
      nativeName: 'Português (Brasil)',
      englishName: 'Portuguese (Brazil)',
      ttsLocale: 'pt-BR',
    ),
    SupportedLanguage(
      code: 'ru',
      nativeName: 'Русский',
      englishName: 'Russian',
      ttsLocale: 'ru-RU',
    ),
    SupportedLanguage(
      code: 'th',
      nativeName: 'ไทย',
      englishName: 'Thai',
      ttsLocale: 'th-TH',
    ),
    SupportedLanguage(
      code: 'tr',
      nativeName: 'Türkçe',
      englishName: 'Turkish',
      ttsLocale: 'tr-TR',
    ),
    SupportedLanguage(
      code: 'vi',
      nativeName: 'Tiếng Việt',
      englishName: 'Vietnamese',
      ttsLocale: 'vi-VN',
    ),
    SupportedLanguage(
      code: 'zh',
      nativeName: '简体中文',
      englishName: 'Simplified Chinese',
      ttsLocale: 'zh-CN',
      requiresPrivacyPolicyOnFirstLaunch: true,
    ),
    SupportedLanguage(
      code: 'zh_Hant',
      nativeName: '繁體中文',
      englishName: 'Traditional Chinese',
      ttsLocale: 'zh-TW',
    ),
  ];

  /// Check if a locale requires showing privacy policy on first launch.
  ///
  /// This checks the effective locale (user preference or system default)
  /// and returns true if that locale requires privacy policy acceptance.
  static bool requiresPrivacyPolicy(Locale? userLocale, Locale systemLocale) {
    final effectiveLocale = userLocale ?? systemLocale;
    final language = getByLocale(effectiveLocale);
    return language?.requiresPrivacyPolicyOnFirstLaunch ?? false;
  }

  /// Get privacy policy URL for a locale.
  ///
  /// Returns Chinese privacy policy URL for Chinese locales (both Simplified
  /// and Traditional), otherwise checks for locale-specific URL, and finally
  /// falls back to the default English URL.
  static String getPrivacyPolicyUrl(Locale? userLocale, Locale systemLocale) {
    final effectiveLocale = userLocale ?? systemLocale;
    // Use Chinese privacy policy for all Chinese variants (zh, zh-CN, zh-Hant, etc.)
    if (effectiveLocale.languageCode == 'zh') {
      return chinesePrivacyPolicyUrl;
    }
    // Check for locale-specific URL in configuration
    final language = getByLocale(effectiveLocale);
    return language?.privacyPolicyUrl ?? defaultPrivacyPolicyUrl;
  }

  /// Get language by code.
  ///
  /// For locales with script codes (e.g., 'zh_Hant'), this method will match
  /// by the full code. For plain language codes (e.g., 'zh'), it matches by
  /// language code only.
  static SupportedLanguage? getByCode(String code) {
    try {
      return languages.firstWhere((lang) => lang.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Get language by Locale object.
  ///
  /// Handles simple locales (e.g., Locale('en')), locales with script codes
  /// (e.g., Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')),
  /// and locales with country codes
  /// (e.g., Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR')).
  static SupportedLanguage? getByLocale(Locale locale) {
    String codeToMatch;
    if (locale.scriptCode != null) {
      codeToMatch = '${locale.languageCode}_${locale.scriptCode}';
    } else if (locale.countryCode != null) {
      codeToMatch = '${locale.languageCode}_${locale.countryCode}';
    } else {
      codeToMatch = locale.languageCode;
    }
    return getByCode(codeToMatch);
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
