import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../core/domain/entities/timer_config.dart';
import '../core/domain/entities/timer_session.dart';
import '../core/domain/enums.dart';
import '../core/domain/services/i_notification_service.dart';
import '../core/domain/types.dart';

/// Android notification service implementation.
class NotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationEvent> _eventController =
      StreamController<NotificationEvent>.broadcast();

  static const String _channelGroupId = 'gt.group.timers';
  static const String _actionIdStop = 'gt.action.stop';

  @override
  Future<void> init() async {
    // 始终初始化时区数据
    tz_data.initializeTimeZones();

    // 仅在支持的平台上初始化通知插件
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Windows 和其他桌面平台暂不支持通知功能
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Create channel group
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
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

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    // Create one channel per sound key
    for (final soundKey in soundKeys) {
      // v2: 添加了明确的 playSound 和 enableVibration 配置
      final channelId = 'gt.alarm.timeup.$soundKey.v2';
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

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return false;

    final result = await androidPlugin.requestNotificationsPermission();
    return result ?? false;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
    // 仅在支持的平台上安排通知
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    if (session.endAtEpochMs == null) return;

    final notificationId = 1000 + session.slotIndex;
    // 使用 v2 通道（配置了声音和振动）
    final channelId = 'gt.alarm.timeup.${config.soundKey}.v2';

    final payload = jsonEncode({
      'v': 1,
      'type': 'time_up',
      'modeId': session.modeId,
      'slotIndex': session.slotIndex,
      'timerId': session.timerId,
      'endAtEpochMs': session.endAtEpochMs,
      'soundKey': config.soundKey,
    });

    final scheduledDate = tz.TZDateTime.from(
      DateTime.fromMillisecondsSinceEpoch(session.endAtEpochMs!),
      tz.local,
    );

    // 获取声音资源名（必须明确指定，zonedSchedule 不会自动使用通道声音）
    final soundResource = _soundKeyToResource(config.soundKey);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Alarm',
      channelDescription: 'Time up notification',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      // 明确设置播放声音和振动
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundResource),
      enableVibration: true,
      // 设置为持续通知，直到用户操作
      ongoing: false,
      autoCancel: false,
      actions: [
        const AndroidNotificationAction(
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
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      // Fallback to inexact if exact alarm permission denied
      await _plugin.zonedSchedule(
        notificationId,
        config.name,
        'Time is up!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  @override
  Future<void> cancelTimeUp({
    required TimerId timerId,
    required int slotIndex,
  }) async {
    // 仅在支持的平台上取消通知
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    final notificationId = 1000 + slotIndex;
    await _plugin.cancel(notificationId);
  }

  @override
  Future<void> cancelAll() async {
    // 仅在支持的平台上取消通知
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    await _plugin.cancelAll();
  }

  @override
  Future<void> showTimeUpNow({
    required TimerSession session,
    required TimerConfig config,
  }) async {
    // 仅在支持的平台上显示通知
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final notificationId = 1000 + session.slotIndex;
    // 使用 v2 通道（配置了声音和振动）
    final channelId = 'gt.alarm.timeup.${config.soundKey}.v2';

    final payload = jsonEncode({
      'v': 1,
      'type': 'time_up',
      'modeId': session.modeId,
      'slotIndex': session.slotIndex,
      'timerId': session.timerId,
      'endAtEpochMs': session.endAtEpochMs,
      'soundKey': config.soundKey,
    });

    // 获取声音资源名（明确指定声音）
    final soundResource = _soundKeyToResource(config.soundKey);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Alarm',
      channelDescription: 'Time up notification',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      // 明确设置播放声音和振动
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundResource),
      enableVibration: true,
      actions: [
        const AndroidNotificationAction(
          _actionIdStop,
          'Stop',
          showsUserInterface: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    // 立即显示通知
    await _plugin.show(
      notificationId,
      config.name,
      'Time is up!',
      details,
      payload: payload,
    );
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
    } else if (response.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      type = NotificationEventType.open;
    }

    _eventController.add(
      NotificationEvent(
        type: type,
        payloadJson: payload,
        actionId: response.actionId,
      ),
    );
  }

  String _soundKeyToResource(String soundKey) {
    // All timers use the same sound file
    return 'sound';
  }

  void dispose() {
    _eventController.close();
  }
}
