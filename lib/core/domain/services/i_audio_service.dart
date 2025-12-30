import '../types.dart';

/// Audio service interface for ringtone playback.
abstract interface class IAudioService {
  /// Preloads audio assets if needed.
  Future<void> init();

  /// Plays the ringtone in a loop.
  /// 
  /// Must interrupt any currently playing sound (newer overrides older).
  Future<void> playLoop({
    required SoundKey soundKey,
  });

  /// Stops any playing sound immediately.
  Future<void> stop();

  /// Whether audio is currently playing.
  Future<bool> isPlaying();
}

