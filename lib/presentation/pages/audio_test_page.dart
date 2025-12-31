import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';

/// Audio test page - for diagnosing sound issues
class AudioTestPage extends ConsumerStatefulWidget {
  const AudioTestPage({super.key});

  @override
  ConsumerState<AudioTestPage> createState() => _AudioTestPageState();
}

class _AudioTestPageState extends ConsumerState<AudioTestPage> {
  final AudioPlayer _testPlayer = AudioPlayer();
  String _log = '';

  void _addLog(String message) {
    setState(() {
      _log += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
    debugPrint('[AudioTest] $message');
  }

  @override
  void dispose() {
    _testPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Please test the following features in order and observe if sound is output.\n'
                  'If a test fails, the corresponding feature has a problem.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test 1: Play audio file directly
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

            // Test 4: Real timer test (lockscreen scenario)
            _buildTestButton(
              title: 'Test 4: Start 10-Second Timer',
              description: 'Start real timer, fully test playback modes and custom audio (can test with lockscreen)',
              onPressed: _testScheduleNotification,
            ),

            const SizedBox(height: 24),

            // Log output
            const Text(
              'Test Log:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                  _log.isEmpty ? 'Waiting for test...' : _log,
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
              child: const Text('Clear Log'),
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              child: const Text('Start Test'),
            ),
          ],
        ),
      ),
    );
  }

  // Test 1: Play audio directly
  Future<void> _testDirectAudioPlay() async {
    _addLog('[Test 1] Starting direct playback of sound.wav');
    try {
      await _testPlayer.stop();
      await _testPlayer.play(AssetSource('sounds/sound.wav'));
      _addLog('[Test 1] ✅ Playback command sent');
      _addLog('[Test 1] Please confirm if you hear sound');
    } catch (e) {
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
    try {
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
      
      await notificationService.showTimeUpNow(
        session: testSession,
        config: testConfig,
      );
      
      _addLog('[Test 3] ✅ Immediate notification displayed');
      _addLog('[Test 3] Please check:');
      _addLog('  - Do you see the notification?');
      _addLog('  - Do you hear notification sound?');
      _addLog('  - Is there vibration?');
    } catch (e) {
      _addLog('[Test 3] ❌ Error: $e');
    }
  }

  // Test 4: Start real timer (full ringing test, supports all playback modes and custom audio)
  Future<void> _testScheduleNotification() async {
    _addLog('[Test 4] Starting 10-second timer (full ringing test)');
    try {
      final timerService = ref.read(timerServiceProvider);
      final audioService = ref.read(audioServiceProvider);
      final settings = ref.read(appSettingsProvider).value;
      
      // Start a real 10-second timer (slot 0 is 10 seconds)
      await timerService.start(modeId: 'default', slotIndex: 0);
      
      _addLog('[Test 4] ✅ 10-second timer started');
      _addLog('[Test 4] 💡 This is a real timer that will:');
      _addLog('  - Use your configured playback mode: ${_getModeDescription(settings)}');
      _addLog('  - Support custom audio files');
      _addLog('  - Show notification when locked');
      _addLog('  - Stop by tapping notification or screen');
      _addLog('[Test 4] You can lock screen now, wait 10 seconds...');
      
      // Wait for timer to complete (10 seconds + 1 second buffer)
      await Future.delayed(const Duration(seconds: 11));
      
      // Check if alarm is ringing
      final isPlaying = await audioService.isPlaying();
      if (isPlaying) {
        _addLog('[Test 4] ✅ Audio is playing');
        _addLog('[Test 4] Please tap screen or notification Stop button to stop');
      } else {
        _addLog('[Test 4] ⚠️ Audio not playing (may have auto-stopped)');
      }
    } catch (e) {
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

