import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/domain/enums.dart';
import '../core/domain/services/i_alarm_volume_service.dart';

/// Android alarm volume service implementation via platform channel.
///
/// This uses AlarmManager + a native BroadcastReceiver to boost alarm volume at
/// the exact ringing time, even on the lock screen.
class AlarmVolumeService implements IAlarmVolumeService {
  static const MethodChannel _channel = MethodChannel(
    'com.calcitem.gridtimer/system_settings',
  );

  static int _boostRequestCode(int slotIndex) => 2000 + slotIndex;

  @override
  Future<void> scheduleBoost({
    required int slotIndex,
    required int triggerAtEpochMs,
    required AlarmVolumeBoostLevel level,
    required int restoreAfterMinutes,
  }) async {
    if (!Platform.isAndroid) return;
    assert(slotIndex >= 0 && slotIndex < 9, 'slotIndex must be in [0, 8]');
    assert(triggerAtEpochMs > 0, 'triggerAtEpochMs must be > 0');
    assert(restoreAfterMinutes > 0, 'restoreAfterMinutes must be > 0');

    // Schedule slightly before the notification to increase the chance that the
    // alarm stream volume is already boosted when sound starts.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final triggerMs = (triggerAtEpochMs - 500).clamp(nowMs, triggerAtEpochMs);

    try {
      await _channel.invokeMethod<void>(
        'scheduleAlarmVolumeBoost',
        <String, dynamic>{
          'requestCode': _boostRequestCode(slotIndex),
          'triggerAtEpochMs': triggerMs,
          'level': level.name,
          'restoreAfterMinutes': restoreAfterMinutes,
        },
      );
    } catch (e, st) {
      debugPrint('AlarmVolumeService: scheduleBoost failed: $e');
      debugPrint('Stack trace: $st');
    }
  }

  @override
  Future<void> cancelScheduledBoost({required int slotIndex}) async {
    if (!Platform.isAndroid) return;
    assert(slotIndex >= 0 && slotIndex < 9, 'slotIndex must be in [0, 8]');

    try {
      await _channel.invokeMethod<void>(
        'cancelAlarmVolumeBoost',
        <String, dynamic>{
          'requestCode': _boostRequestCode(slotIndex),
        },
      );
    } catch (e, st) {
      debugPrint('AlarmVolumeService: cancelScheduledBoost failed: $e');
      debugPrint('Stack trace: $st');
    }
  }

  @override
  Future<void> boostNow({
    required AlarmVolumeBoostLevel level,
    required int restoreAfterMinutes,
  }) async {
    if (!Platform.isAndroid) return;
    assert(restoreAfterMinutes > 0, 'restoreAfterMinutes must be > 0');

    try {
      await _channel.invokeMethod<void>(
        'boostAlarmVolumeNow',
        <String, dynamic>{
          'level': level.name,
          'restoreAfterMinutes': restoreAfterMinutes,
        },
      );
    } catch (e, st) {
      debugPrint('AlarmVolumeService: boostNow failed: $e');
      debugPrint('Stack trace: $st');
    }
  }

  @override
  Future<void> restoreIfBoosted() async {
    if (!Platform.isAndroid) return;
    try {
      final activeCount = await _channel.invokeMethod<int>(
        'getActiveTimeUpNotificationCount',
      );
      // If we can't determine, assume safe to restore.
      final hasActiveTimeUp = (activeCount ?? 0) > 0;
      if (hasActiveTimeUp) return;

      await _channel.invokeMethod<void>('restoreAlarmVolumeNow');
    } catch (e, st) {
      debugPrint('AlarmVolumeService: restoreIfBoosted failed: $e');
      debugPrint('Stack trace: $st');
    }
  }
}


