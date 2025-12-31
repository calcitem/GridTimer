import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/domain/entities/app_settings.dart';
import '../core/domain/enums.dart';
import '../core/domain/services/i_clock.dart';
import '../core/domain/services/i_timer_service.dart';
import '../core/domain/services/i_notification_service.dart';
import '../core/domain/services/i_audio_service.dart';
import '../core/domain/services/i_tts_service.dart';
import '../core/domain/services/i_permission_service.dart';
import '../core/domain/services/i_mode_service.dart';
import '../core/domain/services/i_gesture_service.dart';
import '../core/domain/services/i_vibration_service.dart';
import '../data/repositories/storage_repository.dart';
import '../infrastructure/timer_service.dart';
import '../infrastructure/mode_service.dart';
import '../infrastructure/notification_service.dart';
import '../infrastructure/audio_service.dart';
import '../infrastructure/tts_service.dart';
import '../infrastructure/permission_service.dart';
import '../infrastructure/widget_service.dart';
import '../infrastructure/gesture_service.dart';
import '../infrastructure/vibration_service.dart';

/// Clock provider.
final clockProvider = Provider<IClock>((ref) => const SystemClock());

/// Storage repository provider.
final storageProvider = Provider<StorageRepository>(
  (ref) => StorageRepository(),
);

/// Notification service provider.
final notificationServiceProvider = Provider<INotificationService>((ref) {
  return NotificationService();
});

/// Audio service provider.
final audioServiceProvider = Provider<IAudioService>((ref) {
  return AudioService();
});

/// TTS service provider.
final ttsServiceProvider = Provider<ITtsService>((ref) {
  return TtsService();
});

/// Permission service provider.
final permissionServiceProvider = Provider<IPermissionService>((ref) {
  return PermissionService();
});

/// Widget service provider (Android only).
final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

/// Gesture service provider.
final gestureServiceProvider = Provider<IGestureService>((ref) {
  return GestureService();
});

/// Vibration service provider.
final vibrationServiceProvider = Provider<IVibrationService>((ref) {
  return VibrationService();
});

/// Mode service provider.
final modeServiceProvider = Provider<IModeService>((ref) {
  return ModeService(storage: ref.watch(storageProvider));
});

/// Timer service provider.
final timerServiceProvider = Provider<ITimerService>((ref) {
  return TimerService(
    storage: ref.watch(storageProvider),
    notification: ref.watch(notificationServiceProvider),
    audio: ref.watch(audioServiceProvider),
    tts: ref.watch(ttsServiceProvider),
    clock: ref.watch(clockProvider),
    gesture: ref.watch(gestureServiceProvider),
    vibration: ref.watch(vibrationServiceProvider),
  );
});

/// Timer service initialization provider.
/// Ensures timer service is initialized before use.
final timerServiceInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(timerServiceProvider);
  await service.init();
});

/// Grid state stream provider.
/// Waits for timer service initialization before watching state.
final gridStateProvider = StreamProvider((ref) async* {
  // Wait for timer service to be initialized first
  await ref.watch(timerServiceInitProvider.future);

  final service = ref.watch(timerServiceProvider);
  yield* service.watchGridState();
});

/// App settings provider.
final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

/// Notifier for managing app settings state.
class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static const String _defaultModeId = 'default';

  @override
  Future<AppSettings> build() async {
    final storage = ref.watch(storageProvider);
    // Delay loading to ensure storage is initialized by timer service logic if needed?
    // Actually storage.getSettings() should be fine.
    // Previous code had: Future.microtask(_loadSettings); and initial state loading.
    // Here build() is async, so it starts loading immediately.
    try {
      final settings = await storage.getSettings();
      return settings ?? const AppSettings(activeModeId: _defaultModeId);
    } catch (e) {
      // Return default on error or rethrow?
      // AsyncNotifier handles error state.
      rethrow;
    }
  }

  /// Update settings and save to storage.
  Future<void> updateSettings(AppSettings Function(AppSettings) updater) async {
    final current = state.value;
    if (current == null) return;

    try {
      final updated = updater(current);
      state = AsyncData(updated);
      await ref.read(storageProvider).saveSettings(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Toggle flash animation.
  Future<void> toggleFlash(bool enabled) async {
    await updateSettings((s) => s.copyWith(flashEnabled: enabled));
  }

  /// Toggle global TTS.
  Future<void> toggleTts(bool enabled) async {
    await updateSettings((s) => s.copyWith(ttsGlobalEnabled: enabled));
  }

  /// Toggle keep screen on.
  Future<void> toggleKeepScreenOn(bool enabled) async {
    await updateSettings((s) => s.copyWith(keepScreenOnWhileRunning: enabled));
  }

  /// Toggle vibration.
  Future<void> toggleVibration(bool enabled) async {
    await updateSettings((s) => s.copyWith(vibrationEnabled: enabled));
  }

  /// Set onboarding completed.
  Future<void> setOnboardingCompleted(bool completed) async {
    await updateSettings((s) => s.copyWith(onboardingCompleted: completed));
  }

  /// Set safety disclaimer accepted.
  Future<void> updateSafetyDisclaimerAccepted(bool accepted) async {
    await updateSettings((s) => s.copyWith(safetyDisclaimerAccepted: accepted));
  }

  /// Update sound volume.
  Future<void> updateSoundVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      'Volume must be between 0.0 and 1.0',
    );
    await updateSettings((s) => s.copyWith(soundVolume: volume));
  }

  /// Update selected sound key.
  Future<void> updateSelectedSoundKey(String soundKey) async {
    await updateSettings((s) => s.copyWith(selectedSoundKey: soundKey));
  }

  /// Update TTS volume.
  Future<void> updateTtsVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      'Volume must be between 0.0 and 1.0',
    );
    await updateSettings((s) => s.copyWith(ttsVolume: volume));
  }

  /// Update TTS speech rate.
  Future<void> updateTtsSpeechRate(double rate) async {
    assert(
      rate >= 0.0 && rate <= 1.0,
      'Speech rate must be between 0.0 and 1.0',
    );
    await updateSettings((s) => s.copyWith(ttsSpeechRate: rate));
  }

  /// Update TTS pitch.
  Future<void> updateTtsPitch(double pitch) async {
    assert(pitch >= 0.5 && pitch <= 2.0, 'Pitch must be between 0.5 and 2.0');
    await updateSettings((s) => s.copyWith(ttsPitch: pitch));
  }

  /// Update TTS language.
  /// Pass null to follow system/app language.
  Future<void> updateTtsLanguage(String? language) async {
    await updateSettings((s) => s.copyWith(ttsLanguage: language));
  }

  /// Update audio playback mode.
  Future<void> updateAudioPlaybackMode(AudioPlaybackMode mode) async {
    await updateSettings((s) => s.copyWith(audioPlaybackMode: mode));
  }

  /// Update audio loop duration (in minutes).
  Future<void> updateAudioLoopDuration(int minutes) async {
    assert(minutes > 0, 'Loop duration must be greater than 0');
    await updateSettings((s) => s.copyWith(audioLoopDurationMinutes: minutes));
  }

  /// Update audio interval pause duration (in minutes).
  Future<void> updateAudioIntervalPause(int minutes) async {
    assert(minutes > 0, 'Interval pause must be greater than 0');
    await updateSettings((s) => s.copyWith(audioIntervalPauseMinutes: minutes));
  }

  /// Update gesture action for a specific gesture type.
  Future<void> updateGestureAction(
    AlarmGestureType gesture,
    AlarmGestureAction action,
  ) async {
    await updateSettings((s) {
      final newActions = Map<AlarmGestureType, AlarmGestureAction>.from(
        s.gestureActions,
      );
      newActions[gesture] = action;
      return s.copyWith(gestureActions: newActions);
    });
  }

  /// Update shake sensitivity (1.0 - 5.0).
  Future<void> updateShakeSensitivity(double sensitivity) async {
    assert(
      sensitivity >= 1.0 && sensitivity <= 5.0,
      'Shake sensitivity must be between 1.0 and 5.0',
    );
    await updateSettings((s) => s.copyWith(shakeSensitivity: sensitivity));
  }
}
