import 'package:hive_ce/hive.dart';
import '../../core/domain/entities/timer_config.dart';

part 'timer_config_hive.g.dart';

/// Hive adapter for TimerConfig.
@HiveType(typeId: 1)
class TimerConfigHive {
  @HiveField(0)
  final int slotIndex;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int presetDurationMs;

  @HiveField(3)
  final String soundKey;

  @HiveField(4)
  final bool ttsEnabled;

  TimerConfigHive({
    required this.slotIndex,
    required this.name,
    required this.presetDurationMs,
    required this.soundKey,
    required this.ttsEnabled,
  });

  /// Convert from domain entity.
  factory TimerConfigHive.fromDomain(TimerConfig config) {
    return TimerConfigHive(
      slotIndex: config.slotIndex,
      name: config.name,
      presetDurationMs: config.presetDurationMs,
      soundKey: config.soundKey,
      ttsEnabled: config.ttsEnabled,
    );
  }

  /// Convert to domain entity.
  TimerConfig toDomain() {
    return TimerConfig(
      slotIndex: slotIndex,
      name: name,
      presetDurationMs: presetDurationMs,
      soundKey: soundKey,
      ttsEnabled: ttsEnabled,
    );
  }
}

