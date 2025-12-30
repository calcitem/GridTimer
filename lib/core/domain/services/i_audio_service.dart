import '../types.dart';
import '../enums.dart';

/// Audio service interface for ringtone playback.
abstract interface class IAudioService {
  /// Preloads audio assets if needed.
  Future<void> init();

  /// Plays the ringtone in a loop (backward compatible).
  ///
  /// Must interrupt any currently playing sound (newer overrides older).
  Future<void> playLoop({required SoundKey soundKey, double volume = 1.0});

  /// Plays the ringtone with specified playback mode.
  ///
  /// [mode] determines how the audio plays (loop indefinitely, timed, with intervals, etc.)
  /// [loopDurationMinutes] is used for timed modes
  /// [intervalPauseMinutes] is used for interval modes
  Future<void> playWithMode({
    required SoundKey soundKey,
    required AudioPlaybackMode mode,
    double volume = 1.0,
    int loopDurationMinutes = 5,
    int intervalPauseMinutes = 2,
  });

  /// Stops any playing sound immediately.
  Future<void> stop();

  /// Whether audio is currently playing.
  Future<bool> isPlaying();

  /// Set the volume for future playback (0.0 - 1.0).
  Future<void> setVolume(double volume);
}
