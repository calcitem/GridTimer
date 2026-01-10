import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_ce/hive.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/domain/entities/timer_config.dart';
import '../core/domain/entities/timer_session.dart';
import '../core/domain/enums.dart';
import '../core/domain/services/i_notification_service.dart';
import '../core/domain/types.dart';
import '../core/services/service_localizations.dart';

/// Android notification service implementation.
class NotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<NotificationEvent> _eventController =
      StreamController<NotificationEvent>.broadcast();

  static const MethodChannel _systemSettingsChannel = MethodChannel(
    'com.calcitem.gridtimer/system_settings',
  );

  static const String _channelGroupId = 'gt.group.timers';
  static const String _actionIdStop = 'gt.action.stop';
  static const String _silentTimeUpChannelId = 'gt.alarm.timeup.silent.v1';
  static const String _runningIndicatorChannelId = 'gt.status.running.v1';
  static const int _runningIndicatorNotificationId = 42;

  // iOS notification category for timer alarms
  static const String _iosCategoryTimerAlarm = 'TIMER_ALARM_CATEGORY';

  Future<Map<dynamic, dynamic>?> _getAndroidNotificationChannelInfo({
    required String channelId,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      return await _systemSettingsChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getNotificationChannelInfo',
        {'channelId': channelId},
      );
    } catch (_) {
      return null;
    }
  }

  /// Selects the most reliable channel ID for time-up sound on Android.
  ///
  /// - Prefer the newer alarm-stream channel (v3) to reduce interruption by other
  ///   notification sounds (e.g. IM apps).
  /// - If the alarm stream is muted (alarm volume == 0) or the channel appears
  ///   to be silenced by the user, fall back to the legacy v2 channel (if it
  ///   exists) to avoid a "no sound on lock screen" regression.
  Future<String> _selectAndroidTimeUpSoundChannelId({
    required String alarmChannelIdV3,
    required String legacyChannelIdV2,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return alarmChannelIdV3;

    final v3 = await _getAndroidNotificationChannelInfo(
      channelId: alarmChannelIdV3,
    );
    final v2 = await _getAndroidNotificationChannelInfo(
      channelId: legacyChannelIdV2,
    );

    final v2Exists = v2?['exists'] == true;

    final v3Exists = v3?['exists'] == true;
    final v3Importance = v3?['importance'] as int?;
    final v3Sound = v3?['sound'] as String?;

    final alarmVolume = v3?['alarmVolume'] as int?;

    final v3SilencedByUser =
        v3Exists &&
        (v3Importance == null ||
            v3Importance <= 0 ||
            v3Sound == null ||
            v3Sound.isEmpty);

    final alarmStreamMuted = (alarmVolume ?? 0) == 0;

    if ((alarmStreamMuted || v3SilencedByUser) && v2Exists) {
      return legacyChannelIdV2;
    }

    return alarmChannelIdV3;
  }

  @override
  Future<void> init() async {
    // Always initialize timezone data
    tz_data.initializeTimeZones();

    if (kIsWeb) return;

    // Initialize notification plugin only on supported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Windows and other desktop platforms don't support notification features yet
      return;
    }

    // Note: In release builds with shrinkResources enabled, resources not referenced
    // in the Manifest may be stripped. This project uses @mipmap/launcher_icon in the
    // Manifest, so the notification default icon should remain consistent to avoid
    // "invalid_icon / no valid small icon" crashes.
    const androidInit = AndroidInitializationSettings('ic_stat_timer');

    // iOS initialization with notification categories
    final List<DarwinNotificationCategory> iosCategories = [
      DarwinNotificationCategory(
        _iosCategoryTimerAlarm,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            _actionIdStop,
            'Stop',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),
    ];

    final iosInit = DarwinInitializationSettings(
      // Do not request permissions during app startup. Permission prompts should
      // be triggered explicitly from onboarding or settings (e.g. after showing
      // privacy policy).
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: iosCategories,
    );

    final initSettings = InitializationSettings(
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
    if (kIsWeb || !Platform.isAndroid) return;

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
      // v3: Channel audio attributes explicitly use USAGE_ALARM so alarm sound plays on
      // the alarm stream and is less likely to be interrupted by other notification sounds
      // (e.g., IM apps like WeChat/WhatsApp).
      //
      // Note: On Android 8+ notification channel properties (including sound/audio attributes)
      // cannot be changed after creation. We bump the channel version to ensure existing
      // installs migrate to the corrected audio attributes.
      final alarmChannelId = 'gt.alarm.timeup.$soundKey.v3';
      // v2: Legacy compatibility channel. Uses notification audio usage so it follows
      // notification volume. This is used as a fallback when the alarm stream is muted
      // or when the alarm channel is silenced by the user.
      final legacyChannelId = 'gt.alarm.timeup.$soundKey.v2';

      // Try with groupId first, fall back to without groupId if it fails.
      // This handles OEM ROMs where NotificationChannelGroup creation may fail.
      final alarmChannelWithGroup = AndroidNotificationChannel(
        alarmChannelId,
        'Timer Alarm ($soundKey)',
        description: 'Time up notifications for $soundKey ringtone',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          _soundKeyToResource(soundKey),
        ),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        groupId: groupCreated ? _channelGroupId : null,
      );

      try {
        await androidPlugin.createNotificationChannel(alarmChannelWithGroup);
      } catch (e) {
        // If channel creation with groupId fails, try without groupId.
        if (groupCreated) {
          final alarmChannelWithoutGroup = AndroidNotificationChannel(
            alarmChannelId,
            'Timer Alarm ($soundKey)',
            description: 'Time up notifications for $soundKey ringtone',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(
              _soundKeyToResource(soundKey),
            ),
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          );
          await androidPlugin.createNotificationChannel(
            alarmChannelWithoutGroup,
          );
        } else {
          rethrow;
        }
      }

      // Create the legacy compatibility channel (v2) for fallback.
      final legacyChannelWithGroup = AndroidNotificationChannel(
        legacyChannelId,
        'Timer Alarm ($soundKey) (compatibility)',
        description:
            'Compatibility channel (notification stream) for $soundKey',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          _soundKeyToResource(soundKey),
        ),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        groupId: groupCreated ? _channelGroupId : null,
      );

      try {
        await androidPlugin.createNotificationChannel(legacyChannelWithGroup);
      } catch (e) {
        if (groupCreated) {
          final legacyChannelWithoutGroup = AndroidNotificationChannel(
            legacyChannelId,
            'Timer Alarm ($soundKey) (compatibility)',
            description:
                'Compatibility channel (notification stream) for $soundKey',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(
              _soundKeyToResource(soundKey),
            ),
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
          );
          await androidPlugin.createNotificationChannel(
            legacyChannelWithoutGroup,
          );
        } else {
          rethrow;
        }
      }
    }

    // Create a dedicated silent channel for alarm notifications.
    //
    // This channel is used when playSound is false (e.g. if sound is managed elsewhere
    // or if we only want a visual notification).
    final silentChannelWithGroup = AndroidNotificationChannel(
      _silentTimeUpChannelId,
      'Timer Alarm',
      description: 'Time up notifications (silent)',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
      groupId: groupCreated ? _channelGroupId : null,
    );

    try {
      await androidPlugin.createNotificationChannel(silentChannelWithGroup);
    } catch (e) {
      if (groupCreated) {
        const silentChannelWithoutGroup = AndroidNotificationChannel(
          _silentTimeUpChannelId,
          'Timer Alarm',
          description: 'Time up notifications (silent)',
          importance: Importance.max,
          playSound: false,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(
          silentChannelWithoutGroup,
        );
      } else {
        rethrow;
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

    // Create an ongoing "app is running" indicator channel.
    //
    // Keep it low importance and silent, but not MIN; MIN notifications may not
    // show a status bar icon consistently across OEM ROMs.
    final runningIndicatorChannel = AndroidNotificationChannel(
      _runningIndicatorChannelId,
      'App status',
      description: 'Ongoing app running indicator',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      groupId: groupCreated ? _channelGroupId : null,
    );

    try {
      await androidPlugin.createNotificationChannel(runningIndicatorChannel);
    } catch (e) {
      if (groupCreated) {
        const runningIndicatorChannelNoGroup = AndroidNotificationChannel(
          _runningIndicatorChannelId,
          'App status',
          description: 'Ongoing app running indicator',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        );
        await androidPlugin.createNotificationChannel(
          runningIndicatorChannelNoGroup,
        );
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<bool> requestPostNotificationsPermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin == null) return false;

      final result = await androidPlugin.requestNotificationsPermission();
      return result ?? false;
    } else if (Platform.isIOS) {
      // iOS permissions should be requested explicitly (e.g. from onboarding).
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin == null) return false;

      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    return true;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

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
    if (kIsWeb || !Platform.isAndroid) return true;

    // Android 14+ requires a special app access toggle for full-screen intents.
    // There's no runtime prompt; best-effort is to navigate users to the settings page.
    try {
      await _systemSettingsChannel.invokeMethod<void>(
        'openFullScreenIntentSettings',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> scheduleTimeUp({
    required TimerSession session,
    required TimerConfig config,
    bool repeatSoundUntilStopped = false,
    bool enableVibration = true,
    String? ttsLanguage,
    bool playNotificationSound = false,
    bool preferAlarmAudioUsage = false,
  }) async {
    // Schedule notification only on supported platforms
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    if (session.endAtEpochMs == null) return;

    final notificationId = 1000 + session.slotIndex;
    // Choose channel based on playNotificationSound:
    // - If true: use a sound channel
    // - If false: use silent channel (visual notification only)
    //
    // On Android 8+, channel settings are controlled by the OS/user. A new v3 channel
    // uses alarm audio attributes to reduce interruption by other notification sounds.
    // However, if the alarm stream is muted, we fall back to the legacy v2 channel
    // (if it exists) to avoid "no sound while locked" scenarios.
    String channelId;
    if (playNotificationSound && Platform.isAndroid) {
      if (preferAlarmAudioUsage) {
        channelId = 'gt.alarm.timeup.${config.soundKey}.v3';
      } else {
        channelId = await _selectAndroidTimeUpSoundChannelId(
          alarmChannelIdV3: 'gt.alarm.timeup.${config.soundKey}.v3',
          legacyChannelIdV2: 'gt.alarm.timeup.${config.soundKey}.v2',
        );
      }
    } else {
      channelId = playNotificationSound
          ? 'gt.alarm.timeup.${config.soundKey}.v3'
          : _silentTimeUpChannelId;
    }

    // Cancel existing notifications with the same ID. Otherwise Android may treat this as an
    // update and suppress alerting behaviour (sound/vibration).
    if (Platform.isAndroid || Platform.isIOS) {
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

    // Determine language for notification content based on:
    // 1. Explicit ttsLanguage if set
    // 2. User's app language preference from Hive
    // 3. System locale as fallback
    final String effectiveLocale;
    if (ttsLanguage != null) {
      effectiveLocale = ttsLanguage;
    } else {
      // Fall back to app locale from Hive, then system locale
      String locale = kIsWeb ? 'en' : Platform.localeName;
      try {
        if (Hive.isBoxOpen('settings')) {
          final box = Hive.box('settings');
          final savedLocale = box.get('app_locale') as String?;
          if (savedLocale != null && savedLocale.isNotEmpty) {
            locale = savedLocale;
          }
        }
      } catch (_) {
        // Ignore errors, use system default
      }
      effectiveLocale = locale;
    }

    // Use service localizations for notification text
    final localizations = ServiceLocalizations(effectiveLocale);
    final notificationBody = localizations.timeIsUp;
    final stopButtonText = localizations.stop;

    // Notification.FLAG_INSISTENT: repeat sound/vibration until the notification is cancelled.
    // Using a numeric constant here keeps this Flutter code platform-independent.
    final additionalFlags = repeatSoundUntilStopped
        ? Int32List.fromList(<int>[0x00000004])
        : null;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Alarm',
      channelDescription: 'Time up notification',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      playSound: playNotificationSound,
      enableVibration: enableVibration,
      // Ensure this notification can alert.
      onlyAlertOnce: false,
      // Set as non-persistent until user action
      ongoing: false,
      autoCancel: false,
      additionalFlags: additionalFlags,
      actions: [
        AndroidNotificationAction(
          _actionIdStop,
          stopButtonText,
          showsUserInterface: true,
        ),
      ],
      // Use ALARM audio usage for pre-Android O devices. On Android O+ the channel controls this.
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    // iOS notification details
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playNotificationSound,
      // Note: For custom sounds on iOS, the sound file must be < 30 seconds
      // and in aiff, wav, or caf format. Flutter assets are automatically included
      // in the app bundle, but notification sounds need to be referenced by filename only.
      // Using default sound for now to ensure reliability across all iOS versions.
      sound: playNotificationSound
          ? null
          : null, // null = use default iOS notification sound
      badgeNumber: 1,
      categoryIdentifier: _iosCategoryTimerAlarm,
      // iOS 15+ interruption level - timeSensitive ensures notification shows even in Focus mode
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentBanner: true,
      presentList: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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
      } catch (e2) {
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
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    final notificationId = 1000 + slotIndex;
    await _plugin.cancel(notificationId);
  }

  @override
  Future<void> cancelAll() async {
    // Cancel notifications only on supported platforms
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final notificationId = 1000 + session.slotIndex;
    // Use a dedicated silent channel to avoid double-playing sound on Android.
    final channelId = _silentTimeUpChannelId;

    // Cancel any pending notifications with the same ID to avoid update-suppressed alerting.
    if (Platform.isAndroid || Platform.isIOS) {
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

    // Determine language for notification content based on:
    // 1. Explicit ttsLanguage if set
    // 2. User's app language preference from Hive
    // 3. System locale as fallback
    final String effectiveLocale;
    if (ttsLanguage != null) {
      effectiveLocale = ttsLanguage;
    } else {
      // Fall back to app locale from Hive, then system locale
      String locale = kIsWeb ? 'en' : Platform.localeName;
      try {
        if (Hive.isBoxOpen('settings')) {
          final box = Hive.box('settings');
          final savedLocale = box.get('app_locale') as String?;
          if (savedLocale != null && savedLocale.isNotEmpty) {
            locale = savedLocale;
          }
        }
      } catch (_) {
        // Ignore errors, use system default
      }
      effectiveLocale = locale;
    }

    // Use service localizations for notification text
    final localizations = ServiceLocalizations(effectiveLocale);
    final notificationBody = localizations.timeIsUp;
    final stopButtonText = localizations.stop;

    // Notification.FLAG_INSISTENT: repeat sound/vibration until the notification is cancelled.
    // Using a numeric constant here keeps this Flutter code platform-independent.
    final additionalFlags = repeatSoundUntilStopped
        ? Int32List.fromList(<int>[0x00000004])
        : null;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Timer Alarm',
      channelDescription: 'Time up notification',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      // The channel is silent; keep playSound false regardless of the parameter.
      playSound: false,
      // Control vibration based on user settings.
      enableVibration: enableVibration,
      onlyAlertOnce: false,
      additionalFlags: additionalFlags,
      actions: [
        AndroidNotificationAction(
          _actionIdStop,
          stopButtonText,
          showsUserInterface: true,
        ),
      ],
      // Use ALARM audio usage for pre-Android O devices. On Android O+ the channel controls this.
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    // iOS notification details
    final iosDetailsNow = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false, // Sound is managed by in-app audio service
      badgeNumber: 1,
      categoryIdentifier: _iosCategoryTimerAlarm,
      // iOS 15+ interruption level - timeSensitive ensures notification shows even in Focus mode
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentBanner: true,
      presentList: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetailsNow,
    );

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

  @override
  Future<Map<dynamic, dynamic>?> getChannelInfo({
    required String channelId,
  }) async {
    return _getAndroidNotificationChannelInfo(channelId: channelId);
  }

  @override
  Future<void> showAppRunningIndicator() async {
    if (kIsWeb || !Platform.isAndroid) return;

    // Determine effective locale for app running indicator
    String effectiveLocale = kIsWeb ? 'en' : Platform.localeName;
    try {
      if (Hive.isBoxOpen('settings')) {
        final box = Hive.box('settings');
        final savedLocale = box.get('app_locale') as String?;
        if (savedLocale != null && savedLocale.isNotEmpty) {
          effectiveLocale = savedLocale;
        }
      }
    } catch (_) {
      // Ignore errors, use system default
    }

    // Use service localizations for app running indicator
    final localizations = ServiceLocalizations(effectiveLocale);
    final title = localizations.appTitle;
    final body = localizations.running;

    final androidDetails = const AndroidNotificationDetails(
      _runningIndicatorChannelId,
      'App status',
      channelDescription: 'Ongoing app running indicator',
      importance: Importance.low,
      priority: Priority.low,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.private,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      icon: 'ic_stat_timer',
    );

    await _plugin.show(
      _runningIndicatorNotificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  @override
  Future<void> hideAppRunningIndicator() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _plugin.cancel(_runningIndicatorNotificationId);
  }

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
