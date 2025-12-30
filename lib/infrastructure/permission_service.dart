import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../core/domain/services/i_permission_service.dart';

/// Permission service implementation.
class PermissionService implements IPermissionService {
  @override
  Future<bool> canPostNotifications() async {
    if (!Platform.isAndroid) return true;
    
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;

    // Note: permission_handler may not expose this API.
    // This is a best-effort implementation.
    // For Android 14+, this requires platform channel to check canScheduleExactAlarms().
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  @override
  Future<bool> canUseFullScreenIntent() async {
    // Full-screen intent permission check requires platform channel.
    // Placeholder implementation.
    return true;
  }

  @override
  Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  @override
  Future<void> openExactAlarmSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.alarm);
  }

  @override
  Future<void> openFullScreenIntentSettings() async {
    await AppSettings.openAppSettings();
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.battery);
  }

  @override
  Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }
}



