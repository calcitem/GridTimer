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
  Future<void> ensureAndroidChannels({
    required Set<String> soundKeys,
  });

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
  });

  /// Cancels the scheduled notification for a timer.
  Future<void> cancelTimeUp({
    required TimerId timerId,
    required int slotIndex,
  });

  /// Cancels all scheduled notifications (e.g., mode switch confirmation).
  Future<void> cancelAll();

  /// Shows an immediate time-up notification (for when timer rings while app is running).
  /// This is needed to ensure sound plays even when device is locked.
  Future<void> showTimeUpNow({
    required TimerSession session,
    required TimerConfig config,
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



