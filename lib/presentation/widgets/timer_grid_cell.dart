import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_config.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

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
        child: _buildContent(context, l10n, presetMinutes, remainingMs),
      ),
    );
  }

  /// Build cell content based on timer status
  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    int presetMinutes,
    int remainingMs,
  ) {
    switch (session.status) {
      case TimerStatus.idle:
        // Initial state: show preset duration
        return _buildIdleContent(l10n, presetMinutes);
      case TimerStatus.running:
      case TimerStatus.paused:
        // Running/paused state: show total and remaining time
        return _buildActiveContent(l10n, presetMinutes, remainingMs);
      case TimerStatus.ringing:
        // Ringing state
        return _buildRingingContent(l10n, presetMinutes);
    }
  }

  /// Build idle state content: show preset duration
  Widget _buildIdleContent(AppLocalizations l10n, int presetMinutes) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Preset duration (large font)
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
        // "minutes" label
        Text(
          l10n.minutes,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// Build running/paused state content: show total and remaining time
  Widget _buildActiveContent(
    AppLocalizations l10n,
    int presetMinutes,
    int remainingMs,
  ) {
    final remainingSeconds = (remainingMs / 1000).ceil();
    final isPaused = session.status == TimerStatus.paused;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top: preset duration label
        Text(
          '$presetMinutes ${l10n.minutes}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: isPaused ? Colors.white70 : Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        // Middle: remaining seconds (large font)
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
        // Bottom: status label
        Text(
          isPaused ? l10n.pausing : l10n.remainingSeconds,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPaused ? Colors.white70 : Colors.white,
          ),
        ),
      ],
    );
  }

  /// Build ringing state content: show time up
  Widget _buildRingingContent(AppLocalizations l10n, int presetMinutes) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top: preset duration
        Text(
          '$presetMinutes ${l10n.minutes}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        // Middle: "Time's Up" large text
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.timeUp,
                  style: const TextStyle(
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
        // Bottom: click to stop instruction
        Text(
          l10n.clickToStop,
          style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmStartTitle),
        content: Text(l10n.confirmStart),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer(ref);
            },
            child: Text(l10n.actionStart),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.timerActions),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(timerServiceProvider).pause(session.timerId);
                },
                child: Text(l10n.actionPause),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(timerServiceProvider).reset(session.timerId);
                },
                child: Text(l10n.actionReset),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(l10n.actionCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPausedActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.timerActions),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(timerServiceProvider).resume(session.timerId);
                },
                child: Text(l10n.actionResume),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(timerServiceProvider).reset(session.timerId);
                },
                child: Text(l10n.actionReset),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(l10n.actionCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRingingActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.timerRinging),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(timerServiceProvider).stopRinging(session.timerId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24), // 更大的停止按钮
                ),
                child: Text(
                  l10n.stopAlarm,
                  style: const TextStyle(fontSize: 24), // 更大的字体
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(l10n.actionCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
