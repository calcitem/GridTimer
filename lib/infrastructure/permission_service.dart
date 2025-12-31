import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../core/domain/services/i_permission_service.dart';

/// Permission service implementation.
class PermissionService implements IPermissionService {
  static const MethodChannel _systemSettingsChannel = MethodChannel(
    'com.calcitem.gridtimer/system_settings',
  );

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
    // app_settings is only available on Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    }
  }

  @override
  Future<void> openNotificationChannelSettings({
    required String channelId,
  }) async {
    if (!Platform.isAndroid) return;
    assert(channelId.isNotEmpty, 'channelId must not be empty');

    await _systemSettingsChannel.invokeMethod<void>(
      'openNotificationChannelSettings',
      {'channelId': channelId},
    );
  }

  @override
  Future<void> openExactAlarmSettings() async {
    // app_settings is only available on Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await AppSettings.openAppSettings(type: AppSettingsType.alarm);
    }
  }

  @override
  Future<void> openFullScreenIntentSettings() async {
    // app_settings is only available on Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await AppSettings.openAppSettings();
    }
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    // app_settings is only available on Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await AppSettings.openAppSettings(
        type: AppSettingsType.batteryOptimization,
      );
    }
  }

  @override
  Future<void> openAppSettings() async {
    // app_settings is only available on Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await AppSettings.openAppSettings();
    }
  }

  @override
  Future<void> openTtsSettings() async {
    if (Platform.isAndroid) {
      try {
        await _systemSettingsChannel.invokeMethod<void>('openTtsSettings');
      } catch (e) {
        // Fallback to accessibility settings via app_settings
        await AppSettings.openAppSettings(type: AppSettingsType.accessibility);
      }
    } else if (Platform.isIOS) {
      // iOS doesn't have a direct TTS settings page, open accessibility
      await AppSettings.openAppSettings(type: AppSettingsType.accessibility);
    }
  }
}
