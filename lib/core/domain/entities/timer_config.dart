import 'package:freezed_annotation/freezed_annotation.dart';
import '../types.dart';

part 'timer_config.freezed.dart';
part 'timer_config.g.dart';

/// Configuration for a single timer slot in the grid.
@freezed
abstract class TimerConfig with _$TimerConfig {
  const factory TimerConfig({
    /// Slot index in the grid (0..8).
    required int slotIndex,

    /// Display name (localized or user-defined).
    required String name,

    /// Preset duration in milliseconds.
    required int presetDurationMs,

    /// Sound key for ringtone.
    required SoundKey soundKey,

    /// Whether TTS announcement is enabled for this timer.
    @Default(true) bool ttsEnabled,
  }) = _TimerConfig;

  factory TimerConfig.fromJson(Map<String, dynamic> json) =>
      _$TimerConfigFromJson(json);

  const TimerConfig._();

  /// Get preset duration as Duration object.
  Duration get presetDuration => Duration(milliseconds: presetDurationMs);
}



