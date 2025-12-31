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
import '../data/repositories/storage_repository.dart';
import '../infrastructure/timer_service.dart';
import '../infrastructure/mode_service.dart';
import '../infrastructure/notification_service.dart';
import '../infrastructure/audio_service.dart';
import '../infrastructure/tts_service.dart';
import '../infrastructure/permission_service.dart';
import '../infrastructure/widget_service.dart';

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
  );
});

/// Grid state stream provider.
final gridStateProvider = StreamProvider((ref) {
  final service = ref.watch(timerServiceProvider);
  return service.watchGridState();
});

/// App settings provider.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>>((ref) {
      return AppSettingsNotifier(storage: ref.watch(storageProvider));
    });

/// Notifier for managing app settings state.
class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final StorageRepository storage;
  static const String _defaultModeId = 'default';

  AppSettingsNotifier({required this.storage})
    : super(const AsyncValue.loading()) {
    // Delay loading to ensure storage is initialized by timer service
    Future.microtask(_loadSettings);
  }

  /// Load settings from storage.
  Future<void> _loadSettings() async {
    try {
      final settings = await storage.getSettings();
      state = AsyncValue.data(
        settings ?? const AppSettings(activeModeId: _defaultModeId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update settings and save to storage.
  Future<void> updateSettings(AppSettings Function(AppSettings) updater) async {
    final current = state.value;
    if (current == null) return;

    try {
      final updated = updater(current);
      state = AsyncValue.data(updated);
      await storage.saveSettings(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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

  /// Update custom audio path.
  Future<void> updateCustomAudioPath(String? path) async {
    await updateSettings((s) => s.copyWith(customAudioPath: path));
  }
}
