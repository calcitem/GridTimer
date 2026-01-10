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
  Locale get locale => Locale(code);
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
      requiresPrivacyPolicyOnFirstLaunch: true,
    ),
  ];

  /// Check if a locale requires showing privacy policy on first launch.
  ///
  /// This checks the effective locale (user preference or system default)
  /// and returns true if that locale requires privacy policy acceptance.
  static bool requiresPrivacyPolicy(Locale? userLocale, Locale systemLocale) {
    final effectiveLocale = userLocale ?? systemLocale;
    final language = getByCode(effectiveLocale.languageCode);
    return language?.requiresPrivacyPolicyOnFirstLaunch ?? false;
  }

  /// Get privacy policy URL for a locale.
  ///
  /// Returns Chinese privacy policy URL for Chinese locales (both Simplified
  /// and Traditional), otherwise checks for locale-specific URL, and finally
  /// falls back to the default English URL.
  static String getPrivacyPolicyUrl(Locale? userLocale, Locale systemLocale) {
    final effectiveLocale = userLocale ?? systemLocale;
    // Use Chinese privacy policy for all Chinese variants (zh, zh-CN, zh-TW, etc.)
    if (effectiveLocale.languageCode == 'zh') {
      return chinesePrivacyPolicyUrl;
    }
    // Check for locale-specific URL in configuration
    final language = getByCode(effectiveLocale.languageCode);
    return language?.privacyPolicyUrl ?? defaultPrivacyPolicyUrl;
  }

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
