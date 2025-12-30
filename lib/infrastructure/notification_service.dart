import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/domain/entities/timer_config.dart';
import '../core/domain/entities/timer_session.dart';
import '../core/domain/enums.dart';
import '../core/domain/services/i_notification_service.dart';
import '../core/domain/types.dart';

/// Android notification service implementation.
class NotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<NotificationEvent> _eventController = StreamController<NotificationEvent>.broadcast();

  static const String _channelGroupId = 'gt.group.timers';
  static const String _actionIdStop = 'gt.action.stop';
  static const String _actionIdOpen = 'gt.action.open';

  @override
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // Create channel group
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannelGroup(
            const AndroidNotificationChannelGroup(
              _channelGroupId,
              'Timers',
              description: 'Timer notifications',
            ),
          );
    }
  }

  @override
  Future<void> ensureAndroidChannels({required Set<String> soundKeys}) async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Create one channel per sound key
    for (final soundKey in soundKeys) {
      final channelId = 'gt.alarm.timeup.$soundKey.v1';
      final soundResource = _soundKeyToResource(soundKey);

      final channel = AndroidNotificationChannel(
        channelId,
        'Timer Alarm ($soundKey)',
        description: 'Time up notifications for $soundKey ringtone',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundResource),
        enableVibration: true,
        groupId: _channelGroupId,
      );

      await androidPlugin.createNotificationChannel(channel);
    }

    // Create general channel (silent)
    const generalChannel = AndroidNotificationChannel(
      'gt.general.v1',
      'General',
      description: 'General app notifications',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      groupId: _channelGroupId,
    );
    await androidPlugin.createNotificationChannel(generalChannel);
  }

  @override
  Future<bool> requestPostNotificationsPermission() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final result = await androidPlugin.requestNotificationsPermission();
    return result ?? false;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final result = await androidPlugin.requestExactAlarmsPermission();
    return result ?? false;
  }

  @override
  Future<bool> requestFullScreenIntentPermission() async {
    // Note: flutter_local_notifications may not expose this API directly.
    // This is a placeholder; actual implementation may require platform channels.
    return true;
  }

  @override
  Future<void> scheduleTimeUp({
    required TimerSession session,
    required TimerConfig config,
  }) async {
    if (session.endAtEpochMs == null) return;

    final notificationId = 1000 + session.slotIndex;
    final channelId = 'gt.alarm.timeup.${config.soundKey}.v1';

    final payload = jsonEncode({
      'v': 1,
      'type': 'time_up',
      'modeId': session.modeId,
      'slotIndex': session.slotIndex,
      'timerId': session.timerId,
      'endAtEpochMs': session.endAtEpochMs,
      'soundKey': config.soundKey,
    });

    final scheduledDate = DateTime.fromMillisecondsSinceEpoch(session.endAtEpochMs!);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Alarm',
      channelDescription: 'Time up notification',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      actions: [
        AndroidNotificationAction(
          _actionIdStop,
          'Stop',
          showsUserInterface: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    // Try exact alarm first, fallback to inexact
    try {
      await _plugin.zonedSchedule(
        notificationId,
        config.name,
        'Time is up!',
        scheduledDate.toLocal(),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // Fallback to inexact if exact alarm permission denied
      await _plugin.zonedSchedule(
        notificationId,
        config.name,
        'Time is up!',
        scheduledDate.toLocal(),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  @override
  Future<void> cancelTimeUp({
    required TimerId timerId,
    required int slotIndex,
  }) async {
    final notificationId = 1000 + slotIndex;
    await _plugin.cancel(notificationId);
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  @override
  Stream<NotificationEvent> events() => _eventController.stream;

  void _onNotificationResponse(NotificationResponse response) {
    _handleNotificationResponse(response);
  }

  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Background callback - must be top-level or static
    // Handle minimal state changes here
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.isEmpty) return;

    NotificationEventType type = NotificationEventType.open;
    if (response.actionId == _actionIdStop) {
      type = NotificationEventType.stop;
    } else if (response.notificationResponseType == NotificationResponseType.selectedNotification) {
      type = NotificationEventType.open;
    }

    _eventController.add(NotificationEvent(
      type: type,
      payloadJson: payload,
      actionId: response.actionId,
    ));
  }

  String _soundKeyToResource(String soundKey) {
    // Map sound keys to raw resource names
    final map = {
      'bell01': 'bell_01',
      'bell02': 'bell_02',
      'beep_soft': 'beep_soft',
      'chime': 'chime',
      'ding': 'ding',
      'gentle': 'gentle',
    };
    return map[soundKey] ?? 'bell_01';
  }

  void dispose() {
    _eventController.close();
  }
}

