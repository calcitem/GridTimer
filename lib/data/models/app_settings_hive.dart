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

  @HiveField(5, defaultValue: false)
  final bool vibrationEnabled;

  @HiveField(6)
  final bool onboardingCompleted;

  @HiveField(16, defaultValue: false)
  final bool safetyDisclaimerAccepted;

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

  @HiveField(17, defaultValue: {
    0: 0, // screenTap -> stopAndReset
    1: 0, // volumeUp -> stopAndReset
    2: 0, // volumeDown -> stopAndReset
    3: 2, // shake -> none
    4: 2, // flip -> none
  })
  final Map<int, int> gestureActionsMap;

  @HiveField(18, defaultValue: 2.5)
  final double shakeSensitivity;

  @HiveField(19)
  final String? ttsLanguage;

  AppSettingsHive({
    required this.activeModeId,
    required this.flashEnabled,
    required this.ttsGlobalEnabled,
    required this.keepScreenOnWhileRunning,
    required this.alarmReliabilityHintDismissed,
    required this.vibrationEnabled,
    required this.onboardingCompleted,
    required this.safetyDisclaimerAccepted,
    required this.soundVolume,
    required this.selectedSoundKey,
    required this.ttsVolume,
    required this.ttsSpeechRate,
    required this.ttsPitch,
    required this.gridDurationsInSeconds,
    required this.audioPlaybackModeIndex,
    required this.audioLoopDurationMinutes,
    required this.audioIntervalPauseMinutes,
    required this.gestureActionsMap,
    required this.shakeSensitivity,
    this.ttsLanguage,
  });

  /// Convert from domain entity.
  factory AppSettingsHive.fromDomain(AppSettings settings) {
    // Convert enum map to int map for Hive storage
    final gestureActionsMap = <int, int>{};
    settings.gestureActions.forEach((gesture, action) {
      gestureActionsMap[gesture.index] = action.index;
    });

    return AppSettingsHive(
      activeModeId: settings.activeModeId,
      flashEnabled: settings.flashEnabled,
      ttsGlobalEnabled: settings.ttsGlobalEnabled,
      keepScreenOnWhileRunning: settings.keepScreenOnWhileRunning,
      alarmReliabilityHintDismissed: settings.alarmReliabilityHintDismissed,
      vibrationEnabled: settings.vibrationEnabled,
      onboardingCompleted: settings.onboardingCompleted,
      safetyDisclaimerAccepted: settings.safetyDisclaimerAccepted,
      soundVolume: settings.soundVolume,
      selectedSoundKey: settings.selectedSoundKey,
      ttsVolume: settings.ttsVolume,
      ttsSpeechRate: settings.ttsSpeechRate,
      ttsPitch: settings.ttsPitch,
      gridDurationsInSeconds: settings.gridDurationsInSeconds,
      audioPlaybackModeIndex: settings.audioPlaybackMode.index,
      audioLoopDurationMinutes: settings.audioLoopDurationMinutes,
      audioIntervalPauseMinutes: settings.audioIntervalPauseMinutes,
      gestureActionsMap: gestureActionsMap,
      shakeSensitivity: settings.shakeSensitivity,
      ttsLanguage: settings.ttsLanguage,
    );
  }

  /// Convert to domain entity.
  AppSettings toDomain() {
    // Convert int map back to enum map
    final gestureActions = <AlarmGestureType, AlarmGestureAction>{};
    gestureActionsMap.forEach((gestureIndex, actionIndex) {
      if (gestureIndex >= 0 && gestureIndex < AlarmGestureType.values.length &&
          actionIndex >= 0 && actionIndex < AlarmGestureAction.values.length) {
        gestureActions[AlarmGestureType.values[gestureIndex]] =
            AlarmGestureAction.values[actionIndex];
      }
    });

    return AppSettings(
      activeModeId: activeModeId,
      flashEnabled: flashEnabled,
      ttsGlobalEnabled: ttsGlobalEnabled,
      keepScreenOnWhileRunning: keepScreenOnWhileRunning,
      alarmReliabilityHintDismissed: alarmReliabilityHintDismissed,
      vibrationEnabled: vibrationEnabled,
      onboardingCompleted: onboardingCompleted,
      safetyDisclaimerAccepted: safetyDisclaimerAccepted,
      soundVolume: soundVolume,
      selectedSoundKey: selectedSoundKey,
      ttsVolume: ttsVolume,
      ttsSpeechRate: ttsSpeechRate,
      ttsPitch: ttsPitch,
      gridDurationsInSeconds: gridDurationsInSeconds,
      audioPlaybackMode: AudioPlaybackMode.values[audioPlaybackModeIndex],
      audioLoopDurationMinutes: audioLoopDurationMinutes,
      audioIntervalPauseMinutes: audioIntervalPauseMinutes,
      gestureActions: gestureActions,
      shakeSensitivity: shakeSensitivity,
      ttsLanguage: ttsLanguage,
    );
  }
}



