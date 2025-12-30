import '../entities/timer_grid_set.dart';
import '../entities/timer_session.dart';
import '../types.dart';

/// Core timer service interface for business logic.
/// 
/// This service orchestrates timer lifecycle, persistence, and recovery.
abstract interface class ITimerService {
  /// Initializes storage, loads last sessions, and performs recovery.
  Future<void> init();

  /// Emits the active grid set (mode) and all 9 sessions.
  Stream<(TimerGridSet grid, List<TimerSession> sessions)> watchGridState();

  /// Returns current snapshot synchronously (for cold start UI).
  (TimerGridSet grid, List<TimerSession> sessions) getSnapshot();

  /// Starts a timer for the given slot.
  /// 
  /// Note: Caller (UI) must enforce "start protection" 
  /// (confirm when other timers are running).
  Future<void> start({
    required ModeId modeId,
    required int slotIndex,
  });

  /// Pauses a running timer.
  Future<void> pause(TimerId timerId);

  /// Resumes a paused timer.
  Future<void> resume(TimerId timerId);

  /// Resets a timer back to idle.
  Future<void> reset(TimerId timerId);

  /// Stops ringing and transitions to idle.
  Future<void> stopRinging(TimerId timerId);

  /// Switches mode. Caller must confirm when any timer is running.
  Future<void> switchMode(ModeId modeId);

  /// Force recompute remaining time from system clock (e.g., app resume).
  Future<void> refreshFromClock();

  /// Called when a scheduled "time up" event is received via notification.
  Future<void> handleTimeUpEvent({
    required TimerId timerId,
    required int firedAtEpochMs,
  });
  
  /// Returns whether any timer is not idle.
  bool hasActiveTimers();

  /// Updates default grid durations from settings.
  /// Throws if any timer is active.
  Future<void> updateDefaultGridDurations();
}



