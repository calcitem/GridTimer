import '../enums.dart';

/// Service for managing the Android system alarm stream volume.
///
/// This is used to temporarily boost the alarm volume when an alarm rings,
/// and restore the previous volume after the alarm is stopped.
abstract interface class IAlarmVolumeService {
  /// Schedules a one-shot volume boost at the given time.
  ///
  /// Implementations should be best-effort and no-op on unsupported platforms.
  Future<void> scheduleBoost({
    required int slotIndex,
    required int triggerAtEpochMs,
    required AlarmVolumeBoostLevel level,
    required int restoreAfterMinutes,
  });

  /// Cancels a previously scheduled boost for the given slot.
  Future<void> cancelScheduledBoost({required int slotIndex});

  /// Boosts alarm volume immediately (best-effort).
  Future<void> boostNow({
    required AlarmVolumeBoostLevel level,
    required int restoreAfterMinutes,
  });

  /// Restores the previously saved alarm volume (best-effort).
  ///
  /// Implementations may choose to restore only when no active time-up
  /// notifications remain, to avoid affecting other concurrently ringing timers.
  Future<void> restoreIfBoosted();
}


