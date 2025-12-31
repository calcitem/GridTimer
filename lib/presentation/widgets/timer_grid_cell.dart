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
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) {
      return const SizedBox.shrink();
    }
    final l10n = l10nNullable;

    final color = _getStatusColor(session.status);
    final presetMinutes = (config.presetDurationMs / 60000).round();

    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16), // Rounder corners
          border: Border.all(
            color: session.status == TimerStatus.ringing
                ? const Color(
                    0xFFFFD600,
                  ) // Bright yellow border when ringing, highest alert contrast
                : (session.status == TimerStatus.idle
                      ? Colors.white54
                      : Colors.white), // White border for other states
            width: session.status == TimerStatus.ringing
                ? 6
                : 2, // Thicker border when ringing
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
            fontSize: 24, // Increased font size
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD600), // Bright yellow label, high contrast
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
          style: const TextStyle(
            fontSize: 22, // Increased font size
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: Color(0xFFFFD600), // Bright yellow
            fontFeatures: [FontFeature.tabularFigures()],
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
                  style: const TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: Colors
                        .white, // Always pure white, maintaining highest contrast
                    height: 1.0,
                    fontFeatures: [FontFeature.tabularFigures()],
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
            fontSize: 24, // Increased
            fontWeight: FontWeight.bold,
            color: isPaused
                ? const Color(0xFFFFD600)
                : Colors.white, // Bright yellow reminder when paused
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
        // Idle state: dark gray background, high contrast
        return const Color(0xFF212121);
      case TimerStatus.running:
        // Running: dark green background (avoid too bright, but maintain clear hue)
        return const Color(0xFF1B5E20);
      case TimerStatus.paused:
        // Paused: deep amber/brown background
        return const Color(
          0xFFBF360C,
        ); // Deep orange, better than yellow for background with white text
      case TimerStatus.ringing:
        // Ringing: deep red background
        return const Color(0xFFB71C1C);
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmStartTitle),
        content: SingleChildScrollView(child: Text(l10n.confirmStart)),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: _buildTileButton(
                  icon: Icons.close,
                  label: l10n.actionCancel,
                  color: const Color(0xFF424242), // Dark gray
                  onPressed: () => Navigator.pop(context),
                  isHorizontal: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTileButton(
                  icon: Icons.play_arrow,
                  label: l10n.actionStart,
                  color: const Color(0xFFFFD600), // Bright yellow
                  textColor: Colors.black, // Black text
                  onPressed: () {
                    Navigator.pop(context);
                    _startTimer(ref);
                  },
                  isHorizontal: true,
                ),
              ),
            ],
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.timerActions),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTileButton(
                        icon: Icons.pause,
                        label: l10n.actionPause,
                        color: const Color(0xFFFFD600), // Bright yellow
                        textColor: Colors.black, // Black text
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(timerServiceProvider).pause(session.timerId);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTileButton(
                        icon: Icons.refresh,
                        label: l10n.actionReset,
                        color: const Color(0xFF2979FF), // Bright blue
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(timerServiceProvider).reset(session.timerId);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildTileButton(
                  icon: Icons.close,
                  label: l10n.actionCancel,
                  color: const Color(
                    0xFF424242,
                  ), // Dark gray background, deeper than before, stronger text contrast
                  onPressed: () => Navigator.pop(context),
                  isHorizontal: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPausedActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.timerActions),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTileButton(
                        icon: Icons.play_arrow,
                        label: l10n.actionResume,
                        color: Colors.green.shade700,
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(timerServiceProvider)
                              .resume(session.timerId);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTileButton(
                        icon: Icons.refresh,
                        label: l10n.actionReset,
                        color: Colors.blue.shade700,
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(timerServiceProvider).reset(session.timerId);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildTileButton(
                  icon: Icons.close,
                  label: l10n.actionCancel,
                  color: const Color(0xFF424242), // Dark gray
                  onPressed: () => Navigator.pop(context),
                  isHorizontal: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRingingActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.timerRinging),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTileButton(
                icon: Icons.stop_circle_outlined,
                label: l10n.stopAlarm,
                color: const Color(0xFFD50000), // Bright red
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(timerServiceProvider).stopRinging(session.timerId);
                },
                isLarge: true,
              ),
              const SizedBox(height: 16),
              _buildTileButton(
                icon: Icons.close,
                label: l10n.actionCancel,
                color: const Color(0xFF424242), // Dark gray
                onPressed: () => Navigator.pop(context),
                isHorizontal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build tile-style button
  /// When [isHorizontal] is true, button has smaller height with horizontal content layout
  Widget _buildTileButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    Color textColor = Colors.white, // Default white text
    bool isLarge = false,
    bool isHorizontal = false,
  }) {
    final child = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(isHorizontal ? 8 : 16),
      child: Container(
        padding: EdgeInsets.all(isHorizontal ? 20 : 16),
        alignment: Alignment.center,
        child: isHorizontal
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: textColor,
                  ), // Use custom text color
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Use custom text color
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: isLarge ? 80 : 56, color: textColor),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: isLarge ? 28 : 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );

    if (isHorizontal) {
      return Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: child,
      );
    } else {
      // Force square aspect ratio for tile effect
      return AspectRatio(
        aspectRatio: 1.0,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      );
    }
  }
}
