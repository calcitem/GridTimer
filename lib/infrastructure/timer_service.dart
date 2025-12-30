import 'dart:async';
import '../core/domain/entities/timer_config.dart';
import '../core/domain/entities/timer_grid_set.dart';
import '../core/domain/entities/timer_session.dart';
import '../core/domain/enums.dart';
import '../core/domain/services/i_timer_service.dart';
import '../core/domain/services/i_notification_service.dart';
import '../core/domain/services/i_audio_service.dart';
import '../core/domain/services/i_tts_service.dart';
import '../core/domain/services/i_clock.dart';
import '../core/domain/types.dart';
import '../data/repositories/storage_repository.dart';

/// Timer service implementation with full state management and recovery.
class TimerService implements ITimerService {
  final StorageRepository _storage;
  final INotificationService _notification;
  final IAudioService _audio;
  final ITtsService _tts;
  final IClock _clock;

  TimerGridSet? _currentGrid;
  final Map<TimerId, TimerSession> _sessions = {};

  /// 用于防止重复触发响铃的锁
  final Set<TimerId> _pendingRinging = {};

  final StreamController<(TimerGridSet, List<TimerSession>)> _stateController =
      StreamController<(TimerGridSet, List<TimerSession>)>.broadcast();

  Timer? _uiRefreshTimer;

  TimerService({
    required StorageRepository storage,
    required INotificationService notification,
    required IAudioService audio,
    required ITtsService tts,
    required IClock clock,
  }) : _storage = storage,
       _notification = notification,
       _audio = audio,
       _tts = tts,
       _clock = clock;

  @override
  Future<void> init() async {
    await _storage.init();

    // Load active mode
    final settings = await _storage.getSettings();
    final activeModeId = settings?.activeModeId ?? 'default';

    _currentGrid = await _storage.getMode(activeModeId);
    if (_currentGrid == null) {
      // Create default mode
      _currentGrid = _createDefaultGrid();
      await _storage.saveMode(_currentGrid!);
    }

    // 清理旧的 session 数据，重新初始化为 idle 状态
    // 避免启动时因为脏数据导致的问题
    await _storage.clearAllSessions();
    _initializeIdleSessions();

    // Start UI refresh timer
    _uiRefreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkActiveTimers();
      _emitState();
    });

    _emitState();
  }

  void _checkActiveTimers() {
    if (_currentGrid == null) return;

    final nowMs = _clock.nowEpochMs();
    for (final entry in _sessions.entries.toList()) {
      final session = entry.value;
      final timerId = entry.key;

      // 只处理状态为 RUNNING 且时间已到、且不在处理中的计时器
      if (session.status == TimerStatus.running &&
          session.shouldBeRinging(nowMs) &&
          !_pendingRinging.contains(timerId)) {
        // 加锁，防止重复触发
        _pendingRinging.add(timerId);

        // 立即同步更新内存中的状态为 ringing，避免下次检查时重复触发
        final updated = session.copyWith(
          status: TimerStatus.ringing,
          remainingMsAtPause: 0,
          lastUpdatedEpochMs: nowMs,
        );
        _sessions[timerId] = updated;

        // 异步执行响铃逻辑（保存状态、播放声音）
        _triggerRingingAsync(timerId, session.slotIndex);
      }
    }
  }

  Future<void> _triggerRingingAsync(TimerId timerId, int slotIndex) async {
    try {
      final session = _sessions[timerId];
      if (session == null) return;

      // 保存状态到存储
      await _storage.saveSession(session);

      // 加载设置以获取音量参数
      final settings = await _storage.getSettings();

      // 播放声音和 TTS
      final config = _currentGrid!.slots[slotIndex];
      final soundVolume = settings?.soundVolume ?? 1.0;
      await _audio.playLoop(soundKey: config.soundKey, volume: soundVolume);

      if (config.ttsEnabled && (settings?.ttsGlobalEnabled ?? true)) {
        final ttsVolume = settings?.ttsVolume ?? 1.0;
        final ttsSpeechRate = settings?.ttsSpeechRate ?? 0.5;
        final ttsPitch = settings?.ttsPitch ?? 1.0;

        await _tts.setVolume(ttsVolume);
        await _tts.setSpeechRate(ttsSpeechRate);
        await _tts.setPitch(ttsPitch);

        await _tts.speak(
          text: '${config.name} time is up',
          localeTag: 'en-US',
          interrupt: true,
        );
      }
    } finally {
      // 释放锁
      _pendingRinging.remove(timerId);
    }
  }

  @override
  Stream<(TimerGridSet, List<TimerSession>)> watchGridState() {
    return _stateController.stream;
  }

  @override
  (TimerGridSet, List<TimerSession>) getSnapshot() {
    final sessions = List<TimerSession>.from(_sessions.values);
    sessions.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    return (_currentGrid!, sessions);
  }

  @override
  Future<void> start({required ModeId modeId, required int slotIndex}) async {
    final timerId = '$modeId:$slotIndex';
    final config = _currentGrid!.slots[slotIndex];
    final nowMs = _clock.nowEpochMs();
    final endMs = nowMs + config.presetDurationMs;

    final session = TimerSession(
      timerId: timerId,
      modeId: modeId,
      slotIndex: slotIndex,
      status: TimerStatus.running,
      startedAtEpochMs: nowMs,
      endAtEpochMs: endMs,
      lastUpdatedEpochMs: nowMs,
    );

    _sessions[timerId] = session;
    await _storage.saveSession(session);

    // Schedule notification
    await _notification.scheduleTimeUp(session: session, config: config);

    _emitState();
  }

  @override
  Future<void> pause(TimerId timerId) async {
    final session = _sessions[timerId];
    if (session == null || session.status != TimerStatus.running) return;

    final nowMs = _clock.nowEpochMs();
    final remaining = session.calculateRemaining(nowMs);

    final updated = session.copyWith(
      status: TimerStatus.paused,
      remainingMsAtPause: remaining,
      lastUpdatedEpochMs: nowMs,
    );

    _sessions[timerId] = updated;
    await _storage.saveSession(updated);
    await _notification.cancelTimeUp(
      timerId: timerId,
      slotIndex: session.slotIndex,
    );

    _emitState();
  }

  @override
  Future<void> resume(TimerId timerId) async {
    final session = _sessions[timerId];
    if (session == null || session.status != TimerStatus.paused) return;

    final nowMs = _clock.nowEpochMs();
    final remaining = session.remainingMsAtPause ?? 0;
    final newEndMs = nowMs + remaining;

    final updated = session.copyWith(
      status: TimerStatus.running,
      endAtEpochMs: newEndMs,
      lastUpdatedEpochMs: nowMs,
    );

    _sessions[timerId] = updated;
    await _storage.saveSession(updated);

    final config = _currentGrid!.slots[session.slotIndex];
    await _notification.scheduleTimeUp(session: updated, config: config);

    _emitState();
  }

  @override
  Future<void> reset(TimerId timerId) async {
    final session = _sessions[timerId];
    if (session == null) return;

    final nowMs = _clock.nowEpochMs();
    final updated = session.copyWith(
      status: TimerStatus.idle,
      startedAtEpochMs: null,
      endAtEpochMs: null,
      remainingMsAtPause: null,
      lastUpdatedEpochMs: nowMs,
    );

    _sessions[timerId] = updated;
    await _storage.saveSession(updated);
    await _notification.cancelTimeUp(
      timerId: timerId,
      slotIndex: session.slotIndex,
    );

    // Stop audio/TTS if ringing
    if (session.status == TimerStatus.ringing) {
      await _audio.stop();
      await _tts.stop();
    }

    _emitState();
  }

  @override
  Future<void> stopRinging(TimerId timerId) async {
    final session = _sessions[timerId];
    if (session == null || session.status != TimerStatus.ringing) return;

    await _audio.stop();
    await _tts.stop();

    await reset(timerId);
  }

  @override
  Future<void> switchMode(ModeId modeId) async {
    // Caller must ensure all timers are stopped
    final newGrid = await _storage.getMode(modeId);
    if (newGrid == null) return;

    // Clear all sessions
    await _notification.cancelAll();
    _currentGrid = newGrid;
    _initializeIdleSessions();

    _emitState();
  }

  @override
  Future<void> refreshFromClock() async {
    await _recoverSessions();
    _emitState();
  }

  @override
  Future<void> handleTimeUpEvent({
    required TimerId timerId,
    required int firedAtEpochMs,
  }) async {
    final session = _sessions[timerId];
    if (session == null) return;

    // 如果已经在响铃或处理中，跳过
    if (session.status == TimerStatus.ringing ||
        _pendingRinging.contains(timerId)) {
      return;
    }

    _pendingRinging.add(timerId);

    try {
      final nowMs = _clock.nowEpochMs();
      final updated = session.copyWith(
        status: TimerStatus.ringing,
        remainingMsAtPause: 0,
        lastUpdatedEpochMs: nowMs,
      );

      _sessions[timerId] = updated;
      await _storage.saveSession(updated);

      // 加载设置以获取音量参数
      final settings = await _storage.getSettings();

      // Play audio and TTS
      final config = _currentGrid!.slots[session.slotIndex];
      final soundVolume = settings?.soundVolume ?? 1.0;
      await _audio.playLoop(soundKey: config.soundKey, volume: soundVolume);

      if (config.ttsEnabled && (settings?.ttsGlobalEnabled ?? true)) {
        final ttsVolume = settings?.ttsVolume ?? 1.0;
        final ttsSpeechRate = settings?.ttsSpeechRate ?? 0.5;
        final ttsPitch = settings?.ttsPitch ?? 1.0;

        await _tts.setVolume(ttsVolume);
        await _tts.setSpeechRate(ttsSpeechRate);
        await _tts.setPitch(ttsPitch);

        await _tts.speak(
          text: '${config.name} time is up',
          localeTag: 'en-US',
          interrupt: true,
        );
      }

      _emitState();
    } finally {
      _pendingRinging.remove(timerId);
    }
  }

  @override
  bool hasActiveTimers() {
    return _sessions.values.any((s) => s.status != TimerStatus.idle);
  }

  Future<void> _recoverSessions() async {
    final nowMs = _clock.nowEpochMs();

    for (final session in _sessions.values.toList()) {
      if (session.status == TimerStatus.running) {
        if (session.shouldBeRinging(nowMs)) {
          // Should be ringing
          await handleTimeUpEvent(
            timerId: session.timerId,
            firedAtEpochMs: session.endAtEpochMs!,
          );
        } else {
          // Reschedule notification
          final config = _currentGrid!.slots[session.slotIndex];
          await _notification.scheduleTimeUp(session: session, config: config);
        }
      }
    }
  }

  void _initializeIdleSessions() {
    _sessions.clear();
    for (int i = 0; i < 9; i++) {
      final timerId = '${_currentGrid!.modeId}:$i';
      _sessions[timerId] = TimerSession(
        timerId: timerId,
        modeId: _currentGrid!.modeId,
        slotIndex: i,
        status: TimerStatus.idle,
        lastUpdatedEpochMs: _clock.nowEpochMs(),
      );
    }
  }

  void _emitState() {
    final sessions = List<TimerSession>.from(_sessions.values);
    sessions.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    _stateController.add((_currentGrid!, sessions));
  }

  TimerGridSet _createDefaultGrid() {
    // 默认时间配置：1, 2, 3, 5, 10, 15, 20, 45, 60 分钟
    const defaultDurations = [1, 2, 3, 5, 10, 15, 20, 45, 60];

    final configs = List.generate(9, (i) {
      final minutes = defaultDurations[i];
      return TimerConfig(
        slotIndex: i,
        name: '$minutes min',
        presetDurationMs: Duration(minutes: minutes).inMilliseconds,
        soundKey: 'default',
        ttsEnabled: true,
      );
    });

    return TimerGridSet(modeId: 'default', modeName: 'Default', slots: configs);
  }

  void dispose() {
    _uiRefreshTimer?.cancel();
    _stateController.close();
  }
}
