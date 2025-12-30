/// TTS (Text-to-Speech) service interface.
abstract interface class ITtsService {
  /// Initializes TTS engine and applies platform defaults.
  Future<void> init();

  /// Speaks text. Must interrupt any current utterance by default.
  ///
  /// [text] - The text to speak.
  /// [localeTag] - Locale tag (e.g., "zh-CN", "en-US").
  /// [interrupt] - Whether to stop current speech before speaking.
  Future<void> speak({
    required String text,
    required String localeTag,
    bool interrupt = true,
  });

  /// Stops speaking immediately.
  Future<void> stop();

  /// Set the volume for TTS (0.0 - 1.0).
  Future<void> setVolume(double volume);

  /// Set the speech rate for TTS (0.0 - 1.0, where 0.5 is normal).
  Future<void> setSpeechRate(double rate);

  /// Set the pitch for TTS (0.5 - 2.0, where 1.0 is normal).
  Future<void> setPitch(double pitch);
}
