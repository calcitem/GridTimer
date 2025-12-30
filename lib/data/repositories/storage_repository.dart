import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/domain/entities/timer_grid_set.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/entities/app_settings.dart';
import '../../core/domain/types.dart';
import '../models/timer_grid_set_hive.dart';
import '../models/timer_session_hive.dart';
import '../models/app_settings_hive.dart';

/// Storage repository using Hive for persistence.
class StorageRepository {
  static const String _boxModes = 'box_modes';
  static const String _boxSessions = 'box_sessions';
  static const String _boxSettings = 'box_settings';
  static const String _keySettings = 'app_settings';

  Box<TimerGridSetHive>? _modesBox;
  Box<TimerSessionHive>? _sessionsBox;
  Box<AppSettingsHive>? _settingsBox;

  /// Initialize Hive and open boxes.
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TimerConfigHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TimerGridSetHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TimerSessionHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AppSettingsHiveAdapter());
    }

    // Open boxes
    _modesBox = await Hive.openBox<TimerGridSetHive>(_boxModes);
    _sessionsBox = await Hive.openBox<TimerSessionHive>(_boxSessions);
    _settingsBox = await Hive.openBox<AppSettingsHive>(_boxSettings);
  }

  // ========== Modes ==========

  Future<List<TimerGridSet>> getAllModes() async {
    final box = _modesBox!;
    return box.values.map((h) => h.toDomain()).toList();
  }

  Future<TimerGridSet?> getMode(ModeId modeId) async {
    final box = _modesBox!;
    final hive = box.get(modeId);
    return hive?.toDomain();
  }

  Future<void> saveMode(TimerGridSet gridSet) async {
    final box = _modesBox!;
    await box.put(gridSet.modeId, TimerGridSetHive.fromDomain(gridSet));
  }

  Future<void> deleteMode(ModeId modeId) async {
    final box = _modesBox!;
    await box.delete(modeId);
  }

  // ========== Sessions ==========

  Future<List<TimerSession>> getAllSessions() async {
    final box = _sessionsBox!;
    return box.values.map((h) => h.toDomain()).toList();
  }

  Future<TimerSession?> getSession(TimerId timerId) async {
    final box = _sessionsBox!;
    final hive = box.get(timerId);
    return hive?.toDomain();
  }

  Future<void> saveSession(TimerSession session) async {
    final box = _sessionsBox!;
    await box.put(session.timerId, TimerSessionHive.fromDomain(session));
  }

  Future<void> deleteSession(TimerId timerId) async {
    final box = _sessionsBox!;
    await box.delete(timerId);
  }

  Future<void> clearAllSessions() async {
    final box = _sessionsBox!;
    await box.clear();
  }

  // ========== Settings ==========

  Future<AppSettings?> getSettings() async {
    final box = _settingsBox!;
    final hive = box.get(_keySettings);
    return hive?.toDomain();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final box = _settingsBox!;
    await box.put(_keySettings, AppSettingsHive.fromDomain(settings));
  }
}


