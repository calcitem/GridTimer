import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/domain/services/i_tts_service.dart';

/// TTS service implementation using flutter_tts.
class TtsService implements ITtsService {
  final FlutterTts _tts = FlutterTts();
  double _currentVolume = 1.0;
  double _currentSpeechRate = 0.5;
  double _currentPitch = 1.0;
  bool _isInitialized = false;

  /// Track if TTS started speaking (for Windows where completion may not fire)
  bool _startedSpeaking = false;

  /// Completion notifier for tracking TTS completion
  final StreamController<bool> _completionController =
      StreamController<bool>.broadcast();

  /// Stream that emits when TTS completes speaking
  @override
  Stream<bool> get completionStream => _completionController.stream;

  /// Check if running on desktop platform
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    // Set up completion handlers first
    _tts.setCompletionHandler(() {
      debugPrint('TTS completed');
      _completionController.add(true);
    });

    _tts.setErrorHandler((dynamic message) {
      // Notify completion even on error to prevent UI from hanging
      debugPrint('TTS Error: $message');
      _completionController.add(false);
    });

    // Set up start handler to confirm TTS actually started
    _tts.setStartHandler(() {
      debugPrint('TTS started speaking');
      _startedSpeaking = true;
    });

    // Set up cancel handler
    _tts.setCancelHandler(() {
      debugPrint('TTS cancelled');
      _completionController.add(false);
    });

    try {
      // Android specific settings
      if (!kIsWeb && Platform.isAndroid) {
        // Enable speak completion callback
        await _tts.awaitSpeakCompletion(true);

        // Set shared audio focus mode - this may help on some devices
        // ignore: deprecated_member_use
        await _tts.setSharedInstance(true);
      }

      // Windows/Desktop specific settings
      if (_isDesktop) {
        // Enable speak completion callback for desktop platforms
        try {
          await _tts.awaitSpeakCompletion(true);
          debugPrint('TTS: Desktop awaitSpeakCompletion enabled');
        } catch (e) {
          debugPrint('TTS: Desktop awaitSpeakCompletion not supported: $e');
        }
      }
    } catch (e) {
      debugPrint('TTS platform setup error (non-fatal): $e');
    }

    try {
      await _tts.setVolume(_currentVolume);
      await _tts.setSpeechRate(_currentSpeechRate);
      await _tts.setPitch(_currentPitch);
    } catch (e) {
      debugPrint('TTS parameter setup error (non-fatal): $e');
    }

    // Always mark as initialized - we'll try to use TTS anyway
    // Some devices report errors but TTS still works
    _isInitialized = true;
    debugPrint('TTS initialized (may still work even if some setup failed)');
  }

  @override
  Future<void> setVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      'Volume must be between 0.0 and 1.0',
    );
    _currentVolume = volume;
    try {
      await _tts.setVolume(_currentVolume);
    } catch (e) {
      debugPrint('TTS setVolume error (non-fatal): $e');
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    assert(
      rate >= 0.0 && rate <= 1.0,
      'Speech rate must be between 0.0 and 1.0',
    );
    _currentSpeechRate = rate;
    try {
      await _tts.setSpeechRate(_currentSpeechRate);
    } catch (e) {
      debugPrint('TTS setSpeechRate error (non-fatal): $e');
    }
  }

  @override
  Future<void> setPitch(double pitch) async {
    assert(pitch >= 0.5 && pitch <= 2.0, 'Pitch must be between 0.5 and 2.0');
    _currentPitch = pitch;
    try {
      await _tts.setPitch(_currentPitch);
    } catch (e) {
      debugPrint('TTS setPitch error (non-fatal): $e');
    }
  }

  @override
  Future<void> speak({
    required String text,
    required String localeTag,
    bool interrupt = true,
  }) async {
    // Ensure TTS is initialized
    if (!_isInitialized) {
      try {
        await init();
      } catch (e) {
        debugPrint('TTS init failed in speak(): $e');
        _completionController.add(false);
        return;
      }
    }

    // Reset speaking flag
    _startedSpeaking = false;

    // Even if init "failed", try anyway - some devices report failure
    // but TTS still works
    try {
      if (interrupt) {
        try {
          await stop();
        } catch (e) {
          debugPrint('TTS stop error (non-fatal): $e');
        }
      }

      // Try to set language (will always return true, but logs attempts)
      try {
        await _trySetLanguage(localeTag);
      } catch (e) {
        debugPrint('TTS setLanguage error (non-fatal): $e');
        // Continue anyway - TTS might use default language
      }

      // Speak the text
      // Note: On some devices (Xiaomi/MIUI), speak() may return 0 even when
      // it actually works. The completion handler will tell us the real result.
      final result = await _tts.speak(text);
      debugPrint('TTS speak result: $result');

      // On Windows, completion handler may not fire reliably.
      // Add a fallback timeout to emit completion based on estimated duration.
      if (_isDesktop) {
        _scheduleDesktopCompletionFallback(text);
      }

      // Don't fail immediately based on return value - wait for completion handler
      // The completion handler or error handler will fire eventually
    } catch (e, stackTrace) {
      // Log error but don't throw - app won't crash
      debugPrint('TTS speak error: $e');
      debugPrint('TTS speak stack trace: $stackTrace');
      _completionController.add(false);
    }
  }

  /// Schedule a fallback completion for desktop platforms where the
  /// completion handler may not fire reliably.
  void _scheduleDesktopCompletionFallback(String text) {
    // Estimate duration: ~100ms per character at normal speed, minimum 2s
    final estimatedDurationMs = (text.length * 100).clamp(2000, 10000);
    final adjustedDuration = (estimatedDurationMs / _currentSpeechRate).round();

    debugPrint(
      'TTS: Desktop fallback scheduled for ${adjustedDuration}ms '
      '(text length: ${text.length})',
    );

    Future.delayed(Duration(milliseconds: adjustedDuration), () {
      // Only emit if we actually started speaking and haven't completed yet
      if (_startedSpeaking) {
        debugPrint('TTS: Desktop fallback completion triggered');
        _completionController.add(true);
      }
    });
  }

  /// Try to set TTS language with fallback options.
  /// Always returns true - we'll try to speak even if language setting fails,
  /// as some devices (especially Xiaomi/MIUI) may ignore setLanguage but still
  /// speak correctly using the system default language.
  Future<bool> _trySetLanguage(String localeTag) async {
    // Language tag variations to try for Chinese
    final List<String> tagsToTry = [localeTag];

    if (localeTag.startsWith('zh')) {
      // Add various Chinese locale formats for better compatibility
      // Different Android devices/TTS engines may require different formats
      tagsToTry.addAll([
        'zh-CN',
        'zh_CN',
        'zho-CHN',
        'cmn-Hans-CN', // Mandarin Chinese, Simplified
        'zh-Hans',
        'zh',
      ]);
    } else if (localeTag.startsWith('en')) {
      tagsToTry.addAll(['en-US', 'en_US', 'en']);
    }

    // Remove duplicates while preserving order
    final uniqueTags = tagsToTry.toSet().toList();

    bool anySuccess = false;
    for (final tag in uniqueTags) {
      try {
        final result = await _tts.setLanguage(tag);
        debugPrint('TTS setLanguage($tag) result: $result');

        // On Android, result is 1 for success, 0 for failure, -1 for missing data
        if (result == 1) {
          debugPrint('TTS: Successfully set language to $tag');
          anySuccess = true;
          break;
        }
      } catch (e) {
        debugPrint('TTS setLanguage($tag) error: $e');
      }
    }

    if (!anySuccess) {
      // On Xiaomi/MIUI and some other devices, setLanguage always returns 0
      // but TTS still works with the system default language.
      // So we don't fail here - just log and continue.
      debugPrint(
        'TTS: setLanguage returned 0 for all attempts. '
        'Will try to speak anyway using system default.',
      );
    }

    return true; // Always return true - let speak() try anyway
  }

  @override
  Future<void> stop() async {
    // Only call stop if initialized
    if (!_isInitialized) return;

    try {
      await _tts.stop();
    } catch (e) {
      // Ignore stop errors to prevent crashes
    }
  }

  @override
  Future<String?> checkTtsAvailability(String localeTag) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_isInitialized) {
      return 'TTS_INIT_FAILED';
    }

    // Note: On some devices (especially Xiaomi/MIUI), getEngines may return
    // an empty list even though TTS works fine in system settings.
    // So we don't fail based on engine list alone - we'll try to speak
    // and handle errors there instead.
    try {
      final engines = await _tts.getEngines;
      debugPrint('TTS engines: $engines');

      final languages = await _tts.getLanguages;
      debugPrint('TTS available languages: $languages');

      // Log for debugging, but don't fail - TTS might still work
      if (engines == null || (engines is List && engines.isEmpty)) {
        debugPrint('TTS: Engine list is empty, but will try anyway');
      }
    } catch (e) {
      debugPrint('TTS availability check error: $e');
      // Don't return error - TTS might still work
    }

    // Always return null (available) - actual test will happen when speaking
    return null;
  }

  /// Get detailed TTS diagnostic information for troubleshooting.
  @override
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    if (!_isInitialized) {
      await init();
    }

    final info = <String, dynamic>{
      'initialized': _isInitialized,
      'currentVolume': _currentVolume,
      'currentSpeechRate': _currentSpeechRate,
      'currentPitch': _currentPitch,
    };

    try {
      info['engines'] = await _tts.getEngines;
      info['defaultEngine'] = await _tts.getDefaultEngine;
      info['languages'] = await _tts.getLanguages;
      info['defaultVoice'] = await _tts.getDefaultVoice;
      info['voices'] = await _tts.getVoices;
    } catch (e) {
      info['error'] = e.toString();
    }

    debugPrint('TTS Diagnostic Info: $info');
    return info;
  }

  /// Try to speak with a specific engine.
  Future<bool> speakWithEngine({
    required String text,
    required String localeTag,
    String? engineName,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_isInitialized) return false;

    try {
      // Try to set a specific engine if provided
      if (engineName != null && !kIsWeb && Platform.isAndroid) {
        debugPrint('TTS: Trying to set engine to $engineName');
        // Note: flutter_tts doesn't have a direct setEngine method,
        // but we can try to use the engine by its name
      }

      await stop();

      // Set language
      await _trySetLanguage(localeTag);

      // Set volume to max for testing
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);

      // Try to speak
      final result = await _tts.speak(text);
      debugPrint('TTS speakWithEngine result: $result');

      return result == 1;
    } catch (e) {
      debugPrint('TTS speakWithEngine error: $e');
      return false;
    }
  }

  void dispose() {
    _completionController.close();
  }
}
