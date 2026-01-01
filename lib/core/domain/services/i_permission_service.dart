/// Permission and system settings guidance service.
abstract interface class IPermissionService {
  /// Returns whether the app is allowed to show notifications (Android 13+).
  Future<bool> canPostNotifications();

  /// Returns whether exact alarms are permitted (Android 14+ special access).
  Future<bool> canScheduleExactAlarms();

  /// Returns whether full-screen intents are permitted (Android 14+ special access).
  Future<bool> canUseFullScreenIntent();

  /// Returns whether battery optimization is disabled for this app.
  ///
  /// On Android, this checks if the app is on the battery optimization whitelist
  /// (i.e., system will not restrict background activity).
  /// Returns true if battery optimization is disabled (recommended for alarms).
  /// Returns null if the status cannot be determined (e.g., on some OEM ROMs).
  Future<bool?> isBatteryOptimizationDisabled();

  /// Returns true if the device is running MIUI (Xiaomi).
  Future<bool> isMiuiDevice();

  /// Opens system settings pages (best-effort, platform-specific).
  Future<void> openNotificationSettings();

  /// Opens Android notification channel settings for a specific channelId (Android 8+).
  ///
  /// This is required because scheduled notifications use the channel's sound.
  /// If the channel sound is set to "none", alarms will be silent.
  Future<void> openNotificationChannelSettings({required String channelId});
  Future<void> openExactAlarmSettings();
  Future<void> openFullScreenIntentSettings();
  Future<void> openBatteryOptimizationSettings();
  Future<void> openAppSettings();

  /// Opens the system TTS (Text-to-Speech) settings.
  Future<void> openTtsSettings();

  /// Returns true if TTS settings can be opened on this platform.
  bool get canOpenTtsSettings;
}
