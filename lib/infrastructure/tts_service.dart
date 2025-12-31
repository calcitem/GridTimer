import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/domain/services/i_tts_service.dart';

/// TTS service implementation using flutter_tts.
class TtsService implements ITtsService {
  final FlutterTts _tts = FlutterTts();
  double _currentVolume = 1.0;
  double _currentSpeechRate = 0.5;
  double _currentPitch = 1.0;
  bool _isInitialized = false;

  /// Completion notifier for tracking TTS completion
  final StreamController<bool> _completionController =
      StreamController<bool>.broadcast();

  /// Stream that emits when TTS completes speaking
  @override
  Stream<bool> get completionStream => _completionController.stream;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    // Try to set default language, prioritize system current language
    // If unable to get system language or setting fails, don't force it,
    // leave it to be dynamically specified when speak() method is called
    try {
      // Get current system default language, e.g. "zh-CN", "en-US"
      // Note: getDefaultLanguage may not be available depending on version,
      // adjust according to actual library support
      // Here we just try the call tentatively
      // await _tts.setLanguage("zh-CN"); // Removed hardcoded default
    } catch (e) {
      // Ignore language setting errors, continue initializing other parameters
    }

    // Set up completion handlers
    _tts.setCompletionHandler(() {
      _completionController.add(true);
    });

    _tts.setErrorHandler((dynamic message) {
      // Notify completion even on error to prevent UI from hanging
      _completionController.add(false);
    });

    try {
      await _tts.setVolume(_currentVolume);
      await _tts.setSpeechRate(_currentSpeechRate);
      await _tts.setPitch(_currentPitch);
      _isInitialized = true;
    } catch (e) {
      // 如果初始化失败，记录错误但不阻止应用启动
      // If initialization fails, log error but don't block app startup
      _isInitialized = false;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      'Volume must be between 0.0 and 1.0',
    );
    _currentVolume = volume;
    await _tts.setVolume(_currentVolume);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    assert(
      rate >= 0.0 && rate <= 1.0,
      'Speech rate must be between 0.0 and 1.0',
    );
    _currentSpeechRate = rate;
    await _tts.setSpeechRate(_currentSpeechRate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    assert(pitch >= 0.5 && pitch <= 2.0, 'Pitch must be between 0.5 and 2.0');
    _currentPitch = pitch;
    await _tts.setPitch(_currentPitch);
  }

  @override
  Future<void> speak({
    required String text,
    required String localeTag,
    bool interrupt = true,
  }) async {
    // 确保 TTS 已初始化
    // Ensure TTS is initialized
    if (!_isInitialized) {
      await init();
    }

    if (!_isInitialized) return; // 如果初始化失败，静默返回

    try {
      if (interrupt) {
        await stop();
      }

      await _tts.setLanguage(localeTag);
      await _tts.speak(text);
    } catch (e) {
      // 记录错误但不抛出异常
      // Log error but don't throw
      _completionController.add(false);
    }
  }

  @override
  Future<void> stop() async {
    // 只在初始化后才调用 stop
    // Only call stop if initialized
    if (!_isInitialized) return;

    try {
      await _tts.stop();
    } catch (e) {
      // 忽略 stop 错误，避免崩溃
      // Ignore stop errors to prevent crashes
    }
  }

  void dispose() {
    _completionController.close();
  }
}
