/// Timer execution status.
enum TimerStatus {
  /// Not started, remaining equals preset duration.
  idle,

  /// Countdown in progress (calculated from endAt).
  running,

  /// Paused, remaining is fixed.
  paused,

  /// Time up, alarm is ringing.
  ringing,
}

/// Notification event type for callback handling.
enum NotificationEventType {
  /// Timer reached zero (time up).
  timeUp,

  /// User tapped notification body or opened from full-screen.
  open,

  /// User tapped stop action button.
  stop,
}

/// Permission state enum.
enum PermissionState {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}

/// Exact alarm state (Android 14+).
enum ExactAlarmState {
  granted,
  denied,
  notApplicable, // Android < 12
}

/// Full-screen intent state (Android 14+).
enum FullScreenIntentState {
  granted,
  denied,
  notApplicable,
}

/// Battery optimization state.
enum BatteryOptState {
  optimized,
  notOptimized,
  unknown,
}

/// Audio playback mode for alarm.
enum AudioPlaybackMode {
  /// Loop indefinitely until user stops manually (default).
  loopIndefinitely,

  /// Loop for N minutes then stop automatically.
  loopForDuration,

  /// Loop for N minutes, pause for M minutes, then loop for N minutes again (once).
  loopWithInterval,

  /// Loop for N minutes, pause for M minutes, then loop for N minutes repeatedly until stopped.
  loopWithIntervalRepeating,

  /// Play once and stop automatically.
  playOnce,
}

/// Action to take when gesture is detected during alarm.
enum AlarmGestureAction {
  /// Stop the alarm and reset timer.
  stopAndReset,

  /// Pause the alarm (can be resumed).
  pause,

  /// Do nothing.
  none,
}

/// Types of gestures that can stop/pause alarms.
enum AlarmGestureType {
  /// Press volume up button.
  volumeUp,

  /// Press volume down button.
  volumeDown,

  /// Shake the phone.
  shake,

  /// Flip the phone (face down).
  flip,
}


