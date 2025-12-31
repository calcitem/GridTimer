import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
  // Android Notification.FLAG_INSISTENT = 0x00000004.
  // When set, the notification sound/vibration will repeat until cancelled.
  static const int _androidFlagInsistent = 4;

  @override
  Future<void> init() async {
    // Always initialize timezone data
    tz_data.initializeTimeZones();

    // Initialize notification plugin only on supported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Windows and other desktop platforms don't support notification features yet
      return;
    }

    // Note: In release builds with shrinkResources enabled, resources not referenced
    // in the Manifest may be stripped. This project uses @mipmap/launcher_icon in the
    // Manifest, so the notification default icon should remain consistent to avoid
    // "invalid_icon / no valid small icon" crashes.
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
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

    // Try to create channel group first.
    // On some OEM ROMs (e.g., MIUI on Android 15), channel group creation may
    // silently fail or be delayed, causing subsequent channel creation with
    // groupId to fail with "NotificationChannelGroup doesn't exist".
    bool groupCreated = false;
    try {
      await androidPlugin.createNotificationChannelGroup(
        const AndroidNotificationChannelGroup(
          _channelGroupId,
          'Timers',
          description: 'Timer notifications',
        ),
      );
      groupCreated = true;
    } catch (e) {
      // Channel group creation failed; we'll create channels without groupId.
      groupCreated = false;
    }

    // Create one channel per sound key
    for (final soundKey in soundKeys) {
      // v2: Stable channel ID. On Android 8+, channel settings are controlled by the user.
      // We keep the channel ID stable so users don't have to reconfigure lockscreen/sound
      // settings after upgrades (especially on OEM ROMs like MIUI).
      final channelId = 'gt.alarm.timeup.$soundKey.v2';
      final soundResource = _soundKeyToResource(soundKey);

      // Try with groupId first, fall back to without groupId if it fails.
      // This handles OEM ROMs where NotificationChannelGroup creation may fail.
      final channelWithGroup = AndroidNotificationChannel(
        channelId,
        'Timer Alarm ($soundKey)',
        description: 'Time up notifications for $soundKey ringtone',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundResource),
        enableVibration: true,
        groupId: groupCreated ? _channelGroupId : null,
      );

      try {
        await androidPlugin.createNotificationChannel(channelWithGroup);
      } catch (e) {
        // If channel creation with groupId fails, try without groupId.
        if (groupCreated) {
          final channelWithoutGroup = AndroidNotificationChannel(
            channelId,
            'Timer Alarm ($soundKey)',
            description: 'Time up notifications for $soundKey ringtone',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(soundResource),
            enableVibration: true,
          );
          await androidPlugin.createNotificationChannel(channelWithoutGroup);
        } else {
          rethrow;
        }
      }
    }

    // Create general channel (silent)
    // Also use conditional groupId based on whether group creation succeeded.
    final generalChannel = AndroidNotificationChannel(
      'gt.general.v1',
      'General',
      description: 'General app notifications',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      groupId: groupCreated ? _channelGroupId : null,
    );

    try {
      await androidPlugin.createNotificationChannel(generalChannel);
    } catch (e) {
      // Fallback: create without groupId
      if (groupCreated) {
        const generalChannelNoGroup = AndroidNotificationChannel(
          'gt.general.v1',
          'General',
          description: 'General app notifications',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        );
        await androidPlugin.createNotificationChannel(generalChannelNoGroup);
      } else {
        rethrow;
      }
    }
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
  @override
  Future<void> scheduleTimeUp({
    required TimerSession session,
    required TimerConfig config,
    bool repeatSoundUntilStopped = false,
    bool enableVibration = true,
    String? ttsLanguage,
  }) async {
    // Schedule notification only on supported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    if (session.endAtEpochMs == null) return;

    final notificationId = 1000 + session.slotIndex;
    // Use v2 channel (user-configured on Android 8+).
    final channelId = 'gt.alarm.timeup.${config.soundKey}.v2';

    // Cancel existing notifications with the same ID. Otherwise Android may treat this as an
    // update and suppress alerting behaviour (sound/vibration).
    if (Platform.isAndroid) {
      await _plugin.cancel(notificationId);
    }

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

    // Explicitly specify the sound resource for scheduled notifications.
    final soundResource = _soundKeyToResource(config.soundKey);

    // Determine language for notification content
    final bool useChineseText;
    if (ttsLanguage != null) {
      useChineseText = ttsLanguage.startsWith('zh');
    } else {
      // Fall back to system language detection
      final systemLocale = Platform.localeName;
      useChineseText = systemLocale.startsWith('zh');
    }
    final notificationBody = useChineseText ? '时间到!' : 'Time is up!';
    final stopButtonText = useChineseText ? '停止' : 'Stop';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Alarm',
      channelDescription: 'Time up notification',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      // Enable sound and vibration based on user settings.
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundResource),
      enableVibration: enableVibration,
      // Ensure this notification can alert.
      onlyAlertOnce: false,
      // Set as non-persistent until user action
      ongoing: false,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(
          _actionIdStop,
          stopButtonText,
          showsUserInterface: true,
        ),
      ],
      // Use ALARM audio usage for pre-Android O devices. On Android O+ the channel controls this.
      audioAttributesUsage: AudioAttributesUsage.alarm,
      // Repeat the sound until the user cancels the notification (Android only).
      additionalFlags: Platform.isAndroid && repeatSoundUntilStopped
          ? Int32List.fromList(const <int>[_androidFlagInsistent])
          : null,
    );

    final details = NotificationDetails(android: androidDetails);

    // MIUI/Android 15 can delay or silence scheduled notifications unless they are scheduled
    // as alarm clocks. Try alarmClock first for best lockscreen reliability.
    try {
      await _plugin.zonedSchedule(
        notificationId,
        config.name,
        notificationBody,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: payload,
      );
    } catch (e) {
      // Fallback chain: exactAllowWhileIdle -> inexactAllowWhileIdle.
      try {
        await _plugin.zonedSchedule(
          notificationId,
          config.name,
          notificationBody,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          notificationId,
          config.name,
          notificationBody,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      }
    }
  }

  @override
  Future<void> cancelTimeUp({
    required TimerId timerId,
    required int slotIndex,
  }) async {
    // Cancel notification only on supported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    final notificationId = 1000 + slotIndex;
    await _plugin.cancel(notificationId);
  }

  @override
  Future<void> cancelAll() async {
    // Cancel notifications only on supported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    await _plugin.cancelAll();
  }

  @override
  Future<void> showTimeUpNow({
    required TimerSession session,
    required TimerConfig config,
    bool enableVibration = true,
    bool playSound = false,
    bool repeatSoundUntilStopped = false,
    String? ttsLanguage,
  }) async {
    // Show notification only on supported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final notificationId = 1000 + session.slotIndex;
    // Use v2 channel (user-configured on Android 8+).
    final channelId = 'gt.alarm.timeup.${config.soundKey}.v2';
    final soundResource = _soundKeyToResource(config.soundKey);

    // Cancel any pending notifications with the same ID to avoid update-suppressed alerting.
    if (Platform.isAndroid) {
      await _plugin.cancel(notificationId);
    }

    final payload = jsonEncode({
      'v': 1,
      'type': 'time_up',
      'modeId': session.modeId,
      'slotIndex': session.slotIndex,
      'timerId': session.timerId,
      'endAtEpochMs': session.endAtEpochMs,
      'soundKey': config.soundKey,
    });

    // Determine language for notification content
    final bool useChineseText;
    if (ttsLanguage != null) {
      useChineseText = ttsLanguage.startsWith('zh');
    } else {
      // Fall back to system language detection
      final systemLocale = Platform.localeName;
      useChineseText = systemLocale.startsWith('zh');
    }
    final notificationBody = useChineseText ? '时间到!' : 'Time is up!';
    final stopButtonText = useChineseText ? '停止' : 'Stop';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Alarm',
      channelDescription: 'Time up notification',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      // Allow caller to decide whether this immediate notification should play sound.
      //
      // On Android 8+ the channel controls the actual sound, but playSound still
      // controls whether sound is enabled for the notification instance.
      playSound: playSound,
      sound: playSound
          ? RawResourceAndroidNotificationSound(soundResource)
          : null,
      // Control vibration based on user settings.
      enableVibration: enableVibration,
      onlyAlertOnce: false,
      actions: [
        AndroidNotificationAction(
          _actionIdStop,
          stopButtonText,
          showsUserInterface: true,
        ),
      ],
      // Use ALARM audio usage for pre-Android O devices. On Android O+ the channel controls this.
      audioAttributesUsage: AudioAttributesUsage.alarm,
      // Repeat the sound until the user cancels the notification (Android only).
      additionalFlags:
          Platform.isAndroid && playSound && repeatSoundUntilStopped
          ? Int32List.fromList(const <int>[_androidFlagInsistent])
          : null,
    );

    final details = NotificationDetails(android: androidDetails);

    // Show notification immediately
    await _plugin.show(
      notificationId,
      config.name,
      notificationBody,
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
