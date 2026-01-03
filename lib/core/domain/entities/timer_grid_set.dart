import 'package:freezed_annotation/freezed_annotation.dart';
import '../types.dart';
import 'timer_config.dart';

part 'timer_grid_set.freezed.dart';
part 'timer_grid_set.g.dart';

/// A mode containing 9 timer configurations (3x3 grid).
@freezed
abstract class TimerGridSet with _$TimerGridSet {
  const factory TimerGridSet({
    /// Unique mode identifier.
    required ModeId modeId,

    /// Mode display name.
    required String modeName,

    /// Exactly 9 timer configurations (ordered by slot index).
    required List<TimerConfig> slots,
  }) = _TimerGridSet;

  factory TimerGridSet.fromJson(Map<String, dynamic> json) =>
      _$TimerGridSetFromJson(json);

  const TimerGridSet._();

  /// Validate that slots length is exactly 9.
  bool get isValid => slots.length == 9;
}
