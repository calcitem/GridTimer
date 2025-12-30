import 'package:flutter_tts/flutter_tts.dart';
import '../core/domain/services/i_tts_service.dart';

/// TTS service implementation using flutter_tts.
class TtsService implements ITtsService {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> init() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
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


