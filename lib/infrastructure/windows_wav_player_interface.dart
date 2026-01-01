/// Minimal interface for Windows WAV playback backends.
///
/// This interface exists to allow conditional imports so that Web builds don't
/// compile `dart:ffi` code.
abstract interface class WindowsWavPlayer {
  /// Load resources needed for WAV playback.
  Future<void> init({required String assetKey});

  /// Play the WAV once (async).
  Future<void> playOnce();

  /// Play the WAV in a loop (async).
  Future<void> playLoop();

  /// Stop any currently playing WAV.
  Future<void> stop();
}
