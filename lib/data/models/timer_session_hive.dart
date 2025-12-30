import 'package:hive_ce/hive.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';

part 'timer_session_hive.g.dart';

/// Hive adapter for TimerSession.
@HiveType(typeId: 3)
class TimerSessionHive {
  @HiveField(0)
  final String timerId;

  @HiveField(1)
  final String modeId;

  @HiveField(2)
  final int slotIndex;

  @HiveField(3)
  final int statusIndex; // TimerStatus.index

  @HiveField(4)
  final int? startedAtEpochMs;

  @HiveField(5)
  final int? endAtEpochMs;

  @HiveField(6)
  final int? remainingMsAtPause;

  @HiveField(7)
  final int lastUpdatedEpochMs;

  TimerSessionHive({
    required this.timerId,
    required this.modeId,
    required this.slotIndex,
    required this.statusIndex,
    this.startedAtEpochMs,
    this.endAtEpochMs,
    this.remainingMsAtPause,
    required this.lastUpdatedEpochMs,
  });

  /// Convert from domain entity.
  factory TimerSessionHive.fromDomain(TimerSession session) {
    return TimerSessionHive(
      timerId: session.timerId,
      modeId: session.modeId,
      slotIndex: session.slotIndex,
      statusIndex: session.status.index,
      startedAtEpochMs: session.startedAtEpochMs,
      endAtEpochMs: session.endAtEpochMs,
      remainingMsAtPause: session.remainingMsAtPause,
      lastUpdatedEpochMs: session.lastUpdatedEpochMs,
    );
  }

  /// Convert to domain entity.
  TimerSession toDomain() {
    return TimerSession(
      timerId: timerId,
      modeId: modeId,
      slotIndex: slotIndex,
      status: TimerStatus.values[statusIndex],
      startedAtEpochMs: startedAtEpochMs,
      endAtEpochMs: endAtEpochMs,
      remainingMsAtPause: remainingMsAtPause,
      lastUpdatedEpochMs: lastUpdatedEpochMs,
    );
  }
}



