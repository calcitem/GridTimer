import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform capability detection for conditionally enabling/disabling features.
///
/// This class provides static methods to check what features are available
/// on the current platform, allowing the UI to hide unsupported options.
class PlatformCapabilities {
  PlatformCapabilities._();

  // ============================================================
  // Platform Detection
  // ============================================================

  /// Whether we're running on Android.
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Whether we're running on iOS.
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Whether we're running on a mobile platform (Android or iOS).
  static bool get isMobile => isAndroid || isIOS;

  /// Whether we're running on a desktop platform (Windows, macOS, Linux).
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Whether we're running on Windows.
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Whether we're running on macOS.
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Whether we're running on Linux.
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Whether we're running on the web.
  static bool get isWeb => kIsWeb;

  // ============================================================
  // Feature Capabilities
  // ============================================================

  /// Whether vibration is supported.
  /// Only Android and iOS have vibration hardware.
  static bool get supportsVibration => isMobile;

  /// Whether shake gesture detection is supported.
  /// Requires accelerometer sensor (mobile only).
  static bool get supportsShakeGesture => isMobile;

  /// Whether flip gesture detection is supported.
  /// Requires accelerometer sensor (mobile only).
  static bool get supportsFlipGesture => isMobile;

  /// Whether volume button gesture detection is supported.
  /// Currently only reliable on Android.
  static bool get supportsVolumeButtonGesture => isAndroid;

  /// Whether any gesture controls are supported.
  static bool get supportsGestureControls =>
      supportsShakeGesture || supportsFlipGesture || supportsVolumeButtonGesture;

  /// Whether keeping the screen on is supported/relevant.
  /// Mainly for mobile devices to prevent sleep during timers.
  /// On desktop, window managers handle this differently or it's less critical.
  static bool get supportsKeepScreenOn => isMobile;

  /// Whether system volume control is supported.
  /// Currently only works on Android.
  static bool get supportsVolumeControl => isAndroid;

  /// Whether notification permissions need to be manually requested.
  /// Android 13+ requires runtime permission; iOS always requires.
  static bool get requiresNotificationPermission => isMobile;

  /// Whether exact alarm permission exists.
  /// Only Android 12+ has this permission system.
  static bool get hasExactAlarmPermission => isAndroid;

  /// Whether full-screen intent permission exists.
  /// Only Android 14+ requires this special access.
  static bool get hasFullScreenIntentPermission => isAndroid;

  /// Whether battery optimization settings exist.
  /// Only Android has this; iOS manages background differently.
  static bool get hasBatteryOptimization => isAndroid;

  /// Whether notification channels are supported.
  /// Only Android 8.0+ (API 26+) has notification channels.
  static bool get supportsNotificationChannels => isAndroid;

  /// Whether the app can be killed by the system/user in a way that
  /// prevents scheduled alarms from firing.
  /// This is mainly a concern on Android where background restrictions apply.
  static bool get canBeKilledBySystem => isAndroid;

  /// Whether alarm troubleshooting is relevant for this platform.
  /// Only Android has complex background/permission issues.
  static bool get needsAlarmTroubleshooting => isAndroid;

  /// Whether TTS system settings can be opened programmatically.
  static bool get canOpenTtsSettings => isMobile;

  /// Whether platform has system-level sound/vibration settings.
  static bool get hasSystemSoundSettings => isMobile;

  // ============================================================
  // Feature Descriptions
  // ============================================================

  /// Get a description of why a feature is not available.
  static String getUnavailableReason(String feature) {
    final platform = _currentPlatformName;
    return '$feature is not supported on $platform';
  }

  static String get _currentPlatformName {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'this platform';
  }
}
