import 'dart:async';
import '../core/domain/entities/app_settings.dart';
import '../core/domain/entities/timer_config.dart';
import '../core/domain/entities/timer_grid_set.dart';
import '../core/domain/entities/timer_session.dart';
import '../core/domain/enums.dart';
import '../core/domain/services/i_timer_service.dart';
import '../core/domain/services/i_notification_service.dart';
import '../core/domain/services/i_audio_service.dart';
import '../core/domain/services/i_tts_service.dart';
import '../core/domain/services/i_clock.dart';
import '../core/domain/services/i_gesture_service.dart';
import '../core/domain/types.dart';
import '../data/repositories/storage_repository.dart';

/// Timer service implementation with full state management and recovery.
class TimerService implements ITimerService {
  final StorageRepository _storage;
  final INotificationService _notification;
  final IAudioService _audio;
  final ITtsService _tts;
  final IClock _clock;
  final IGestureService _gesture;

  TimerGridSet? _currentGrid;
  final Map<TimerId, TimerSession> _sessions = {};

  /// Set of timer IDs that are currently ringing
  final Set<TimerId> _ringingTimers = {};

  /// Lock to prevent duplicate ringing triggers
  final Set<TimerId> _pendingRinging = {};

  /// Gesture subscription
  StreamSubscription<AlarmGestureType>? _gestureSubscription;

  final StreamController<(TimerGridSet, List<TimerSession>)> _stateController =
      StreamController<(TimerGridSet, List<TimerSession>)>.broadcast();

  Timer? _uiRefreshTimer;

  TimerService({
    required StorageRepository storage,
    required INotificationService notification,
    required IAudioService audio,
    required ITtsService tts,
    required IClock clock,
    required IGestureService gesture,
  }) : _storage = storage,
       _notification = notification,
       _audio = audio,
       _tts = tts,
       _clock = clock,
       _gesture = gesture;

  bool _initialized = false;

  @override
  Future<void> init() async {
    // Prevent double initialization
    if (_initialized) return;
    _initialized = true;

    await _storage.init();

    // Initialize gesture service
    await _gesture.init();

    // Listen for gesture events
    _gestureSubscription = _gesture.gestureStream.listen(_onGestureDetected);

    // Load active mode
    final settings = await _storage.getSettings();
    final activeModeId = settings?.activeModeId ?? 'default';

    _currentGrid = await _storage.getMode(activeModeId);
    if (_currentGrid == null) {
      // Create default mode using configured durations
      _currentGrid = _createDefaultGrid(settings);
      await _storage.saveMode(_currentGrid!);
    }

    // Clear old session data and reinitialize to idle state
    // Avoid issues caused by stale data on startup
    await _storage.clearAllSessions();
    _initializeIdleSessions();

    // Start UI refresh timer
    _uiRefreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkActiveTimers();
      _emitState();
    });

    _emitState();
  }

  /// Handle detected gestures during alarm
  Future<void> _onGestureDetected(AlarmGestureType gestureType) async {
    // Only process gestures when there are ringing timers
    if (_ringingTimers.isEmpty) return;

    final settings = await _storage.getSettings();
    if (settings == null) return;

    // Get the action for this gesture
    final action = settings.gestureActions[gestureType];
    if (action == null || action == AlarmGestureAction.none) return;

    // Apply action to all ringing timers
    for (final timerId in _ringingTimers.toList()) {
      switch (action) {
        case AlarmGestureAction.stopAndReset:
          await stopRinging(timerId);
          break;
        case AlarmGestureAction.pause:
          await pause(timerId);
          break;
        case AlarmGestureAction.none:
          break;
      }
    }
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

      // Save state to storage
      await _storage.saveSession(session);

      // Add to ringing timers set
      _ringingTimers.add(timerId);

      // Start gesture monitoring when first timer starts ringing
      if (_ringingTimers.length == 1) {
        _gesture.startMonitoring();

        // Update shake sensitivity from settings
        final settings = await _storage.getSettings();
        if (settings != null) {
          _gesture.updateShakeSensitivity(settings.shakeSensitivity);
        }
      }

      // Load settings for volume parameters
      final settings = await _storage.getSettings();

      // Play sound and TTS
      final config = _currentGrid!.slots[slotIndex];
      final soundVolume = settings?.soundVolume ?? 1.0;

      // Use configured playback mode
      await _audio.playWithMode(
        soundKey: config.soundKey,
        volume: soundVolume,
        mode: settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely,
        loopDurationMinutes: settings?.audioLoopDurationMinutes ?? 5,
        intervalPauseMinutes: settings?.audioIntervalPauseMinutes ?? 2,
        customAudioPath: settings?.customAudioPath,
      );

      // Show immediate notification to ensure sound on lockscreen
      await _notification.showTimeUpNow(session: session, config: config);

      if (config.ttsEnabled && (settings?.ttsGlobalEnabled ?? true)) {
        final ttsVolume = settings?.ttsVolume ?? 1.0;
        final ttsSpeechRate = settings?.ttsSpeechRate ?? 0.5;
        final ttsPitch = settings?.ttsPitch ?? 1.0;

        await _tts.setVolume(ttsVolume);
        await _tts.setSpeechRate(ttsSpeechRate);
        await _tts.setPitch(ttsPitch);

        // Determine TTS locale (simple logic: check if name contains Chinese characters)
        // Ideally we should use the app's current locale, but here we can infer from content or default to a safe fallback.
        // Or we can check system locale. For now, let's use a simple heuristic or default to system.
        // Given user requirement "App is for Chinese and English users", we should adapt.

        final isChineseName = RegExp(r'[\u4e00-\u9fa5]').hasMatch(config.name);
        final localeTag = isChineseName ? 'zh-CN' : 'en-US';
        final ttsText = isChineseName
            ? '${config.name} 时间到'
            : '${config.name} time is up';

        await _tts.speak(text: ttsText, localeTag: localeTag, interrupt: true);
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

    final settings = await _storage.getSettings();
    final repeatSoundUntilStopped =
        (settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely) ==
        AudioPlaybackMode.loopIndefinitely;

    // Schedule notification
    await _notification.scheduleTimeUp(
      session: session,
      config: config,
      repeatSoundUntilStopped: repeatSoundUntilStopped,
    );

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

    final settings = await _storage.getSettings();
    final repeatSoundUntilStopped =
        (settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely) ==
        AudioPlaybackMode.loopIndefinitely;

    final config = _currentGrid!.slots[session.slotIndex];
    await _notification.scheduleTimeUp(
      session: updated,
      config: config,
      repeatSoundUntilStopped: repeatSoundUntilStopped,
    );

    _emitState();
  }

  @override
  Future<void> reset(TimerId timerId) async {
    // Ensure we clear the pending flag to prevent lock-up
    _pendingRinging.remove(timerId);

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

      // Remove from ringing timers
      _ringingTimers.remove(timerId);

      // Stop gesture monitoring if no more ringing timers
      if (_ringingTimers.isEmpty) {
        _gesture.stopMonitoring();
      }
    }

    _emitState();
  }

  @override
  Future<void> stopRinging(TimerId timerId) async {
    final session = _sessions[timerId];
    if (session == null || session.status != TimerStatus.ringing) return;

    await _audio.stop();
    await _tts.stop();

    // Remove from ringing timers
    _ringingTimers.remove(timerId);

    // Stop gesture monitoring if no more ringing timers
    if (_ringingTimers.isEmpty) {
      _gesture.stopMonitoring();
    }

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

  /// 更新 default mode 的时长配置（从设置中读取最新配置）
  @override
  Future<void> updateDefaultGridDurations() async {
    // 只能在没有活动计时器时更新
    if (hasActiveTimers()) {
      throw Exception('Cannot update grid durations while timers are active');
    }

    final settings = await _storage.getSettings();
    if (_currentGrid?.modeId == 'default') {
      // 重新创建 default grid
      _currentGrid = _createDefaultGrid(settings);
      await _storage.saveMode(_currentGrid!);

      // 重新初始化 sessions
      _initializeIdleSessions();

      _emitState();
    }
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

    // Skip if already ringing or pending
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

      // Add to ringing timers and start gesture monitoring
      _ringingTimers.add(timerId);
      if (_ringingTimers.length == 1) {
        _gesture.startMonitoring();

        // Update shake sensitivity from settings
        final settings = await _storage.getSettings();
        if (settings != null) {
          _gesture.updateShakeSensitivity(settings.shakeSensitivity);
        }
      }

      // Load settings for volume parameters
      final settings = await _storage.getSettings();

      // Play audio and TTS
      final config = _currentGrid!.slots[session.slotIndex];
      final soundVolume = settings?.soundVolume ?? 1.0;

      // 使用配置的播放模式
      await _audio.playWithMode(
        soundKey: config.soundKey,
        volume: soundVolume,
        mode: settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely,
        loopDurationMinutes: settings?.audioLoopDurationMinutes ?? 5,
        intervalPauseMinutes: settings?.audioIntervalPauseMinutes ?? 2,
        customAudioPath: settings?.customAudioPath,
      );

      // 显示即时通知，确保锁屏时也能发声
      await _notification.showTimeUpNow(session: updated, config: config);

      if (config.ttsEnabled && (settings?.ttsGlobalEnabled ?? true)) {
        final ttsVolume = settings?.ttsVolume ?? 1.0;
        final ttsSpeechRate = settings?.ttsSpeechRate ?? 0.5;
        final ttsPitch = settings?.ttsPitch ?? 1.0;

        await _tts.setVolume(ttsVolume);
        await _tts.setSpeechRate(ttsSpeechRate);
        await _tts.setPitch(ttsPitch);

        // Determine TTS locale (simple logic: check if name contains Chinese characters)
        // Ideally we should use the app's current locale, but here we can infer from content or default to a safe fallback.
        // Or we can check system locale. For now, let's use a simple heuristic or default to system.
        // Given user requirement "App is for Chinese and English users", we should adapt.

        final isChineseName = RegExp(r'[\u4e00-\u9fa5]').hasMatch(config.name);
        final localeTag = isChineseName ? 'zh-CN' : 'en-US';
        final ttsText = isChineseName
            ? '${config.name} 时间到'
            : '${config.name} time is up';

        await _tts.speak(text: ttsText, localeTag: localeTag, interrupt: true);
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
    final settings = await _storage.getSettings();
    final repeatSoundUntilStopped =
        (settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely) ==
        AudioPlaybackMode.loopIndefinitely;

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
          await _notification.scheduleTimeUp(
            session: session,
            config: config,
            repeatSoundUntilStopped: repeatSoundUntilStopped,
          );
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

  TimerGridSet _createDefaultGrid(AppSettings? settings) {
    // 从设置中获取配置的时长，如果没有则使用默认值
    // 默认时间配置（单位：秒）：10秒, 2分, 3分, 5分, 8分, 10分, 15分, 20分, 45分
    final durationsInSeconds =
        settings?.gridDurationsInSeconds ??
        [10, 120, 180, 300, 480, 600, 900, 1200, 2700];

    assert(durationsInSeconds.length == 9, '九宫格时长配置必须包含9个元素');

    final configs = List.generate(9, (i) {
      final seconds = durationsInSeconds[i];
      // 根据秒数生成显示名称
      final name = _formatDurationName(seconds);

      return TimerConfig(
        slotIndex: i,
        name: name,
        presetDurationMs: Duration(seconds: seconds).inMilliseconds,
        soundKey: 'default',
        ttsEnabled: true,
      );
    });

    return TimerGridSet(modeId: 'default', modeName: 'Default', slots: configs);
  }

  /// Format duration name based on seconds
  String _formatDurationName(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      return '$hours h';
    }
  }

  void dispose() {
    _uiRefreshTimer?.cancel();
    _stateController.close();
    _gestureSubscription?.cancel();
    _gesture.dispose();
  }
}
