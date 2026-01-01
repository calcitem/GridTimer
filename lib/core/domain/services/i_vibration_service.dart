/// Vibration service interface for controlling device vibration.
abstract interface class IVibrationService {
  /// Initialize the vibration service.
  Future<void> init();

  /// Check if the device has vibrator support.
  Future<bool> hasVibrator();

  /// Trigger a single vibration.
  ///
  /// [duration] Duration of vibration in milliseconds.
  Future<void> vibrate({int duration = 500});

  /// Trigger a vibration pattern.
  ///
  /// [pattern] Vibration pattern alternating wait and vibrate times in milliseconds.
  /// Example: [0, 500, 200, 500] means vibrate 500ms immediately, wait 200ms, vibrate 500ms again.
  Future<void> vibrateWithPattern(List<int> pattern);

  /// Stop vibration.
  Future<void> cancel();
}
