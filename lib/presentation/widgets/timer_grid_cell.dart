import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_config.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';
import '../../core/theme/app_theme.dart';
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
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    // Initialize flash animation controller for red flashing effect
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
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
    final theme = ref.watch(themeProvider);
    final tokens = theme.tokens;

    // Default to true (flash enabled) if settings are not yet loaded
    final flashEnabled = settingsAsync.value?.flashEnabled ?? true;
    final showMinutesSeconds =
        settingsAsync.value?.showMinutesSecondsFormat ?? true;
    final remainingMs = widget.session.calculateRemaining(clock.nowEpochMs());
    final gridNames = settingsAsync.value?.gridNames;
    final userDefinedName =
        (gridNames != null && gridNames.length > widget.slotIndex)
            ? gridNames[widget.slotIndex].trim()
            : '';
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) {
      return const SizedBox.shrink();
    }
    final l10n = l10nNullable;

    final isRinging = widget.session.status == TimerStatus.ringing;
    final reduceMotion =
        MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;
    final shouldFlash = isRinging && flashEnabled && !reduceMotion;

    // Control flash animation based on ringing status and settings
    if (shouldFlash && !_flashController.isAnimating) {
      _flashController.repeat(reverse: true);
    } else if (!shouldFlash && _flashController.isAnimating) {
      _flashController.stop();
      _flashController.reset();
    }

    final color = _getStatusColor(widget.session.status, tokens);
    final presetDurationMs = widget.config.presetDurationMs;

    // Build semantic label for screen readers
    final String semanticLabel = _buildSemanticLabel(
      l10n,
      presetDurationMs,
      remainingMs,
      showMinutesSeconds,
    );
    final String semanticHint = _buildSemanticHint(l10n);

    // Recreate animation if needed for theme consistency (optional optimization)
    // For now we use the animation value for ringing state color oscillation

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: true,
      onTap: () => _handleTap(context, ref),
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            // If flashing, oscillate between surfaceRinging and a brighter
            // variant/danger color.
            final Color ringingColor =
                Color.lerp(
                  tokens.surfaceRinging,
                  tokens.danger,
                  _flashController.value,
                ) ??
                tokens.surfaceRinging;

            final currentColor = shouldFlash ? ringingColor : color;

            final idleBorderColor = tokens.border.withValues(alpha: 0.5);
            final baseBorderColor = widget.session.status == TimerStatus.idle
                ? idleBorderColor
                : tokens.border;

            final borderColor = isRinging
                ? tokens.focusRing
                : (_isFocused ? tokens.focusRing : baseBorderColor);

            final double borderWidth = isRinging ? 6 : (_isFocused ? 4 : 2);

            return Material(
              color: currentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor, width: borderWidth),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _handleTap(context, ref),
                onFocusChange: (hasFocus) {
                  if (hasFocus != _isFocused) {
                    setState(() => _isFocused = hasFocus);
                  }
                },
                // High contrast splash/ripple for clear feedback
                splashColor: tokens.textPrimary.withValues(alpha: 0.2),
                highlightColor: tokens.textPrimary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _buildContent(
                    context,
                    l10n,
                    presetDurationMs,
                    remainingMs,
                    showMinutesSeconds,
                    userDefinedName,
                    tokens,
                  ),
                ),
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
    int presetDurationMs,
    int remainingMs,
    bool showMinutesSeconds,
    String userDefinedName,
    AppThemeTokens tokens,
  ) {
    switch (widget.session.status) {
      case TimerStatus.idle:
        return _buildIdleContent(l10n, presetDurationMs, userDefinedName, tokens);
      case TimerStatus.running:
      case TimerStatus.paused:
        return _buildActiveContent(
          l10n,
          presetDurationMs,
          remainingMs,
          showMinutesSeconds,
          userDefinedName,
          tokens,
        );
      case TimerStatus.ringing:
        return _buildRingingContent(
          l10n,
          presetDurationMs,
          userDefinedName,
          tokens,
        );
    }
  }

  Widget _buildIdleContent(
    AppLocalizations l10n,
    int presetDurationMs,
    String userDefinedName,
    AppThemeTokens tokens,
  ) {
    final isWholeMinute = presetDurationMs % 60000 == 0;
    final minutes = presetDurationMs ~/ 60000;
    final seconds = (presetDurationMs % 60000) ~/ 1000;

    final String displayValue;
    final String? unitLabel;

    if (isWholeMinute) {
      displayValue = '$minutes';
      unitLabel = l10n.minutes;
    } else {
      displayValue = '$minutes:${seconds.toString().padLeft(2, '0')}';
      unitLabel = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Detect if cell is too flat (landscape orientation)
        final isFlat = constraints.maxWidth > constraints.maxHeight * 1.2;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display Name (scrolling if needed)
            if (userDefinedName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _AutoScrollText(
                  text: userDefinedName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tokens.textSecondary,
                    height: 1.0,
                  ),
                ),
              ),
            Expanded(
              flex: isFlat ? 1 : 3,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: tokens.textPrimary,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (unitLabel != null && !isFlat)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  unitLabel,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            if (!isFlat)
              _buildStatusRow(
                icon: Icons.timer_outlined,
                text: l10n.timerIdle,
                tokens: tokens,
              ),
          ],
        );
      },
    );
  }

  Widget _buildActiveContent(
    AppLocalizations l10n,
    int presetDurationMs,
    int remainingMs,
    bool showMinutesSeconds,
    String userDefinedName,
    AppThemeTokens tokens,
  ) {
    final remainingSeconds = (remainingMs / 1000).ceil();
    final isPaused = widget.session.status == TimerStatus.paused;

    final String displayTime;
    if (showMinutesSeconds) {
      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      displayTime =
          '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
    } else {
      displayTime = '$remainingSeconds';
    }

    final presetLabel = _formatPresetLabel(l10n, presetDurationMs);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Detect if cell is too flat (landscape orientation)
        final isFlat = constraints.maxWidth > constraints.maxHeight * 1.2;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildNameAndPresetHeader(
                isFlat: isFlat,
                userDefinedName: userDefinedName,
                presetLabel: presetLabel,
                nameColor: tokens.textPrimary,
                presetColor: tokens.textPrimary.withValues(alpha: 0.85),
              ),
            ),
            Expanded(
              flex: isFlat ? 1 : 3,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      displayTime,
                      style: TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: tokens.textPrimary, // High contrast
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isFlat)
              _buildStatusRow(
                icon: isPaused ? Icons.pause : Icons.play_arrow,
                text: isPaused ? l10n.timerPaused : l10n.timerRunning,
                tokens: tokens,
              ),
          ],
        );
      },
    );
  }

  Widget _buildRingingContent(
    AppLocalizations l10n,
    int presetDurationMs,
    String userDefinedName,
    AppThemeTokens tokens,
  ) {
    final presetLabel = _formatPresetLabel(l10n, presetDurationMs);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Detect if cell is too flat (landscape orientation)
        final isFlat = constraints.maxWidth > constraints.maxHeight * 1.2;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildNameAndPresetHeader(
                isFlat: isFlat,
                userDefinedName: userDefinedName,
                presetLabel: presetLabel,
                nameColor: tokens.textPrimary,
                presetColor: tokens.textPrimary.withValues(alpha: 0.9),
              ),
            ),
            Expanded(
              flex: isFlat ? 1 : 3,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l10n.timeUp,
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: tokens.focusRing,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isFlat)
              _buildStatusRow(
                icon: Icons.touch_app,
                text: l10n.clickToStop,
                tokens: tokens,
              ),
          ],
        );
      },
    );
  }

  String _formatPresetLabel(AppLocalizations l10n, int presetDurationMs) {
    final isWholeMinute = presetDurationMs % 60000 == 0;
    final minutes = presetDurationMs ~/ 60000;
    final seconds = (presetDurationMs % 60000) ~/ 1000;

    if (isWholeMinute) {
      return '$minutes ${l10n.minutes}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildNameAndPresetHeader({
    required bool isFlat,
    required String userDefinedName,
    required String presetLabel,
    required Color nameColor,
    required Color presetColor,
  }) {
    final name = userDefinedName.trim();
    final hasName = name.isNotEmpty;

    final nameStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w900,
      color: nameColor,
      height: 1.0,
    );
    final presetStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: presetColor,
      height: 1.0,
    );

    if (isFlat) {
      if (!hasName) {
        return Text(
          presetLabel,
          style: presetStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
      }

      return Row(
        children: [
          Expanded(
            child: _AutoScrollText(text: name, style: nameStyle),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              presetLabel,
              style: presetStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasName) _AutoScrollText(text: name, style: nameStyle),
        if (hasName) const SizedBox(height: 2),
        Text(
          presetLabel,
          style: presetStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String text,
    required AppThemeTokens tokens,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: tokens.textPrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSemanticLabel(
    AppLocalizations l10n,
    int presetDurationMs,
    int remainingMs,
    bool showMinutesSeconds,
  ) {
    final slotNumber = widget.slotIndex + 1;
    final name = widget.config.name;

    switch (widget.session.status) {
      case TimerStatus.idle:
        return '${l10n.gridSlot(slotNumber)}, $name, ${l10n.timerIdle}';
      case TimerStatus.running:
        final remainingSeconds = (remainingMs / 1000).ceil();
        final String timeText;
        if (showMinutesSeconds) {
          final rMinutes = remainingSeconds ~/ 60;
          final rSeconds = remainingSeconds % 60;
          timeText = '$rMinutes ${l10n.minutes} $rSeconds ${l10n.seconds}';
        } else {
          timeText = '$remainingSeconds ${l10n.seconds}';
        }
        return '${l10n.gridSlot(slotNumber)}, $name, ${l10n.timerRunning}, $timeText ${l10n.remainingSeconds}';
      case TimerStatus.paused:
        final remainingSeconds = (remainingMs / 1000).ceil();
        final String timeText;
        if (showMinutesSeconds) {
          final rMinutes = remainingSeconds ~/ 60;
          final rSeconds = remainingSeconds % 60;
          timeText = '$rMinutes ${l10n.minutes} $rSeconds ${l10n.seconds}';
        } else {
          timeText = '$remainingSeconds ${l10n.seconds}';
        }
        return '${l10n.gridSlot(slotNumber)}, $name, ${l10n.timerPaused}, $timeText ${l10n.remainingSeconds}';
      case TimerStatus.ringing:
        return '${l10n.gridSlot(slotNumber)}, $name, ${l10n.timerRinging}, ${l10n.timeUp}';
    }
  }

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

  Color _getStatusColor(TimerStatus status, AppThemeTokens tokens) {
    switch (status) {
      case TimerStatus.idle:
        return tokens.surfaceIdle;
      case TimerStatus.running:
        return tokens.surfaceRunning;
      case TimerStatus.paused:
        return tokens.surfacePaused;
      case TimerStatus.ringing:
        return tokens.surfaceRinging;
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    final timerService = ref.read(timerServiceProvider);

    switch (widget.session.status) {
      case TimerStatus.idle:
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

  // Helper for action dialogs to use theme
  Widget _buildTileButton({
    required IconData icon,
    required String label,
    required Color
    color, // This might need theme override or be passed semantic color
    required VoidCallback onPressed,
    Color? textColor,
    bool isLarge = false,
    bool isHorizontal = false,
  }) {
    // For dialog buttons, we should also respect the theme where possible,
    // but the original code passed specific colors.
    // We'll keep the colors passed in for now as they are specific to actions (Start=Yellow/Green, Stop=Red)
    // but we ensure text contrast is high.

    final effectiveTextColor = textColor ?? Colors.white;

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
                    Icon(icon, size: 32, color: effectiveTextColor),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: effectiveTextColor,
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
                      Icon(
                        icon,
                        size: isLarge ? 80 : 56,
                        color: effectiveTextColor,
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: isLarge ? 28 : 22,
                            fontWeight: FontWeight.bold,
                            color: effectiveTextColor,
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

  // Dialog implementations need to be updated to pass theme colors or similar
  // For brevity in this large block, I'm keeping the original dialog calls
  // but they should eventually use the theme tokens.
  // The _buildTileButton above handles the button rendering.

  void _showStartConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.read(themeProvider); // Read once for dialog
    final tokens = theme.tokens;

    if (l10n == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmStartTitle),
        content: SingleChildScrollView(
            child: Text(l10n.confirmStartBody(widget.config.name))),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: _buildTileButton(
                  icon: Icons.close,
                  label: l10n.actionCancel,
                  color: tokens.surfacePressed, // Dark gray replacement
                  onPressed: () => Navigator.pop(context),
                  isHorizontal: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTileButton(
                  icon: Icons.play_arrow,
                  label: l10n.actionStart,
                  color: tokens.accent,
                  textColor: tokens.bg, // Contrast
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
    final theme = ref.read(themeProvider);
    final tokens = theme.tokens;

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
                        color: tokens.accent,
                        textColor: tokens.bg,
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
                        color: const Color(
                          0xFF448AFF,
                        ), // High contrast blue for Reset
                        textColor: Colors.white,
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
                  color: tokens.surfacePressed,
                  textColor: tokens.textPrimary,
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
    final theme = ref.read(themeProvider);
    final tokens = theme.tokens;

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
                        color: tokens
                            .accent, // Use accent (Amber) for primary action
                        textColor: tokens.bg,
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
                        color: const Color(0xFF448AFF), // High contrast blue
                        textColor: Colors.white,
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
                  color: tokens.surfacePressed,
                  textColor: tokens.textPrimary,
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
    final theme = ref.read(themeProvider);
    final tokens = theme.tokens;

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
                color: tokens.danger,
                textColor: Colors.white, // Keep white on red for high contrast
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
                color: tokens.surfacePressed,
                textColor: tokens.textPrimary,
                onPressed: () => Navigator.pop(context),
                isHorizontal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auto-scrolling text widget for Marquee effect
class _AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _AutoScrollText({
    required this.text,
    required this.style,
  });

  @override
  State<_AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<_AutoScrollText> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _needScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Check if scrolling is needed after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkScrollNecessity();
    });
  }

  @override
  void didUpdateWidget(_AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkScrollNecessity();
      });
    }
  }

  void _checkScrollNecessity() {
    if (!_scrollController.hasClients) return;

    // If content width > container width, we need scrolling
    if (_scrollController.position.maxScrollExtent > 0) {
      if (!_needScrolling) {
        setState(() => _needScrolling = true);
        _startScrolling();
      }
    } else {
      if (_needScrolling) {
        setState(() => _needScrolling = false);
        _stopScrolling();
      }
    }
  }

  void _startScrolling() {
    _stopScrolling(); // Ensure clear previous
    _scrollLoop();
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    // Reset position if possible
    if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
    }
  }

  void _scrollLoop() {
    if (!mounted || !_needScrolling || !_scrollController.hasClients) return;

    // 1. Wait a bit at the start
    _scrollTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted || !_needScrolling) return;

        // 2. Animate to end
        final double maxExtent = _scrollController.position.maxScrollExtent;
        final double durationSeconds = maxExtent / 30; // 30 pixels per second
        final duration = Duration(milliseconds: (durationSeconds * 1000).round());

        _scrollController.animateTo(
          maxExtent,
          duration: duration,
          curve: Curves.linear,
        ).then((_) {
            if (!mounted || !_needScrolling) return;

            // 3. Wait a bit at the end
            _scrollTimer = Timer(const Duration(seconds: 1), () {
                 if (!mounted || !_needScrolling) return;

                 // 4. Animate back to start (or jump)
                 // Jumping back is better for marquee usually, but animating back is smoother
                 _scrollController.animateTo(
                    0,
                    duration: duration,
                    curve: Curves.linear,
                 ).then((_) {
                     if (!mounted || !_needScrolling) return;
                     // Loop
                     _scrollLoop();
                 });
            });
        });
    });
  }

  @override
  void dispose() {
    _stopScrolling();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.style.fontSize != null ? widget.style.fontSize! * 1.5 : 30,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Disable user scrolling while auto-scrolling
        child: Text(
          widget.text,
          style: widget.style,
        ),
      ),
    );
  }
}
