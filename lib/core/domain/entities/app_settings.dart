import 'package:freezed_annotation/freezed_annotation.dart';
import '../types.dart';
import '../enums.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Global application settings.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// Currently active mode ID.
    required ModeId activeModeId,

    /// Whether red flash animation is enabled when ringing.
    @Default(true) bool flashEnabled,

    /// Global TTS enable/disable.
    @Default(true) bool ttsGlobalEnabled,

    /// Keep screen on while any timer is running.
    @Default(false) bool keepScreenOnWhileRunning,

    /// Whether alarm reliability hint has been dismissed.
    @Default(false) bool alarmReliabilityHintDismissed,

    /// Whether vibration is enabled.
    @Default(false) bool vibrationEnabled,

    /// Whether the onboarding permission wizard has been completed.
    @Default(false) bool onboardingCompleted,

    /// Sound volume (0.0 - 1.0).
    @Default(1.0) double soundVolume,

    /// Selected sound key for alarm.
    @Default('default') String selectedSoundKey,

    /// TTS volume (0.0 - 1.0).
    @Default(1.0) double ttsVolume,

    /// TTS speech rate (0.0 - 1.0, where 0.5 is normal).
    @Default(0.5) double ttsSpeechRate,

    /// TTS pitch (0.5 - 2.0, where 1.0 is normal).
    @Default(1.0) double ttsPitch,

    /// Grid custom duration configuration (in seconds), 9 elements for 9 grid slots
    /// Default values: [10s, 2min, 3min, 5min, 8min, 10min, 15min, 20min, 45min]
    @Default([10, 120, 180, 300, 480, 600, 900, 1200, 2700])
    List<int> gridDurationsInSeconds,

    /// Audio playback mode for alarm.
    @Default(AudioPlaybackMode.loopIndefinitely)
    AudioPlaybackMode audioPlaybackMode,

    /// Duration to loop audio in minutes (for loopForDuration, loopWithInterval modes).
    @Default(5) int audioLoopDurationMinutes,

    /// Interval pause duration in minutes (for loopWithInterval modes).
    @Default(2) int audioIntervalPauseMinutes,

    /// Custom audio file path (null means use default sound).
    String? customAudioPath,

    /// Gesture actions map: which action to take for each gesture type.
    @Default({
      AlarmGestureType.screenTap: AlarmGestureAction.stopAndReset,
      AlarmGestureType.volumeUp: AlarmGestureAction.stopAndReset,
      AlarmGestureType.volumeDown: AlarmGestureAction.stopAndReset,
      AlarmGestureType.shake: AlarmGestureAction.none,
      AlarmGestureType.flip: AlarmGestureAction.none,
    })
    Map<AlarmGestureType, AlarmGestureAction> gestureActions,

    /// Shake sensitivity threshold (1.0 - 5.0, lower = more sensitive).
    @Default(2.5) double shakeSensitivity,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
