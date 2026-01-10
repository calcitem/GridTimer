import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';

const _systemSettingsChannel = MethodChannel(
  'com.calcitem.gridtimer/system_settings',
);

void _debugLogTest(
  String location,
  String message,
  Map<String, dynamic> data,
  String hypothesisId,
) {
  final entry = jsonEncode({
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'sessionId': 'debug-session',
    'hypothesisId': hypothesisId,
  });
  debugPrint('[AGENT_DEBUG] $entry');
}

/// Audio test page - for diagnosing sound issues
class AudioTestPage extends ConsumerStatefulWidget {
  const AudioTestPage({super.key});

  @override
  ConsumerState<AudioTestPage> createState() => _AudioTestPageState();
}

class _AudioTestPageState extends ConsumerState<AudioTestPage> {
  AudioPlayer? _testPlayer;
  String _log = '';

  bool get _isWindows => !kIsWeb && Platform.isWindows;

  @override
  void initState() {
    super.initState();
    // Avoid using audioplayers directly on Windows because it may crash due to
    // platform channel messages being sent from a non-platform thread.
    if (!_isWindows) {
      _testPlayer = AudioPlayer();
    }
  }

  void _addLog(String message) {
    setState(() {
      _log += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
    debugPrint('[AudioTest] $message');
  }

  @override
  void dispose() {
    _testPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.audioTest)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.audioTestInstructions,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test 1: Play audio file directly
            if (!_isWindows)
              _buildTestButton(
                title: 'Test 1: AudioPlayer Playback',
                description: 'Directly play sound.wav using AudioPlayer',
                onPressed: _testDirectAudioPlay,
              ),

            // Test 2: Play using service
            _buildTestButton(
              title: 'Test 2: AudioService Playback',
              description: 'Play through AudioService (method used in app)',
              onPressed: _testAudioServicePlay,
            ),

            // Test 3: Show immediate notification
            _buildTestButton(
              title: 'Test 3: Show Immediate Notification',
              description: 'Display notification and play notification sound',
              onPressed: _testShowNotification,
            ),

            // Test 3b: Show notification with system default sound
            _buildTestButton(
              title: 'Test 3b: Notification with System Sound',
              description:
                  'Display notification using system DEFAULT sound (not custom)',
              onPressed: _testShowNotificationWithSystemSound,
            ),

            // Test 3c: Open MIUI notification settings
            _buildTestButton(
              title: 'Test 3c: Open App Notification Settings',
              description:
                  'Open system settings to check/enable notification sound for this app (MIUI fix)',
              onPressed: _openAppNotificationSettings,
            ),

            // Test 3d: Play system tones directly (bypass notifications)
            _buildTestButton(
              title: 'Test 3d: Play System Notification Tone',
              description:
                  'Play system notification tone via RingtoneManager (no notification involved)',
              onPressed: () => _playSystemTone(type: 'notification'),
            ),
            _buildTestButton(
              title: 'Test 3e: Play System Alarm Tone',
              description:
                  'Play system alarm tone via RingtoneManager (no notification involved)',
              onPressed: () => _playSystemTone(type: 'alarm'),
            ),
            _buildTestButton(
              title: 'Test 3f: Stop System Tone',
              description: 'Stop the system tone started by Test 3d/3e',
              onPressed: _stopSystemTone,
            ),

            _buildTestButton(
              title:
                  'Test 3g: Native Notification (NOTIFICATION usage + raw sound)',
              description:
                  'Native NotificationCompat, channel sound usage=notification',
              onPressed: () => _nativeNotificationTest(
                channelId: 'gt.native.test.notif.raw',
                usage: 'notification',
                sound: 'raw',
                notificationId: 88001,
              ),
            ),
            _buildTestButton(
              title: 'Test 3h: Native Notification (ALARM usage + raw sound)',
              description:
                  'Native NotificationCompat, channel sound usage=alarm',
              onPressed: () => _nativeNotificationTest(
                channelId: 'gt.native.test.alarm.raw',
                usage: 'alarm',
                sound: 'raw',
                notificationId: 88002,
              ),
            ),
            _buildTestButton(
              title:
                  'Test 3i: Native Notification (ALARM usage + default ALARM sound)',
              description:
                  'Native NotificationCompat, channel sound=system default alarm',
              onPressed: () => _nativeNotificationTest(
                channelId: 'gt.native.test.alarm.default',
                usage: 'alarm',
                sound: 'defaultAlarm',
                notificationId: 88003,
              ),
            ),

            _buildTestButton(
              title: 'Test 5a: Start Foreground Alarm Loop (raw)',
              description:
                  'Start native foreground service looping raw sound (workaround for MIUI)',
              onPressed: () =>
                  _startAlarmSoundService(sound: 'raw', loop: true),
            ),
            _buildTestButton(
              title: 'Test 5b: Stop Foreground Alarm Loop',
              description: 'Stop the native foreground alarm sound service',
              onPressed: _stopAlarmSoundService,
            ),

            // Test 4: Real timer test (lockscreen scenario)
            _buildTestButton(
              title: 'Test 4: Start 10-Second Timer',
              description:
                  'Start real timer, fully test playback modes and custom audio (can test with lockscreen)',
              onPressed: _testScheduleNotification,
            ),

            const SizedBox(height: 24),

            // Log output
            Text(
              l10n.testLog,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  _log.isEmpty ? l10n.waitingForTest : _log,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Courier',
                    color: Colors.green,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _log = '';
                });
              },
              child: Text(l10n.clearLog),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return ElevatedButton(
                  onPressed: onPressed,
                  child: Text(l10n?.startTest ?? 'Start Test'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Test 1: Play audio directly
  Future<void> _testDirectAudioPlay() async {
    if (_isWindows || _testPlayer == null) {
      _addLog(
        '[Test 1] Skipped on Windows - direct AudioPlayer playback may crash',
      );
      return;
    }

    final testPlayer = _testPlayer!;

    _addLog('[Test 1] Starting direct playback of sound.wav');
    _debugLogTest(
      'audio_test_page.dart:_testDirectAudioPlay:entry',
      'Test 1 started',
      {'playerState': testPlayer.state.toString()},
      'C',
    );

    try {
      await testPlayer.stop();

      _debugLogTest(
        'audio_test_page.dart:_testDirectAudioPlay:beforePlay',
        'About to play',
        {
          'assetPath': 'sounds/sound.wav',
          'playerState': testPlayer.state.toString(),
        },
        'C',
      );

      await testPlayer.play(AssetSource('sounds/sound.wav'));

      _debugLogTest(
        'audio_test_page.dart:_testDirectAudioPlay:afterPlay',
        'Play command sent',
        {'playerState': testPlayer.state.toString()},
        'C',
      );

      _addLog('[Test 1] ✅ Playback command sent');
      _addLog('[Test 1] Please confirm if you hear sound');
    } catch (e, stackTrace) {
      _debugLogTest(
        'audio_test_page.dart:_testDirectAudioPlay:error',
        'Test 1 error',
        {
          'error': e.toString(),
          'stackTrace': stackTrace.toString().substring(0, 500),
        },
        'C',
      );
      _addLog('[Test 1] ❌ Error: $e');
    }
  }

  // Test 2: Play through service
  Future<void> _testAudioServicePlay() async {
    _addLog('[Test 2] Starting playback through AudioService');
    try {
      final audioService = ref.read(audioServiceProvider);
      await audioService.playLoop(soundKey: 'default', volume: 1.0);
      _addLog('[Test 2] ✅ AudioService.playLoop called');
      _addLog('[Test 2] Please confirm if you hear sound (should loop)');

      // Stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () async {
        await audioService.stop();
        _addLog('[Test 2] Playback stopped');
      });
    } catch (e) {
      _addLog('[Test 2] ❌ Error: $e');
    }
  }

  // Test 3: Show immediate notification
  Future<void> _testShowNotification() async {
    _addLog('[Test 3] Starting to show immediate notification');
    _debugLogTest(
      'audio_test_page.dart:_testShowNotification:entry',
      'Test 3 started',
      {
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'platformVersion': kIsWeb ? 'web' : Platform.operatingSystemVersion,
      },
      'A,B',
    );

    try {
      // Get notification channel info before showing notification
      try {
        final channelInfo = await _systemSettingsChannel
            .invokeMethod<Map<dynamic, dynamic>>('getNotificationChannelInfo', {
              'channelId': 'gt.alarm.timeup.default.v3',
            });
        _debugLogTest(
          'audio_test_page.dart:_testShowNotification:channelInfo',
          'Notification channel info',
          {
            'channelExists': channelInfo?['exists'],
            'areNotificationsEnabled': channelInfo?['areNotificationsEnabled'],
            'interruptionFilter': channelInfo?['interruptionFilter'],
            'notificationPolicyAccessGranted':
                channelInfo?['notificationPolicyAccessGranted'],
            'channelImportance': channelInfo?['importance'],
            'channelSound': channelInfo?['sound'],
            'channelSoundEnabled': channelInfo?['soundEnabled'],
            'channelVibrationEnabled': channelInfo?['vibrationEnabled'],
            'canBypassDnd': channelInfo?['canBypassDnd'],
            'lockscreenVisibility': channelInfo?['lockscreenVisibility'],
            'audioAttributesUsage': channelInfo?['audioAttributesUsage'],
            'audioAttributesContentType':
                channelInfo?['audioAttributesContentType'],
            'alarmVolume': channelInfo?['alarmVolume'],
            'alarmVolumeMax': channelInfo?['alarmVolumeMax'],
            'notificationVolume': channelInfo?['notificationVolume'],
            'notificationVolumeMax': channelInfo?['notificationVolumeMax'],
            'ringerMode': channelInfo?['ringerMode'],
            'androidSdk': channelInfo?['androidSdk'],
            'manufacturer': channelInfo?['manufacturer'],
            'model': channelInfo?['model'],
          },
          'F,G',
        );
        _addLog(
          '[Test 3] Channel info: sound=${channelInfo?['sound']}, soundEnabled=${channelInfo?['soundEnabled']}, alarmVol=${channelInfo?['alarmVolume']}/${channelInfo?['alarmVolumeMax']}',
        );
      } catch (e) {
        _debugLogTest(
          'audio_test_page.dart:_testShowNotification:channelInfoError',
          'Failed to get channel info',
          {'error': e.toString()},
          'F',
        );
      }

      final notificationService = ref.read(notificationServiceProvider);
      final (grid, _) = ref.read(timerServiceProvider).getSnapshot();

      final testSession = TimerSession(
        timerId: 'test:0',
        modeId: 'default',
        slotIndex: 0,
        status: TimerStatus.ringing,
        lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

      final testConfig = grid.slots[0];

      _debugLogTest(
        'audio_test_page.dart:_testShowNotification:beforeShow',
        'Calling showTimeUpNow',
        {'soundKey': testConfig.soundKey, 'slotIndex': testSession.slotIndex},
        'A,B',
      );

      await notificationService.showTimeUpNow(
        session: testSession,
        config: testConfig,
        playSound: true,
      );

      _debugLogTest(
        'audio_test_page.dart:_testShowNotification:afterShow',
        'showTimeUpNow completed',
        {},
        'A',
      );

      _addLog('[Test 3] ✅ Immediate notification displayed');
      _addLog('[Test 3] Please check:');
      _addLog('  - Do you see the notification?');
      _addLog('  - Do you hear notification sound?');
      _addLog('  - Is there vibration?');
    } catch (e, stackTrace) {
      _debugLogTest(
        'audio_test_page.dart:_testShowNotification:error',
        'Test 3 error',
        {
          'error': e.toString(),
          'stackTrace': stackTrace.toString().substring(0, 500),
        },
        'A,B,E',
      );
      _addLog('[Test 3] ❌ Error: $e');
    }
  }

  // Test 3c: Open app notification settings (for MIUI)
  Future<void> _openAppNotificationSettings() async {
    _addLog('[Test 3c] Opening app notification settings...');
    _debugLogTest(
      'audio_test_page.dart:_openAppNotificationSettings:entry',
      'Opening notification settings',
      {},
      'K',
    );

    try {
      // Try to open the notification channel settings directly
      await _systemSettingsChannel.invokeMethod<void>(
        'openNotificationChannelSettings',
        {'channelId': 'gt.alarm.timeup.default.v3'},
      );

      _addLog('[Test 3c] ✅ Settings opened');
      _addLog('[Test 3c] 📋 MIUI Users: Please check the following:');
      _addLog('  1. Make sure "Timer Alarm" channel is enabled');
      _addLog('  2. Check if sound is set (not "None")');
      _addLog('  3. Check "Allow sound" or similar option');
      _addLog('  4. Return and run Test 3 again');

      _debugLogTest(
        'audio_test_page.dart:_openAppNotificationSettings:success',
        'Settings opened',
        {},
        'K',
      );
    } catch (e) {
      _addLog('[Test 3c] ❌ Error: $e');
      _addLog('[Test 3c] Please manually go to:');
      _addLog('  Settings > Apps > Grid Timer > Notifications');
      _debugLogTest(
        'audio_test_page.dart:_openAppNotificationSettings:error',
        'Failed to open settings',
        {'error': e.toString()},
        'K',
      );
    }
  }

  // Test 3b: Show notification with system default sound
  Future<void> _testShowNotificationWithSystemSound() async {
    _addLog('[Test 3b] Testing notification with SYSTEM DEFAULT sound');
    _debugLogTest(
      'audio_test_page.dart:_testShowNotificationWithSystemSound:entry',
      'Test 3b started',
      {},
      'I,J',
    );

    try {
      // Import and use flutter_local_notifications directly
      final FlutterLocalNotificationsPlugin plugin =
          FlutterLocalNotificationsPlugin();

      // Create a test channel with system default sound (no custom sound)
      const testChannelId = 'gt.test.system_sound';

      final androidPlugin = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        // Create channel with DEFAULT system sound (no RawResourceAndroidNotificationSound)
        const channel = AndroidNotificationChannel(
          testChannelId,
          'Test System Sound',
          description: 'Test channel using system default sound',
          importance: Importance.max,
          playSound: true,
          // sound: null means use system default
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
        _addLog('[Test 3b] Created test channel with system default sound');
        _debugLogTest(
          'audio_test_page.dart:_testShowNotificationWithSystemSound:channelCreated',
          'Test channel created',
          {'channelId': testChannelId, 'useSystemDefaultSound': true},
          'I,J',
        );
      }

      // Show notification using the test channel
      const androidDetails = AndroidNotificationDetails(
        testChannelId,
        'Test System Sound',
        channelDescription: 'Test notification with system sound',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        // No custom sound - should use system default
        enableVibration: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await plugin.show(
        9999, // Different ID to not conflict
        'Test 3b',
        'This notification should play SYSTEM DEFAULT sound',
        details,
      );

      _addLog('[Test 3b] ✅ Notification shown with system default sound');
      _addLog('[Test 3b] Do you hear the system notification sound?');
      _debugLogTest(
        'audio_test_page.dart:_testShowNotificationWithSystemSound:success',
        'Test notification shown',
        {},
        'I,J',
      );
    } catch (e, stackTrace) {
      _addLog('[Test 3b] ❌ Error: $e');
      _debugLogTest(
        'audio_test_page.dart:_testShowNotificationWithSystemSound:error',
        'Test 3b error',
        {
          'error': e.toString(),
          'stackTrace': stackTrace.toString().substring(0, 500),
        },
        'I,J',
      );
    }
  }

  Future<void> _playSystemTone({required String type}) async {
    _addLog('[Test 3d/3e] Playing system tone: $type');
    _debugLogTest(
      'audio_test_page.dart:_playSystemTone:entry',
      'playSystemTone',
      {'type': type},
      'DND',
    );
    try {
      final result = await _systemSettingsChannel
          .invokeMethod<Map<dynamic, dynamic>>('playSystemTone', {
            'type': type,
          });
      _debugLogTest(
        'audio_test_page.dart:_playSystemTone:success',
        'playSystemTone success',
        {'result': result},
        'DND',
      );
      _addLog('[Test 3d/3e] ✅ playSystemTone success: uri=${result?['uri']}');
    } catch (e) {
      _debugLogTest(
        'audio_test_page.dart:_playSystemTone:error',
        'playSystemTone failed',
        {'error': e.toString()},
        'DND',
      );
      _addLog('[Test 3d/3e] ❌ playSystemTone failed: $e');
    }
  }

  Future<void> _stopSystemTone() async {
    _addLog('[Test 3f] Stopping system tone');
    _debugLogTest(
      'audio_test_page.dart:_stopSystemTone:entry',
      'stopSystemTone',
      {},
      'DND',
    );
    try {
      await _systemSettingsChannel.invokeMethod<void>('stopSystemTone');
      _debugLogTest(
        'audio_test_page.dart:_stopSystemTone:success',
        'stopSystemTone success',
        {},
        'DND',
      );
      _addLog('[Test 3f] ✅ stopped');
    } catch (e) {
      _debugLogTest(
        'audio_test_page.dart:_stopSystemTone:error',
        'stopSystemTone failed',
        {'error': e.toString()},
        'DND',
      );
      _addLog('[Test 3f] ❌ stop failed: $e');
    }
  }

  Future<void> _nativeNotificationTest({
    required String channelId,
    required String usage,
    required String sound,
    required int notificationId,
  }) async {
    _addLog('[Test 3g/3h/3i] Native notification test: $channelId');
    _debugLogTest(
      'audio_test_page.dart:_nativeNotificationTest:entry',
      'nativeShowNotificationTest',
      {
        'channelId': channelId,
        'usage': usage,
        'sound': sound,
        'notificationId': notificationId,
      },
      'L,M',
    );

    try {
      final result = await _systemSettingsChannel
          .invokeMethod<Map<dynamic, dynamic>>('nativeShowNotificationTest', {
            'channelId': channelId,
            'usage': usage,
            'sound': sound,
            'notificationId': notificationId,
          });

      _debugLogTest(
        'audio_test_page.dart:_nativeNotificationTest:nativeResult',
        'nativeShowNotificationTest result',
        {'result': result},
        'L,M',
      );

      // Fetch channel info to confirm audioAttributesUsage on device.
      final channelInfo = await _systemSettingsChannel
          .invokeMethod<Map<dynamic, dynamic>>('getNotificationChannelInfo', {
            'channelId': channelId,
          });
      _debugLogTest(
        'audio_test_page.dart:_nativeNotificationTest:channelInfo',
        'Native test channel info',
        {
          'channelId': channelId,
          'channelExists': channelInfo?['exists'],
          'channelImportance': channelInfo?['importance'],
          'channelSound': channelInfo?['sound'],
          'audioAttributesUsage': channelInfo?['audioAttributesUsage'],
          'audioAttributesContentType':
              channelInfo?['audioAttributesContentType'],
          'interruptionFilter': channelInfo?['interruptionFilter'],
        },
        'L',
      );

      _addLog('[Test 3g/3h/3i] ✅ Shown. Please tell if it had sound.');
      _addLog(
        '[Test 3g/3h/3i] Channel usage=${channelInfo?['audioAttributesUsage']} sound=${channelInfo?['sound']}',
      );
    } catch (e) {
      _debugLogTest(
        'audio_test_page.dart:_nativeNotificationTest:error',
        'nativeShowNotificationTest failed',
        {'error': e.toString()},
        'L,M',
      );
      _addLog('[Test 3g/3h/3i] ❌ Failed: $e');
    }
  }

  Future<void> _startAlarmSoundService({
    required String sound,
    required bool loop,
  }) async {
    _addLog('[Test 5a] Starting foreground alarm sound service...');
    _debugLogTest(
      'audio_test_page.dart:_startAlarmSoundService:entry',
      'startAlarmSoundService',
      {'sound': sound, 'loop': loop},
      'SVC',
    );

    try {
      final result = await _systemSettingsChannel
          .invokeMethod<Map<dynamic, dynamic>>('startAlarmSoundService', {
            'sound': sound,
            'loop': loop,
          });
      _debugLogTest(
        'audio_test_page.dart:_startAlarmSoundService:success',
        'startAlarmSoundService success',
        {'result': result},
        'SVC',
      );
      _addLog(
        '[Test 5a] ✅ Started. Please lock screen and confirm it keeps looping.',
      );
    } catch (e) {
      _debugLogTest(
        'audio_test_page.dart:_startAlarmSoundService:error',
        'startAlarmSoundService failed',
        {'error': e.toString()},
        'SVC',
      );
      _addLog('[Test 5a] ❌ Failed: $e');
    }
  }

  Future<void> _stopAlarmSoundService() async {
    _addLog('[Test 5b] Stopping foreground alarm sound service...');
    _debugLogTest(
      'audio_test_page.dart:_stopAlarmSoundService:entry',
      'stopAlarmSoundService',
      {},
      'SVC',
    );

    try {
      await _systemSettingsChannel.invokeMethod<void>('stopAlarmSoundService');
      _debugLogTest(
        'audio_test_page.dart:_stopAlarmSoundService:success',
        'stopAlarmSoundService success',
        {},
        'SVC',
      );
      _addLog('[Test 5b] ✅ Stopped.');
    } catch (e) {
      _debugLogTest(
        'audio_test_page.dart:_stopAlarmSoundService:error',
        'stopAlarmSoundService failed',
        {'error': e.toString()},
        'SVC',
      );
      _addLog('[Test 5b] ❌ Failed: $e');
    }
  }

  // Test 4: Start real timer (full ringing test, supports all playback modes and custom audio)
  Future<void> _testScheduleNotification() async {
    _addLog('[Test 4] Starting 10-second timer (full ringing test)');
    _debugLogTest(
      'audio_test_page.dart:_testScheduleNotification:entry',
      'Test 4 started',
      {
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        'platformVersion': kIsWeb ? 'web' : Platform.operatingSystemVersion,
      },
      'A,B,D,E',
    );

    try {
      final timerService = ref.read(timerServiceProvider);
      final audioService = ref.read(audioServiceProvider);
      final settings = ref.read(appSettingsProvider).value;

      _debugLogTest(
        'audio_test_page.dart:_testScheduleNotification:beforeStart',
        'Starting timer',
        {'audioPlaybackMode': settings?.audioPlaybackMode.toString() ?? 'null'},
        'A',
      );

      // Start a real 10-second timer (slot 0 is 10 seconds)
      await timerService.start(modeId: 'default', slotIndex: 0);

      _debugLogTest(
        'audio_test_page.dart:_testScheduleNotification:timerStarted',
        'Timer started',
        {},
        'A',
      );

      _addLog('[Test 4] ✅ 10-second timer started');
      _addLog('[Test 4] 💡 This is a real timer that will:');
      _addLog(
        '  - Use your configured playback mode: ${_getModeDescription(settings)}',
      );
      _addLog('  - Support custom audio files');
      _addLog('  - Show notification when locked');
      _addLog('  - Stop by tapping notification or screen');
      _addLog('[Test 4] You can lock screen now, wait 10 seconds...');

      // Wait for timer to complete (10 seconds + 1 second buffer)
      await Future.delayed(const Duration(seconds: 11));

      // Check if alarm is ringing
      final isPlaying = await audioService.isPlaying();

      _debugLogTest(
        'audio_test_page.dart:_testScheduleNotification:afterDelay',
        'Timer completed, checking audio',
        {'isPlaying': isPlaying},
        'C,D',
      );

      if (isPlaying) {
        _addLog('[Test 4] ✅ Audio is playing');
        _addLog(
          '[Test 4] Please tap screen or notification Stop button to stop',
        );
      } else {
        _addLog('[Test 4] ⚠️ Audio not playing (may have auto-stopped)');
      }
    } catch (e, stackTrace) {
      _debugLogTest(
        'audio_test_page.dart:_testScheduleNotification:error',
        'Test 4 error',
        {
          'error': e.toString(),
          'stackTrace': stackTrace.toString().substring(0, 500),
        },
        'A,B,D,E',
      );
      _addLog('[Test 4] ❌ Error: $e');
    }
  }

  String _getModeDescription(dynamic settings) {
    if (settings == null) return 'Default (loop indefinitely)';
    final mode = settings.audioPlaybackMode;
    switch (mode) {
      case AudioPlaybackMode.loopIndefinitely:
        return 'Loop indefinitely until manually stopped';
      case AudioPlaybackMode.loopForDuration:
        return 'Loop for ${settings.audioLoopDurationMinutes} minutes then auto-stop';
      case AudioPlaybackMode.loopWithInterval:
        return 'Loop N minutes, pause M minutes, loop once more';
      case AudioPlaybackMode.loopWithIntervalRepeating:
        return 'Loop N minutes, pause M minutes, repeat until stopped';
      case AudioPlaybackMode.playOnce:
        return 'Play once only';
      default:
        return 'Unknown mode';
    }
  }
}
