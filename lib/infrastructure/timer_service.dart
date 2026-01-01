import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
import '../core/domain/services/i_vibration_service.dart';
import '../core/domain/types.dart';
import '../core/services/duration_formatter.dart';
import '../data/repositories/storage_repository.dart';

const _alarmServiceChannel = MethodChannel(
  'com.calcitem.gridtimer/system_settings',
);

/// Timer service implementation with full state management and recovery.
class TimerService with WidgetsBindingObserver implements ITimerService {
  final StorageRepository _storage;
  final INotificationService _notification;
  final IAudioService _audio;
  final ITtsService _tts;
  final IClock _clock;
  final IGestureService _gesture;
  final IVibrationService _vibration;

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

  /// Tracks current app lifecycle state to decide foreground/background behaviours.
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  /// Subscription for notification action events (e.g., Stop button).
  StreamSubscription<NotificationEvent>? _notificationSubscription;

  TimerService({
    required StorageRepository storage,
    required INotificationService notification,
    required IAudioService audio,
    required ITtsService tts,
    required IClock clock,
    required IGestureService gesture,
    required IVibrationService vibration,
  }) : _storage = storage,
       _notification = notification,
       _audio = audio,
       _tts = tts,
       _clock = clock,
       _gesture = gesture,
       _vibration = vibration;

  bool _initialized = false;

  static const int _androidAlarmSoundRequestCodeBase = 52000;

  int _androidAlarmSoundRequestCodeForSlot(int slotIndex) {
    assert(slotIndex >= 0 && slotIndex < 9, 'slotIndex must be in [0, 8]');
    return _androidAlarmSoundRequestCodeBase + slotIndex;
  }

  Future<void> _scheduleAndroidAlarmSound({
    required int triggerAtEpochMs,
    required String channelId,
    required int slotIndex,
    required bool loop,
  }) async {
    if (!Platform.isAndroid) return;
    assert(channelId.isNotEmpty, 'channelId must not be empty');
    assert(triggerAtEpochMs > 0, 'triggerAtEpochMs must be > 0');

    try {
      await _alarmServiceChannel.invokeMethod<void>(
        'scheduleAlarmSound',
        {
          'triggerAtEpochMs': triggerAtEpochMs,
          'channelId': channelId,
          'requestCode': _androidAlarmSoundRequestCodeForSlot(slotIndex),
          'loop': loop,
          // Fallback used if channel sound cannot be resolved (e.g., channel missing).
          'soundFallback': 'raw',
        },
      );
    } catch (e) {
      debugPrint('TimerService: Failed to schedule AlarmSoundService: $e');
    }
  }

  Future<void> _cancelAndroidAlarmSound({required int slotIndex}) async {
    if (!Platform.isAndroid) return;
    try {
      await _alarmServiceChannel.invokeMethod<void>(
        'cancelAlarmSound',
        {'requestCode': _androidAlarmSoundRequestCodeForSlot(slotIndex)},
      );
    } catch (e) {
      debugPrint('TimerService: Failed to cancel AlarmSoundService alarm: $e');
    }
  }

  Future<void> _cancelAllAndroidAlarmSounds() async {
    if (!Platform.isAndroid) return;
    for (int i = 0; i < 9; i++) {
      await _cancelAndroidAlarmSound(slotIndex: i);
    }
  }

  @override
  Future<void> init() async {
    // Prevent double initialization
    if (_initialized) return;
    _initialized = true;

    // Observe app lifecycle so we can switch between in-app audio and system
    // notification sound when the app is backgrounded/locked.
    WidgetsBinding.instance.addObserver(this);

    // Best-effort cleanup: stop any existing foreground alarm playback and cancel
    // pending native alarms. This prevents stray playback after process restarts.
    if (Platform.isAndroid) {
      try {
        await _alarmServiceChannel.invokeMethod<void>('stopAlarmSoundService');
      } catch (_) {
        // Ignore.
      }
      await _cancelAllAndroidAlarmSounds();
    }

    // Listen for notification action events (e.g., Stop).
    _notificationSubscription = _notification.events().listen(
      _onNotificationEvent,
    );

    await _storage.init();

    // Initialize gesture service
    await _gesture.init();

    // Initialize vibration service
    await _vibration.init();

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

  bool get _isInForeground => _lifecycleState == AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  Future<void> _onNotificationEvent(NotificationEvent event) async {
    if (event.type != NotificationEventType.stop) return;
    try {
      final decoded = jsonDecode(event.payloadJson);
      if (decoded is! Map<String, dynamic>) return;

      final timerIdAny = decoded['timerId'];
      final timerId = timerIdAny is String ? timerIdAny : null;
      if (timerId == null || timerId.isEmpty) return;

      final slotIndexAny = decoded['slotIndex'];
      final slotIndex = slotIndexAny is int ? slotIndexAny : null;

      final session = _sessions[timerId];
      if (session == null) {
        // Best-effort: still cancel the notification if we can't map it to a local session.
        if (slotIndex != null) {
          await _notification.cancelTimeUp(
            timerId: timerId,
            slotIndex: slotIndex,
          );
        }
        // If state is unknown (e.g., app restarted), still try to stop alarm playback.
        await _tts.stop();
        await _vibration.cancel();
        if (Platform.isAndroid) {
          try {
            await _alarmServiceChannel.invokeMethod<void>('stopAlarmSoundService');
          } catch (_) {
            // Ignore.
          }
        }
        return;
      }

      if (session.status == TimerStatus.ringing) {
        await stopRinging(timerId);
      } else {
        // If we don't consider it "ringing" locally (e.g., app restarted),
        // still cancel the notification to stop any repeating alert.
        await reset(timerId);
      }
    } catch (e, stackTrace) {
      debugPrint('TimerService: Failed to handle notification event: $e');
      debugPrint('Stack trace: $stackTrace');
    }
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

      // Only process timers that are RUNNING, time is up, and not being processed
      if (session.status == TimerStatus.running &&
          session.shouldBeRinging(nowMs) &&
          !_pendingRinging.contains(timerId)) {
        // Lock to prevent duplicate triggers
        _pendingRinging.add(timerId);

        // Immediately update memory state to ringing to avoid duplicate triggers on next check
        final updated = session.copyWith(
          status: TimerStatus.ringing,
          remainingMsAtPause: 0,
          lastUpdatedEpochMs: nowMs,
        );
        _sessions[timerId] = updated;

        // Execute ringing logic asynchronously (save state, play sound)
        _triggerRingingAsync(timerId, session.slotIndex);
      }
    }
  }

  Future<void> _triggerRingingAsync(TimerId timerId, int slotIndex) async {
    try {
      final session = _sessions[timerId];
      if (session == null) return;

      // Safety check: ensure _currentGrid is valid
      if (_currentGrid == null ||
          slotIndex < 0 ||
          slotIndex >= _currentGrid!.slots.length) {
        debugPrint(
          'TimerService: Invalid state in _triggerRingingAsync - '
          'grid=$_currentGrid, slotIndex=$slotIndex',
        );
        return;
      }

      // Save state to storage
      await _storage.saveSession(session);

      // Add to ringing timers set
      _ringingTimers.add(timerId);

      // Load settings and config (used by audio/TTS and gesture sensitivity).
      final settings = await _storage.getSettings();
      final config = _currentGrid!.slots[slotIndex];

      // Start gesture monitoring when first timer starts ringing
      if (_ringingTimers.length == 1) {
        _gesture.startMonitoring();

        // Update shake sensitivity from settings
        if (settings != null) {
          _gesture.updateShakeSensitivity(settings.shakeSensitivity);
        }

        if (!Platform.isAndroid) {
          // Non-Android platforms use in-app audio playback.
          try {
            await _audio.playWithMode(
              soundKey: config.soundKey,
              mode:
                  settings?.audioPlaybackMode ??
                  AudioPlaybackMode.loopIndefinitely,
              volume: settings?.soundVolume ?? 1.0,
              loopDurationMinutes: settings?.audioLoopDurationMinutes ?? 5,
              intervalPauseMinutes: settings?.audioIntervalPauseMinutes ?? 2,
            );
          } catch (e) {
            debugPrint('TimerService: Failed to play in-app audio: $e');
          }
        }
      }

      // IMPORTANT:
      // - On Android, alarm audio is played by a native foreground service.
      // - Time-up notifications are silent to avoid double-playing sound.

      // TTS playback logic:
      // - Android/iOS: Only reliable in foreground (background may be restricted by system)
      // - Windows/Desktop: Can play even in background, no restriction
      final isDesktop =
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
      final shouldPlayTts =
          config.ttsEnabled &&
          (settings?.ttsGlobalEnabled ?? true) &&
          (isDesktop || _isInForeground);

      if (shouldPlayTts) {
        final ttsVolume = settings?.ttsVolume ?? 1.0;
        final ttsSpeechRate = settings?.ttsSpeechRate ?? 0.5;
        final ttsPitch = settings?.ttsPitch ?? 1.0;

        await _tts.setVolume(ttsVolume);
        await _tts.setSpeechRate(ttsSpeechRate);
        await _tts.setPitch(ttsPitch);

        // Use user-selected TTS language, or fall back to system language detection
        final userTtsLanguage = settings?.ttsLanguage;
        final String localeTag;
        final String ttsText;

        if (userTtsLanguage != null) {
          // User has explicitly set a TTS language
          localeTag = userTtsLanguage;
          ttsText = userTtsLanguage.startsWith('zh')
              ? '${config.name} 时间到'
              : '${config.name} time is up';
        } else {
          // Fall back to system language detection
          final systemLocale = Platform.localeName;
          final isChineseSystem = systemLocale.startsWith('zh');
          localeTag = isChineseSystem ? 'zh-CN' : 'en-US';
          ttsText = isChineseSystem
              ? '${config.name} 时间到'
              : '${config.name} time is up';
        }

        await _tts.speak(text: ttsText, localeTag: localeTag, interrupt: true);
      }
    } catch (e, stackTrace) {
      // Log error but don't crash the app
      debugPrint('TimerService: Error in _triggerRingingAsync: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      // Release lock
      _pendingRinging.remove(timerId);
    }
  }

  @override
  Stream<(TimerGridSet, List<TimerSession>)> watchGridState() {
    return _stateController.stream;
  }

  @override
  (TimerGridSet, List<TimerSession>) getSnapshot() {
    assert(_currentGrid != null, 'getSnapshot() called before init()');
    final sessions = List<TimerSession>.from(_sessions.values);
    sessions.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    return (_currentGrid!, sessions);
  }

  @override
  Future<void> start({required ModeId modeId, required int slotIndex}) async {
    assert(_currentGrid != null, 'start() called before init()');
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
        (settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely) !=
        AudioPlaybackMode.playOnce;

    // Schedule notification
    await _notification.scheduleTimeUp(
      session: session,
      config: config,
      repeatSoundUntilStopped: repeatSoundUntilStopped,
      enableVibration: settings?.vibrationEnabled ?? true,
      ttsLanguage: settings?.ttsLanguage,
    );

    // Schedule native alarm playback for Android (works even if Flutter process is killed).
    if (Platform.isAndroid) {
      final mode = settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely;
      final loop = mode != AudioPlaybackMode.playOnce;
      await _scheduleAndroidAlarmSound(
        triggerAtEpochMs: endMs,
        channelId: 'gt.alarm.timeup.${config.soundKey}.v2',
        slotIndex: slotIndex,
        loop: loop,
      );
    }

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
    if (Platform.isAndroid) {
      await _cancelAndroidAlarmSound(slotIndex: session.slotIndex);
    }

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
        (settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely) !=
        AudioPlaybackMode.playOnce;

    final config = _currentGrid!.slots[session.slotIndex];
    await _notification.scheduleTimeUp(
      session: updated,
      config: config,
      repeatSoundUntilStopped: repeatSoundUntilStopped,
      enableVibration: settings?.vibrationEnabled ?? true,
      ttsLanguage: settings?.ttsLanguage,
    );

    if (Platform.isAndroid) {
      final mode = settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely;
      final loop = mode != AudioPlaybackMode.playOnce;
      await _scheduleAndroidAlarmSound(
        triggerAtEpochMs: newEndMs,
        channelId: 'gt.alarm.timeup.${config.soundKey}.v2',
        slotIndex: session.slotIndex,
        loop: loop,
      );
    }

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
    if (Platform.isAndroid) {
      await _cancelAndroidAlarmSound(slotIndex: session.slotIndex);
    }

    // Stop audio/TTS if ringing
    if (session.status == TimerStatus.ringing) {
      await _tts.stop();

      // Stop vibration.
      await _vibration.cancel();

      // Remove from ringing timers
      _ringingTimers.remove(timerId);

      // Stop gesture monitoring if no more ringing timers
      if (_ringingTimers.isEmpty) {
        await _audio.stop();
        _gesture.stopMonitoring();

        // Stop foreground alarm service when no timers are ringing
        if (Platform.isAndroid) {
          try {
            await _alarmServiceChannel.invokeMethod<void>(
              'stopAlarmSoundService',
            );
            debugPrint(
              'TimerService: Foreground alarm service stopped (from reset)',
            );
          } catch (e) {
            debugPrint(
              'TimerService: Failed to stop foreground alarm service: $e',
            );
          }
        }
      }
    }

    // Best-effort: if no timers are ringing locally, ensure foreground alarm playback is stopped.
    // This covers cases where the native alarm service started while Flutter state is out of sync.
    if (Platform.isAndroid && _ringingTimers.isEmpty) {
      try {
        await _alarmServiceChannel.invokeMethod<void>('stopAlarmSoundService');
      } catch (_) {
        // Ignore.
      }
    }

    _emitState();
  }

  @override
  Future<void> stopRinging(TimerId timerId) async {
    final session = _sessions[timerId];
    if (session == null || session.status != TimerStatus.ringing) return;
    await reset(timerId);
  }

  @override
  Future<void> switchMode(ModeId modeId) async {
    // Caller must ensure all timers are stopped
    final newGrid = await _storage.getMode(modeId);
    if (newGrid == null) return;

    // Clear all sessions
    await _notification.cancelAll();
    if (Platform.isAndroid) {
      await _cancelAllAndroidAlarmSounds();
      try {
        await _alarmServiceChannel.invokeMethod<void>('stopAlarmSoundService');
      } catch (_) {
        // Ignore.
      }
    }
    _currentGrid = newGrid;
    _initializeIdleSessions();

    _emitState();
  }

  /// Update duration configuration for default mode (read latest config from settings)
  @override
  Future<void> updateDefaultGridDurations() async {
    // Can only update when no active timers
    if (hasActiveTimers()) {
      throw Exception('Cannot update grid durations while timers are active');
    }

    final settings = await _storage.getSettings();
    if (_currentGrid?.modeId == 'default') {
      // Recreate default grid
      _currentGrid = _createDefaultGrid(settings);
      await _storage.saveMode(_currentGrid!);

      // Re-initialize sessions
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
      // Safety check: ensure _currentGrid is valid
      if (_currentGrid == null ||
          session.slotIndex < 0 ||
          session.slotIndex >= _currentGrid!.slots.length) {
        debugPrint(
          'TimerService: Invalid state in handleTimeUpEvent - '
          'grid=$_currentGrid, slotIndex=${session.slotIndex}',
        );
        return;
      }

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

      // IMPORTANT: Do NOT call showTimeUpNow() here!
      // The scheduled notification from scheduleTimeUp() will trigger and play sound.
      // Calling showTimeUpNow() would cancel the scheduled notification, and immediate
      // notifications don't play sound reliably when app is in foreground/background.

      // Load settings for TTS.
      final settings = await _storage.getSettings();
      final config = _currentGrid!.slots[session.slotIndex];

      // TTS playback logic:
      // - Android/iOS: Only reliable in foreground (background may be restricted by system)
      // - Windows/Desktop: Can play even in background, no restriction
      final isDesktop =
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
      final shouldPlayTts =
          config.ttsEnabled &&
          (settings?.ttsGlobalEnabled ?? true) &&
          (isDesktop || _isInForeground);

      if (shouldPlayTts) {
        final ttsVolume = settings?.ttsVolume ?? 1.0;
        final ttsSpeechRate = settings?.ttsSpeechRate ?? 0.5;
        final ttsPitch = settings?.ttsPitch ?? 1.0;

        await _tts.setVolume(ttsVolume);
        await _tts.setSpeechRate(ttsSpeechRate);
        await _tts.setPitch(ttsPitch);

        // Use user-selected TTS language, or fall back to system language detection
        final userTtsLanguage = settings?.ttsLanguage;
        final String localeTag;
        final String ttsText;

        if (userTtsLanguage != null) {
          // User has explicitly set a TTS language
          localeTag = userTtsLanguage;
          ttsText = userTtsLanguage.startsWith('zh')
              ? '${config.name} 时间到'
              : '${config.name} time is up';
        } else {
          // Fall back to system language detection
          final systemLocale = Platform.localeName;
          final isChineseSystem = systemLocale.startsWith('zh');
          localeTag = isChineseSystem ? 'zh-CN' : 'en-US';
          ttsText = isChineseSystem
              ? '${config.name} 时间到'
              : '${config.name} time is up';
        }

        await _tts.speak(text: ttsText, localeTag: localeTag, interrupt: true);
      }

      _emitState();
    } catch (e, stackTrace) {
      // Log error but don't crash the app
      debugPrint('TimerService: Error in handleTimeUpEvent: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _pendingRinging.remove(timerId);
    }
  }

  @override
  bool hasActiveTimers() {
    return _sessions.values.any((s) => s.status != TimerStatus.idle);
  }

  Future<void> _recoverSessions() async {
    // Safety check: ensure _currentGrid is valid
    if (_currentGrid == null) {
      debugPrint('TimerService: _recoverSessions called with null grid');
      return;
    }

    final nowMs = _clock.nowEpochMs();
    final settings = await _storage.getSettings();
    final repeatSoundUntilStopped =
        (settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely) !=
        AudioPlaybackMode.playOnce;

    for (final session in _sessions.values.toList()) {
      if (session.status == TimerStatus.running) {
        // Safety check: ensure slotIndex is valid
        if (session.slotIndex < 0 ||
            session.slotIndex >= _currentGrid!.slots.length) {
          debugPrint(
            'TimerService: Invalid slotIndex ${session.slotIndex} in _recoverSessions',
          );
          continue;
        }

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
            enableVibration: settings?.vibrationEnabled ?? true,
            ttsLanguage: settings?.ttsLanguage,
          );
        }
      }
    }
  }

  void _initializeIdleSessions() {
    assert(
      _currentGrid != null,
      '_initializeIdleSessions() called before grid is set',
    );
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
    // Safety check: don't emit if grid is not initialized yet
    if (_currentGrid == null) {
      debugPrint('TimerService: _emitState() skipped - grid not initialized');
      return;
    }
    final sessions = List<TimerSession>.from(_sessions.values);
    sessions.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
    _stateController.add((_currentGrid!, sessions));
  }

  TimerGridSet _createDefaultGrid(AppSettings? settings) {
    // Get configured durations from settings, use defaults if not available
    // Default time configuration (in seconds): 2min, 3min, 5min, 8min, 9min, 10min, 15min, 20min, 45min
    final durationsInSeconds =
        settings?.gridDurationsInSeconds ??
        [120, 180, 300, 480, 540, 600, 900, 1200, 2700];

    assert(
      durationsInSeconds.length == 9,
      'Grid duration configuration must contain 9 elements',
    );

    // Create duration formatter based on system locale
    final systemLocale = Platform.localeName;
    final formatter = DurationFormatter(systemLocale);

    final configs = List.generate(9, (i) {
      final seconds = durationsInSeconds[i];
      // Generate display name using localized formatter
      final userDefinedName =
          (settings?.gridNames != null && settings!.gridNames.length > i)
              ? settings.gridNames[i]
              : '';

      final name =
          userDefinedName.isNotEmpty
              ? userDefinedName
              : formatter.format(seconds);

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

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    _uiRefreshTimer?.cancel();
    _stateController.close();
    _gestureSubscription?.cancel();
    _gesture.dispose();
  }
}
