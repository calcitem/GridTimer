import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_config.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';

/// A single cell in the 3x3 timer grid.
class TimerGridCell extends ConsumerWidget {
  final TimerSession session;
  final TimerConfig config;
  final int slotIndex;

  const TimerGridCell({
    super.key,
    required this.session,
    required this.config,
    required this.slotIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(clockProvider);
    final remainingMs = session.calculateRemaining(clock.nowEpochMs());

    final color = _getStatusColor(session.status);
    final presetMinutes = (config.presetDurationMs / 60000).round();

    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: session.status == TimerStatus.ringing
                ? Colors.red
                : Colors.grey.shade300,
            width: session.status == TimerStatus.ringing ? 4 : 2,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: _buildContent(presetMinutes, remainingMs),
      ),
    );
  }

  /// 构建格子内容，根据状态显示不同信息
  Widget _buildContent(int presetMinutes, int remainingMs) {
    switch (session.status) {
      case TimerStatus.idle:
        // 初始状态：显示预设时长（如 "5分钟"）
        return _buildIdleContent(presetMinutes);
      case TimerStatus.running:
      case TimerStatus.paused:
        // 运行/暂停状态：显示总时长和剩余时间
        return _buildActiveContent(presetMinutes, remainingMs);
      case TimerStatus.ringing:
        // 响铃状态
        return _buildRingingContent(presetMinutes);
    }
  }

  /// 初始状态：大字显示预设时长
  Widget _buildIdleContent(int presetMinutes) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 预设时长（超大字体）
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$presetMinutes',
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: Colors.white,
                    height: 1.0,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
        // "分钟" 标签
        const Text(
          '分钟',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 运行/暂停状态：显示总时长和剩余时间
  Widget _buildActiveContent(int presetMinutes, int remainingMs) {
    final remainingSeconds = (remainingMs / 1000).ceil();
    final isPaused = session.status == TimerStatus.paused;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 顶部：预设时长标签
        Text(
          '$presetMinutes 分钟',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isPaused ? Colors.white70 : Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        // 中间：剩余秒数（超大字体）
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$remainingSeconds',
                  style: TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: isPaused ? Colors.white70 : Colors.white,
                    height: 1.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 底部：状态标签
        Text(
          isPaused ? '暂停中' : '剩余秒',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPaused ? Colors.white70 : Colors.white,
          ),
        ),
      ],
    );
  }

  /// 响铃状态：显示时间到
  Widget _buildRingingContent(int presetMinutes) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 顶部：预设时长
        Text(
          '$presetMinutes 分钟',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        // 中间："时间到" 大字
        const Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '时间到',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.yellow,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        // 底部：点击停止提示
        const Text(
          '点击停止',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return Colors.blueGrey.shade700;
      case TimerStatus.running:
        return Colors.green.shade700;
      case TimerStatus.paused:
        return Colors.orange.shade700;
      case TimerStatus.ringing:
        return Colors.red.shade700;
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    final timerService = ref.read(timerServiceProvider);

    switch (session.status) {
      case TimerStatus.idle:
        // Start timer (with confirmation if others running)
        if (timerService.hasActiveTimers()) {
          _showStartConfirmation(context, ref);
        } else {
          _startTimer(ref);
        }
        break;

      case TimerStatus.running:
        _showRunningActions(context, ref);
        break;

      case TimerStatus.paused:
        _showPausedActions(context, ref);
        break;

      case TimerStatus.ringing:
        _showRingingActions(context, ref);
        break;
    }
  }

  void _showStartConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Start?'),
        content: const Text(
          'Other timers are running. Continue to start this timer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer(ref);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _startTimer(WidgetRef ref) {
    final timerService = ref.read(timerServiceProvider);
    timerService.start(modeId: session.modeId, slotIndex: slotIndex);
  }

  void _showRunningActions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Timer Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(timerServiceProvider).pause(session.timerId);
              },
              child: const Text('Pause'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(timerServiceProvider).reset(session.timerId);
              },
              child: const Text('Reset'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPausedActions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Timer Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(timerServiceProvider).resume(session.timerId);
              },
              child: const Text('Resume'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(timerServiceProvider).reset(session.timerId);
              },
              child: const Text('Reset'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRingingActions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Timer Ringing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(timerServiceProvider).stopRinging(session.timerId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Stop Alarm'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
