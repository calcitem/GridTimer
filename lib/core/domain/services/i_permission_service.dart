/// Permission and system settings guidance service.
abstract interface class IPermissionService {
  /// Returns whether the app is allowed to show notifications (Android 13+).
  Future<bool> canPostNotifications();

  /// Returns whether exact alarms are permitted (Android 14+ special access).
  Future<bool> canScheduleExactAlarms();

  /// Returns whether full-screen intents are permitted (Android 14+ special access).
  Future<bool> canUseFullScreenIntent();

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
}



