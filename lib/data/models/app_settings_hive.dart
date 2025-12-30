import 'package:hive_ce/hive.dart';
import '../../core/domain/entities/app_settings.dart';

part 'app_settings_hive.g.dart';

/// Hive adapter for AppSettings.
@HiveType(typeId: 4)
class AppSettingsHive {
  @HiveField(0)
  final String activeModeId;

  @HiveField(1)
  final bool flashEnabled;

  @HiveField(2)
  final bool ttsGlobalEnabled;

  @HiveField(3)
  final bool keepScreenOnWhileRunning;

  @HiveField(4)
  final bool alarmReliabilityHintDismissed;

  @HiveField(5)
  final bool vibrationEnabled;

  @HiveField(6)
  final bool onboardingCompleted;

  AppSettingsHive({
    required this.activeModeId,
    required this.flashEnabled,
    required this.ttsGlobalEnabled,
    required this.keepScreenOnWhileRunning,
    required this.alarmReliabilityHintDismissed,
    required this.vibrationEnabled,
    required this.onboardingCompleted,
  });

  /// Convert from domain entity.
  factory AppSettingsHive.fromDomain(AppSettings settings) {
    return AppSettingsHive(
      activeModeId: settings.activeModeId,
      flashEnabled: settings.flashEnabled,
      ttsGlobalEnabled: settings.ttsGlobalEnabled,
      keepScreenOnWhileRunning: settings.keepScreenOnWhileRunning,
      alarmReliabilityHintDismissed: settings.alarmReliabilityHintDismissed,
      vibrationEnabled: settings.vibrationEnabled,
      onboardingCompleted: settings.onboardingCompleted,
    );
  }

  /// Convert to domain entity.
  AppSettings toDomain() {
    return AppSettings(
      activeModeId: activeModeId,
      flashEnabled: flashEnabled,
      ttsGlobalEnabled: ttsGlobalEnabled,
      keepScreenOnWhileRunning: keepScreenOnWhileRunning,
      alarmReliabilityHintDismissed: alarmReliabilityHintDismissed,
      vibrationEnabled: vibrationEnabled,
      onboardingCompleted: onboardingCompleted,
    );
  }
}

