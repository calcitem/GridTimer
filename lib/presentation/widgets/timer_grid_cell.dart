import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_config.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';

/// A single cell in the 3x3 timer grid.
class TimerGridCell extends ConsumerStatefulWidget {
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
  ConsumerState<TimerGridCell> createState() => _TimerGridCellState();
}

class _TimerGridCellState extends ConsumerState<TimerGridCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize flash animation controller for red flashing effect
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Define color animation from deep red to bright red
    _colorAnimation = ColorTween(
      begin: const Color(0xFFB71C1C), // Deep red
      end: const Color(0xFFFF1744), // Bright red
    ).animate(_flashController);

    // Note: Animation will be started in build() after settings are available
  }

  @override
  void didUpdateWidget(TimerGridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animation control is now handled in build() to access settings
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clock = ref.watch(clockProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    // Default to true (flash enabled) if settings are not yet loaded
    final flashEnabled = settingsAsync.value?.flashEnabled ?? true;
    final showMinutesSeconds =
        settingsAsync.value?.showMinutesSecondsFormat ?? true;
    final remainingMs = widget.session.calculateRemaining(clock.nowEpochMs());
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) {
      return const SizedBox.shrink();
    }
    final l10n = l10nNullable;

    final isRinging = widget.session.status == TimerStatus.ringing;
    final shouldFlash = isRinging && flashEnabled;

    // Control flash animation based on ringing status and settings
    if (shouldFlash && !_flashController.isAnimating) {
      _flashController.repeat(reverse: true);
    } else if (!shouldFlash && _flashController.isAnimating) {
      _flashController.stop();
      _flashController.reset();
    }

    final color = _getStatusColor(widget.session.status);
    final presetMinutes = (widget.config.presetDurationMs / 60000).round();

    // Build semantic label for screen readers
    final String semanticLabel = _buildSemanticLabel(
      l10n,
      presetMinutes,
      remainingMs,
      showMinutesSeconds,
    );
    final String semanticHint = _buildSemanticHint(l10n);

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: () => _handleTap(context, ref),
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            return Container(
            decoration: BoxDecoration(
              // Use animated color only when flash is enabled and ringing
              color: shouldFlash ? _colorAnimation.value : color,
              borderRadius: BorderRadius.circular(16), // Rounder corners
              border: Border.all(
                color: isRinging
                    ? const Color(
                        0xFFFFD600,
                      ) // Bright yellow border when ringing, highest alert contrast
                    : (widget.session.status == TimerStatus.idle
                          ? Colors.white54
                          : Colors.white), // White border for other states
                width: isRinging ? 6 : 2, // Thicker border when ringing
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: _buildContent(
              context,
              l10n,
              presetMinutes,
              remainingMs,
              showMinutesSeconds,
            ),
            );
          },
        ),
      ),
    );
  }

  /// Build cell content based on timer status
  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    int presetMinutes,
    int remainingMs,
    bool showMinutesSeconds,
  ) {
    switch (widget.session.status) {
      case TimerStatus.idle:
        // Initial state: show preset duration
        return _buildIdleContent(l10n, presetMinutes);
      case TimerStatus.running:
      case TimerStatus.paused:
        // Running/paused state: show total and remaining time
        return _buildActiveContent(
          l10n,
          presetMinutes,
          remainingMs,
          showMinutesSeconds,
        );
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
    bool showMinutesSeconds,
  ) {
    final remainingSeconds = (remainingMs / 1000).ceil();
    final isPaused = widget.session.status == TimerStatus.paused;

    // Format remaining time based on user preference
    final String displayTime;
    if (showMinutesSeconds) {
      // Display in MM:SS format
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      displayTime =
          '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
    } else {
      // Display total seconds
      displayTime = '$remainingSeconds';
    }

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
        // Middle: remaining time (large font)
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  displayTime,
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

  /// Build semantic label for screen readers
  String _buildSemanticLabel(
    AppLocalizations l10n,
    int presetMinutes,
    int remainingMs,
    bool showMinutesSeconds,
  ) {
    final slotNumber = widget.slotIndex + 1;
    switch (widget.session.status) {
      case TimerStatus.idle:
        return '${l10n.gridSlot(slotNumber)}, $presetMinutes ${l10n.minutes}, ${l10n.timerIdle}';
      case TimerStatus.running:
        final remainingSeconds = (remainingMs / 1000).ceil();
        final String timeText;
        if (showMinutesSeconds) {
          final minutes = remainingSeconds ~/ 60;
          final seconds = remainingSeconds % 60;
          timeText = '$minutes ${l10n.minutes} $seconds ${l10n.seconds}';
        } else {
          timeText = '$remainingSeconds ${l10n.seconds}';
        }
        return '${l10n.gridSlot(slotNumber)}, $presetMinutes ${l10n.minutes}, ${l10n.timerRunning}, $timeText ${l10n.remainingSeconds}';
      case TimerStatus.paused:
        final remainingSeconds = (remainingMs / 1000).ceil();
        final String timeText;
        if (showMinutesSeconds) {
          final minutes = remainingSeconds ~/ 60;
          final seconds = remainingSeconds % 60;
          timeText = '$minutes ${l10n.minutes} $seconds ${l10n.seconds}';
        } else {
          timeText = '$remainingSeconds ${l10n.seconds}';
        }
        return '${l10n.gridSlot(slotNumber)}, $presetMinutes ${l10n.minutes}, ${l10n.timerPaused}, $timeText ${l10n.remainingSeconds}';
      case TimerStatus.ringing:
        return '${l10n.gridSlot(slotNumber)}, $presetMinutes ${l10n.minutes}, ${l10n.timerRinging}, ${l10n.timeUp}';
    }
  }

  /// Build semantic hint for screen readers
  String _buildSemanticHint(AppLocalizations l10n) {
    switch (widget.session.status) {
      case TimerStatus.idle:
        return l10n.actionStart;
      case TimerStatus.running:
        return '${l10n.actionPause}, ${l10n.actionReset}';
      case TimerStatus.paused:
        return '${l10n.actionResume}, ${l10n.actionReset}';
      case TimerStatus.ringing:
        return l10n.stopAlarm;
    }
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

    switch (widget.session.status) {
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
    timerService.start(
      modeId: widget.session.modeId,
      slotIndex: widget.slotIndex,
    );
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
                          ref
                              .read(timerServiceProvider)
                              .pause(widget.session.timerId);
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
                          ref
                              .read(timerServiceProvider)
                              .reset(widget.session.timerId);
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
                              .resume(widget.session.timerId);
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
                          ref
                              .read(timerServiceProvider)
                              .reset(widget.session.timerId);
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
                  ref
                      .read(timerServiceProvider)
                      .stopRinging(widget.session.timerId);
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
    final child = Semantics(
      button: true,
      label: label,
      enabled: true,
      child: InkWell(
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
