import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../core/domain/services/i_audio_service.dart';
import '../core/domain/types.dart';

/// Audio playback service implementation.
class AudioService implements IAudioService {
  final AudioPlayer _player = AudioPlayer();
  SoundKey? _currentSoundKey;

  @override
  Future<void> init() async {
    // Set release mode to loop
    await _player.setReleaseMode(ReleaseMode.loop);
  }

  @override
  Future<void> playLoop({required SoundKey soundKey}) async {
    try {
      // Stop current if playing different sound
      if (_currentSoundKey != null && _currentSoundKey != soundKey) {
        await stop();
      }

      _currentSoundKey = soundKey;
      final assetPath = _soundKeyToAssetPath(soundKey);

      await _player.play(AssetSource(assetPath));
    } catch (e) {
      // 捕获音频播放错误，避免影响应用运行
      debugPrint('Audio playback error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      _currentSoundKey = null;
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  @override
  Future<bool> isPlaying() async {
    return _player.state == PlayerState.playing;
  }

  String _soundKeyToAssetPath(SoundKey soundKey) {
    // All timers use the same sound file
    return 'sounds/sound.wav';
  }

  void dispose() {
    _player.dispose();
  }
}
