import 'package:audioplayers/audioplayers.dart';
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
    // Stop current if playing different sound
    if (_currentSoundKey != null && _currentSoundKey != soundKey) {
      await stop();
    }

    _currentSoundKey = soundKey;
    final assetPath = _soundKeyToAssetPath(soundKey);

    await _player.play(AssetSource(assetPath));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentSoundKey = null;
  }

  @override
  Future<bool> isPlaying() async {
    return _player.state == PlayerState.playing;
  }

  String _soundKeyToAssetPath(SoundKey soundKey) {
    // Map sound keys to asset paths (without 'assets/' prefix for AssetSource)
    final map = {
      'bell01': 'sounds/bell_01.mp3',
      'bell02': 'sounds/bell_02.mp3',
      'beep_soft': 'sounds/beep_soft.mp3',
      'chime': 'sounds/chime.mp3',
      'ding': 'sounds/ding.mp3',
      'gentle': 'sounds/gentle.mp3',
    };
    return map[soundKey] ?? 'sounds/bell_01.mp3';
  }

  void dispose() {
    _player.dispose();
  }
}
