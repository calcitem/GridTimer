import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';

/// 音频测试页面 - 用于诊断声音问题
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
        title: const Text('音频测试'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 测试说明
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '请依次测试以下功能，观察是否有声音输出。\n'
                  '如果某项测试失败，说明对应的功能有问题。',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 测试 1: 直接播放音频文件
            _buildTestButton(
              title: '测试 1: AudioPlayer 播放',
              description: '直接使用 AudioPlayer 播放 sound.wav',
              onPressed: _testDirectAudioPlay,
            ),

            // 测试 2: 使用服务播放
            _buildTestButton(
              title: '测试 2: AudioService 播放',
              description: '通过 AudioService 播放（应用内使用的方式）',
              onPressed: _testAudioServicePlay,
            ),

            // 测试 3: 显示即时通知
            _buildTestButton(
              title: '测试 3: 显示即时通知',
              description: '显示通知并播放通知声音',
              onPressed: _testShowNotification,
            ),

            // 测试 4: 真实计时器测试（锁屏场景）
            _buildTestButton(
              title: '测试 4: 启动10秒计时器',
              description: '启动真实计时器，完整测试播放模式和自定义音频（可锁屏测试）',
              onPressed: _testScheduleNotification,
            ),

            const SizedBox(height: 24),

            // 日志输出
            const Text(
              '测试日志:',
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
                  _log.isEmpty ? '等待测试...' : _log,
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
              child: const Text('清空日志'),
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
              child: const Text('开始测试'),
            ),
          ],
        ),
      ),
    );
  }

  // 测试 1: 直接播放音频
  Future<void> _testDirectAudioPlay() async {
    _addLog('【测试1】开始直接播放 sound.wav');
    try {
      await _testPlayer.stop();
      await _testPlayer.play(AssetSource('sounds/sound.wav'));
      _addLog('【测试1】✅ 播放命令已发送');
      _addLog('【测试1】请确认是否听到声音');
    } catch (e) {
      _addLog('【测试1】❌ 错误: $e');
    }
  }

  // 测试 2: 通过服务播放
  Future<void> _testAudioServicePlay() async {
    _addLog('【测试2】开始通过 AudioService 播放');
    try {
      final audioService = ref.read(audioServiceProvider);
      await audioService.playLoop(soundKey: 'default', volume: 1.0);
      _addLog('【测试2】✅ AudioService.playLoop 已调用');
      _addLog('【测试2】请确认是否听到声音（应该循环播放）');
      
      // 5秒后停止
      Future.delayed(const Duration(seconds: 5), () async {
        await audioService.stop();
        _addLog('【测试2】已停止播放');
      });
    } catch (e) {
      _addLog('【测试2】❌ 错误: $e');
    }
  }

  // 测试 3: 显示即时通知
  Future<void> _testShowNotification() async {
    _addLog('【测试3】开始显示即时通知');
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
      
      _addLog('【测试3】✅ 即时通知已显示');
      _addLog('【测试3】请检查：');
      _addLog('  - 是否看到通知？');
      _addLog('  - 是否听到通知声音？');
      _addLog('  - 是否有振动？');
    } catch (e) {
      _addLog('【测试3】❌ 错误: $e');
    }
  }

  // 测试 4: 启动真实计时器（完整响铃测试，支持所有播放模式和自定义音频）
  Future<void> _testScheduleNotification() async {
    _addLog('【测试4】启动 5 秒计时器（完整响铃测试）');
    try {
      final timerService = ref.read(timerServiceProvider);
      final audioService = ref.read(audioServiceProvider);
      final settings = ref.read(appSettingsProvider).value;
      
      // Start a real 5-second timer (slot 1: 2 minutes by default, but we override)
      await timerService.start(modeId: 'default', slotIndex: 0); // Slot 0 is 10 seconds
      
      _addLog('【测试4】✅ 已启动 10 秒计时器');
      _addLog('【测试4】💡 这是真实的计时器，会：');
      _addLog('  - 使用你配置的播放模式: ${_getModeDescription(settings)}');
      _addLog('  - 支持自定义音频文件');
      _addLog('  - 锁屏时显示通知');
      _addLog('  - 点击通知或屏幕停止');
      _addLog('【测试4】现在可以锁屏，等待 10 秒...');
      
      // Wait for timer to complete (10 seconds + 1 second buffer)
      await Future.delayed(const Duration(seconds: 11));
      
      // Check if alarm is ringing
      final isPlaying = await audioService.isPlaying();
      if (isPlaying) {
        _addLog('【测试4】✅ 音频正在播放中');
        _addLog('【测试4】请点击屏幕或通知的 Stop 按钮停止');
      } else {
        _addLog('【测试4】⚠️ 音频未播放（可能已自动停止）');
      }
    } catch (e) {
      _addLog('【测试4】❌ 错误: $e');
    }
  }
  
  String _getModeDescription(dynamic settings) {
    if (settings == null) return '默认（一直循环）';
    final mode = settings.audioPlaybackMode;
    switch (mode) {
      case AudioPlaybackMode.loopIndefinitely:
        return '一直循环直到手动停止';
      case AudioPlaybackMode.loopForDuration:
        return '循环播放 ${settings.audioLoopDurationMinutes} 分钟后自动停止';
      case AudioPlaybackMode.loopWithInterval:
        return '循环 N 分钟，间隔 M 分钟，再循环（共一次）';
      case AudioPlaybackMode.loopWithIntervalRepeating:
        return '循环 N 分钟，间隔 M 分钟，重复直到停止';
      case AudioPlaybackMode.playOnce:
        return '只播放一次';
      default:
        return '未知模式';
    }
  }
}

