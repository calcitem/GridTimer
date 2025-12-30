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
    @Default(true) bool vibrationEnabled,

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

    /// 九宫格的自定义时长配置（单位：秒），9个元素分别对应9个宫格
    /// 默认值：[10秒, 2分, 3分, 5分, 8分, 10分, 15分, 20分, 45分]
    @Default([10, 120, 180, 300, 480, 600, 900, 1200, 2700])
    List<int> gridDurationsInSeconds,

    /// Audio playback mode for alarm.
    @Default(AudioPlaybackMode.loopIndefinitely)
    AudioPlaybackMode audioPlaybackMode,

    /// Duration to loop audio in minutes (for loopForDuration, loopWithInterval modes).
    @Default(5) int audioLoopDurationMinutes,

    /// Interval pause duration in minutes (for loopWithInterval modes).
    @Default(2) int audioIntervalPauseMinutes,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
