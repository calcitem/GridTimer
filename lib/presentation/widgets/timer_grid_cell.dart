import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/services/i_clock.dart';

/// A single cell in the 3x3 timer grid.
class TimerGridCell extends ConsumerWidget {
  final TimerSession session;
  final int slotIndex;

  const TimerGridCell({
    super.key,
    required this.session,
    required this.slotIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(clockProvider);
    final remainingMs = session.calculateRemaining(clock.nowEpochMs());
    
    final color = _getStatusColor(session.status);
    final name = 'Timer ${slotIndex + 1}';
    
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Time display
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatTime(remainingMs),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Status indicator
            Text(
              _getStatusText(session.status),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return Colors.grey.shade600;
      case TimerStatus.running:
        return Colors.green.shade600;
      case TimerStatus.paused:
        return Colors.orange.shade600;
      case TimerStatus.ringing:
        return Colors.red.shade600;
    }
  }

  String _getStatusText(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return 'Idle';
      case TimerStatus.running:
        return 'Running';
      case TimerStatus.paused:
        return 'Paused';
      case TimerStatus.ringing:
        return 'RINGING';
    }
  }

  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final hours = (minutes / 60).floor();
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${(minutes % 60).toString().padLeft(2, '0')}:'
          '${(seconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${(seconds % 60).toString().padLeft(2, '0')}';
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
        content: const Text('Other timers are running. Continue to start this timer?'),
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

