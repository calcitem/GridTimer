import '../entities/timer_grid_set.dart';
import '../types.dart';

/// Mode (preset grid configuration) management service.
abstract interface class IModeService {
  Future<void> init();

  Stream<List<TimerGridSet>> watchAllModes();
  Stream<TimerGridSet> watchActiveMode();

  Future<List<TimerGridSet>> listModes();
  Future<TimerGridSet> getActiveMode();

  Future<void> createMode(TimerGridSet gridSet);
  Future<void> updateMode(TimerGridSet gridSet);
  Future<void> deleteMode(ModeId modeId);

  /// Caller must confirm if timers are running.
  Future<void> setActiveMode(ModeId modeId);
}


