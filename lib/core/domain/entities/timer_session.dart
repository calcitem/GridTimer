import 'package:freezed_annotation/freezed_annotation.dart';
import '../types.dart';
import '../enums.dart';

part 'timer_session.freezed.dart';
part 'timer_session.g.dart';

/// Runtime state of a single timer instance.
@freezed
abstract class TimerSession with _$TimerSession {
  const factory TimerSession({
    /// Unique timer ID: "{modeId}:{slotIndex}"
    required TimerId timerId,

    /// Associated mode ID.
    required ModeId modeId,

    /// Slot index (0..8).
    required int slotIndex,

    /// Current timer status.
    required TimerStatus status,

    /// Epoch milliseconds (UTC) when timer was started.
    /// Only meaningful when status is running.
    int? startedAtEpochMs,

    /// Epoch milliseconds (UTC) when timer should end.
    /// MUST exist when status is running.
    int? endAtEpochMs,

    /// Remaining milliseconds captured at pause time.
    /// Only meaningful when status is paused or ringing.
    int? remainingMsAtPause,

    /// Last update timestamp (for debugging/recovery).
    @Default(0) int lastUpdatedEpochMs,
  }) = _TimerSession;

  factory TimerSession.fromJson(Map<String, dynamic> json) =>
      _$TimerSessionFromJson(json);

  const TimerSession._();

  /// Calculate remaining time based on current clock time.
  /// Returns 0 if timer has ended or is not running.
  int calculateRemaining(int nowEpochMs) {
    if (status == TimerStatus.running && endAtEpochMs != null) {
      return (endAtEpochMs! - nowEpochMs).clamp(0, double.maxFinite.toInt());
    } else if (status == TimerStatus.paused || status == TimerStatus.ringing) {
      return remainingMsAtPause ?? 0;
    }
    return 0;
  }

  /// Check if timer should be ringing based on current time.
  bool shouldBeRinging(int nowEpochMs) {
    return status == TimerStatus.running &&
        endAtEpochMs != null &&
        nowEpochMs >= endAtEpochMs!;
  }
}
