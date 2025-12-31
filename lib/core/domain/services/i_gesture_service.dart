import '../enums.dart';

/// Gesture detection service interface for alarm control.
abstract interface class IGestureService {
  /// Initialize the gesture detection service.
  Future<void> init();

  /// Start listening for gestures.
  /// Returns a stream of detected gesture types.
  Stream<AlarmGestureType> get gestureStream;

  /// Start monitoring gestures.
  void startMonitoring();

  /// Stop monitoring gestures.
  void stopMonitoring();

  /// Update shake sensitivity (1.0 - 5.0, lower = more sensitive).
  void updateShakeSensitivity(double sensitivity);

  /// Dispose resources.
  void dispose();
}
