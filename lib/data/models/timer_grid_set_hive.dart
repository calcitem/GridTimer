import 'package:hive_ce/hive.dart';
import '../../core/domain/entities/timer_grid_set.dart';
import 'timer_config_hive.dart';

part 'timer_grid_set_hive.g.dart';

/// Hive adapter for TimerGridSet (Mode).
@HiveType(typeId: 2)
class TimerGridSetHive {
  @HiveField(0)
  final String modeId;

  @HiveField(1)
  final String modeName;

  @HiveField(2)
  final List<TimerConfigHive> slots;

  TimerGridSetHive({
    required this.modeId,
    required this.modeName,
    required this.slots,
  });

  /// Convert from domain entity.
  factory TimerGridSetHive.fromDomain(TimerGridSet gridSet) {
    return TimerGridSetHive(
      modeId: gridSet.modeId,
      modeName: gridSet.modeName,
      slots: gridSet.slots.map((c) => TimerConfigHive.fromDomain(c)).toList(),
    );
  }

  /// Convert to domain entity.
  TimerGridSet toDomain() {
    return TimerGridSet(
      modeId: modeId,
      modeName: modeName,
      slots: slots.map((c) => c.toDomain()).toList(),
    );
  }
}



