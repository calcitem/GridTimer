import 'package:flutter_tts/flutter_tts.dart';
import '../core/domain/services/i_tts_service.dart';

/// TTS service implementation using flutter_tts.
class TtsService implements ITtsService {
  final FlutterTts _tts = FlutterTts();
  double _currentVolume = 1.0;
  double _currentSpeechRate = 0.5;
  double _currentPitch = 1.0;

  @override
  Future<void> init() async {
    // 尝试设置默认语言，优先使用系统当前语言
    // 如果无法获取系统语言或设置失败，则不强制设置，留给 speak() 方法调用时动态指定
    try {
      // 获取当前系统默认语言，例如 "zh-CN", "en-US"
      // 注意：getDefaultLanguage 可能因版本不同而不可用，需根据实际库支持情况调整
      // 这里暂时只做尝试性调用
      // await _tts.setLanguage("zh-CN"); // Removed hardcoded default
    } catch (e) {
      // 忽略语言设置错误，继续初始化其他参数
    }

    await _tts.setVolume(_currentVolume);
    await _tts.setSpeechRate(_currentSpeechRate);
    await _tts.setPitch(_currentPitch);
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
    if (interrupt) {
      await stop();
    }

    await _tts.setLanguage(localeTag);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  void dispose() {
    // FlutterTts doesn't have explicit disposal
  }
}
