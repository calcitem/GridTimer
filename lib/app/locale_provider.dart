import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider for managing app locale (language) settings.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Notifier for managing locale state.
class LocaleNotifier extends Notifier<Locale?> {
  static const String _boxName = 'settings';
  static const String _localeKey = 'app_locale';
  bool _initialized = false;

  @override
  Locale? build() {
    // Don't load immediately, wait for Hive to be initialized
    Future.microtask(_loadLocale);
    return null;
  }

  /// Load saved locale from storage
  Future<void> _loadLocale() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final box = await Hive.openBox(_boxName);
      final savedLocale = box.get(_localeKey) as String?;
      if (savedLocale != null) {
        state = Locale(savedLocale);
      }
    } catch (e) {
      // Ignore errors, use system default
      debugPrint('Failed to load locale: $e');
    }
  }

  /// Change the app locale and save to storage
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      final box = await Hive.openBox(_boxName);
      if (locale != null) {
        await box.put(_localeKey, locale.languageCode);
      } else {
        await box.delete(_localeKey);
      }
    } catch (e) {
      debugPrint('Failed to save locale: $e');
    }
  }

  /// Reset to system default locale
  Future<void> resetToSystem() async {
    await setLocale(null);
  }
}
