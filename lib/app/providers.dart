import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Clock provider.
final clockProvider = Provider<IClock>((ref) => const SystemClock());

/// Storage repository provider.
final storageProvider = Provider<StorageRepository>((ref) => StorageRepository());

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



