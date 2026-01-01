import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../core/config/environment_config.dart';
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
    // Block opening system settings in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint('Opening notification settings blocked in test environment');
      return;
    }

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

    // Block opening system settings in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint(
        'Opening notification channel settings blocked in test environment',
      );
      return;
    }

    await _systemSettingsChannel.invokeMethod<void>(
      'openNotificationChannelSettings',
      {'channelId': channelId},
    );
  }

  @override
  Future<void> openExactAlarmSettings() async {
    // Block opening system settings in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint('Opening exact alarm settings blocked in test environment');
      return;
    }

    // app_settings is only available on Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await AppSettings.openAppSettings(type: AppSettingsType.alarm);
    }
  }

  @override
  Future<void> openFullScreenIntentSettings() async {
    // Block opening system settings in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint(
        'Opening full screen intent settings blocked in test environment',
      );
      return;
    }

    // app_settings is only available on Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await AppSettings.openAppSettings();
    }
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    // Block opening system settings in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint(
        'Opening battery optimization settings blocked in test environment',
      );
      return;
    }

    if (Platform.isAndroid) {
      // Use native implementation for better MIUI/OEM compatibility
      try {
        await _systemSettingsChannel.invokeMethod<void>(
          'openBatteryOptimizationSettings',
        );
      } catch (e) {
        // Fallback to app_settings if native method fails
        debugPrint(
          'Native openBatteryOptimizationSettings failed, using fallback: $e',
        );
        await AppSettings.openAppSettings(
          type: AppSettingsType.batteryOptimization,
        );
      }
    } else if (Platform.isIOS) {
      await AppSettings.openAppSettings(
        type: AppSettingsType.batteryOptimization,
      );
    }
  }

  @override
  Future<bool?> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _systemSettingsChannel.invokeMethod<bool?>(
        'isIgnoringBatteryOptimizations',
      );
      // Result can be: true (disabled), false (enabled), or null (unknown/MIUI)
      return result;
    } catch (e) {
      // If we can't determine, return null to indicate unknown
      return null;
    }
  }

  @override
  Future<bool> isMiuiDevice() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _systemSettingsChannel.invokeMethod<bool>(
        'isMiuiDevice',
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> openAppSettings() async {
    // Block opening system settings in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint('Opening app settings blocked in test environment');
      return;
    }

    // app_settings is only available on Android and iOS
    if (Platform.isAndroid || Platform.isIOS) {
      await AppSettings.openAppSettings();
    }
  }

  @override
  Future<void> openTtsSettings() async {
    // Block opening system settings in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint('Opening TTS settings blocked in test environment');
      return;
    }

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
    // Windows/macOS/Linux: No reliable way to open TTS settings
    // Do nothing - the UI should hide this option on desktop platforms
  }

  @override
  bool get canOpenTtsSettings => Platform.isAndroid || Platform.isIOS;
}
