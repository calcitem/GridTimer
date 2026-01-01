import 'dart:async';
import '../core/domain/entities/timer_grid_set.dart';
import '../core/domain/entities/app_settings.dart';
import '../core/domain/services/i_mode_service.dart';
import '../core/domain/types.dart';
import '../data/repositories/storage_repository.dart';

/// Mode service implementation.
class ModeService implements IModeService {
  final StorageRepository _storage;

  final StreamController<List<TimerGridSet>> _allModesController =
      StreamController<List<TimerGridSet>>.broadcast();
  final StreamController<TimerGridSet> _activeModeController =
      StreamController<TimerGridSet>.broadcast();

  List<TimerGridSet> _modes = [];
  TimerGridSet? _activeMode;

  ModeService({required StorageRepository storage}) : _storage = storage;

  @override
  Future<void> init() async {
    await _storage.init();

    _modes = await _storage.getAllModes();

    // Load active mode from settings
    final settings = await _storage.getSettings();
    final activeModeId = settings?.activeModeId ?? 'default';

    _activeMode = _modes.firstWhere(
      (m) => m.modeId == activeModeId,
      orElse: () => _modes.first,
    );

    _emitStates();
  }

  @override
  Stream<List<TimerGridSet>> watchAllModes() => _allModesController.stream;

  @override
  Stream<TimerGridSet> watchActiveMode() => _activeModeController.stream;

  @override
  Future<List<TimerGridSet>> listModes() async {
    return _modes;
  }

  @override
  Future<TimerGridSet> getActiveMode() async {
    return _activeMode!;
  }

  @override
  Future<void> createMode(TimerGridSet gridSet) async {
    await _storage.saveMode(gridSet);
    _modes.add(gridSet);
    _emitStates();
  }

  @override
  Future<void> updateMode(TimerGridSet gridSet) async {
    await _storage.saveMode(gridSet);
    final index = _modes.indexWhere((m) => m.modeId == gridSet.modeId);
    if (index != -1) {
      _modes[index] = gridSet;
    }
    if (_activeMode?.modeId == gridSet.modeId) {
      _activeMode = gridSet;
    }
    _emitStates();
  }

  @override
  Future<void> deleteMode(ModeId modeId) async {
    if (_modes.length <= 1) {
      throw Exception('Cannot delete the last mode');
    }

    await _storage.deleteMode(modeId);
    _modes.removeWhere((m) => m.modeId == modeId);

    if (_activeMode?.modeId == modeId) {
      _activeMode = _modes.first;
      await _updateActiveModeInSettings(_activeMode!.modeId);
    }

    _emitStates();
  }

  @override
  Future<void> setActiveMode(ModeId modeId) async {
    final mode = _modes.firstWhere((m) => m.modeId == modeId);
    _activeMode = mode;
    await _updateActiveModeInSettings(modeId);
    _emitStates();
  }

  Future<void> _updateActiveModeInSettings(ModeId modeId) async {
    final settings = await _storage.getSettings() ??
        AppSettings(activeModeId: modeId);
    await _storage.saveSettings(settings.copyWith(activeModeId: modeId));
  }

  void _emitStates() {
    _allModesController.add(_modes);
    if (_activeMode != null) {
      _activeModeController.add(_activeMode!);
    }
  }

  void dispose() {
    _allModesController.close();
    _activeModeController.close();
  }
}




