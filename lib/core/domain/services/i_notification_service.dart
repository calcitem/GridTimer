import '../entities/timer_config.dart';
import '../entities/timer_session.dart';
import '../enums.dart';
import '../types.dart';

/// Notification service interface for Android notifications and alarms.
abstract interface class INotificationService {
  /// Must be called before scheduling any notifications.
  Future<void> init();

  /// Creates/updates channels where applicable.
  ///
  /// Note: channel sound cannot be changed after creation;
  /// one channel per soundKey is required.
  Future<void> ensureAndroidChannels({required Set<String> soundKeys});

  /// Android 13+ notification permission request.
  Future<bool> requestPostNotificationsPermission();

  /// Android 14+ exact alarm special access request (best-effort).
  Future<bool> requestExactAlarmPermission();

  /// Android 14+ full-screen intent special access request (best-effort).
  Future<bool> requestFullScreenIntentPermission();

  /// Schedules a notification for timer end.
  ///
  /// Implementer must choose exact/inexact schedule mode based on permission.
  Future<void> scheduleTimeUp({
    required TimerSession session,
    required TimerConfig config,

    /// Whether the notification sound should repeat until the notification is
    /// dismissed/cancelled by the user.
    ///
    /// On Android, this is typically implemented via `Notification.FLAG_INSISTENT`.
    /// On other platforms, this may be ignored due to OS limitations.
    bool repeatSoundUntilStopped = false,

    /// Whether vibration should be enabled for this notification.
    bool enableVibration = true,

    /// TTS language for notification content (e.g., 'zh-CN', 'en-US').
    /// If null, falls back to name-based detection.
    String? ttsLanguage,

    /// Whether the notification itself should play sound.
    /// - true: use sound channel (for notification mode)
    /// - false: use silent channel (for alarmClock mode with foreground service)
    bool playNotificationSound = false,

    /// Android-only: Prefer an alarm-usage notification channel even if the
    /// alarm stream volume is currently muted.
    ///
    /// When enabled, the app may independently manage the system alarm volume
    /// (e.g., temporarily boosting it at ringing time) and therefore does not
    /// need to fall back to a notification-usage channel.
    bool preferAlarmAudioUsage = false,
  });

  /// Cancels the scheduled notification for a timer.
  Future<void> cancelTimeUp({required TimerId timerId, required int slotIndex});

  /// Cancels all scheduled notifications (e.g., mode switch confirmation).
  Future<void> cancelAll();

  /// Shows an immediate time-up notification (for when timer rings while app is running).
  /// This is needed to ensure sound plays even when device is locked.
  Future<void> showTimeUpNow({
    required TimerSession session,
    required TimerConfig config,

    /// Whether vibration should be enabled for this notification.
    bool enableVibration = true,

    /// Whether the notification should play a sound.
    ///
    /// Note: On Android 8+ the notification channel controls the actual sound.
    /// This flag only controls whether sound is enabled for this notification.
    bool playSound = false,

    /// Whether the notification sound/vibration should repeat until cancelled.
    ///
    /// On Android this is typically implemented via `Notification.FLAG_INSISTENT`.
    /// Some OEM ROMs may ignore this flag.
    bool repeatSoundUntilStopped = false,

    /// TTS language for notification content (e.g., 'zh-CN', 'en-US').
    /// If null, falls back to name-based detection.
    String? ttsLanguage,
  });

  /// Stream of notification events (tap, action, full-screen trigger).
  Stream<NotificationEvent> events();
}

/// Notification event from user interaction.
class NotificationEvent {
  final NotificationEventType type;
  final String payloadJson;
  final String? actionId; // null if body tap

  const NotificationEvent({
    required this.type,
    required this.payloadJson,
    this.actionId,
  });
}
