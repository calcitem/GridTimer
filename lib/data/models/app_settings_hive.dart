import 'package:hive_ce/hive.dart';
import '../../core/domain/entities/app_settings.dart';
import '../../core/domain/enums.dart';

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

  @HiveField(7, defaultValue: 1.0)
  final double soundVolume;

  @HiveField(8, defaultValue: 'default')
  final String selectedSoundKey;

  @HiveField(9, defaultValue: 1.0)
  final double ttsVolume;

  @HiveField(10, defaultValue: 0.5)
  final double ttsSpeechRate;

  @HiveField(11, defaultValue: 1.0)
  final double ttsPitch;

  @HiveField(12, defaultValue: [10, 120, 180, 300, 480, 600, 900, 1200, 2700])
  final List<int> gridDurationsInSeconds;

  @HiveField(13, defaultValue: 0)
  final int audioPlaybackModeIndex;

  @HiveField(14, defaultValue: 5)
  final int audioLoopDurationMinutes;

  @HiveField(15, defaultValue: 2)
  final int audioIntervalPauseMinutes;

  @HiveField(16)
  final String? customAudioPath;

  AppSettingsHive({
    required this.activeModeId,
    required this.flashEnabled,
    required this.ttsGlobalEnabled,
    required this.keepScreenOnWhileRunning,
    required this.alarmReliabilityHintDismissed,
    required this.vibrationEnabled,
    required this.onboardingCompleted,
    required this.soundVolume,
    required this.selectedSoundKey,
    required this.ttsVolume,
    required this.ttsSpeechRate,
    required this.ttsPitch,
    required this.gridDurationsInSeconds,
    required this.audioPlaybackModeIndex,
    required this.audioLoopDurationMinutes,
    required this.audioIntervalPauseMinutes,
    this.customAudioPath,
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
      soundVolume: settings.soundVolume,
      selectedSoundKey: settings.selectedSoundKey,
      ttsVolume: settings.ttsVolume,
      ttsSpeechRate: settings.ttsSpeechRate,
      ttsPitch: settings.ttsPitch,
      gridDurationsInSeconds: settings.gridDurationsInSeconds,
      audioPlaybackModeIndex: settings.audioPlaybackMode.index,
      audioLoopDurationMinutes: settings.audioLoopDurationMinutes,
      audioIntervalPauseMinutes: settings.audioIntervalPauseMinutes,
      customAudioPath: settings.customAudioPath,
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
      soundVolume: soundVolume,
      selectedSoundKey: selectedSoundKey,
      ttsVolume: ttsVolume,
      ttsSpeechRate: ttsSpeechRate,
      ttsPitch: ttsPitch,
      gridDurationsInSeconds: gridDurationsInSeconds,
      audioPlaybackMode: AudioPlaybackMode.values[audioPlaybackModeIndex],
      audioLoopDurationMinutes: audioLoopDurationMinutes,
      audioIntervalPauseMinutes: audioIntervalPauseMinutes,
      customAudioPath: customAudioPath,
    );
  }
}



