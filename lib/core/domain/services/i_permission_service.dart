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
  Future<void> openExactAlarmSettings();
  Future<void> openFullScreenIntentSettings();
  Future<void> openBatteryOptimizationSettings();
  Future<void> openAppSettings();
}



