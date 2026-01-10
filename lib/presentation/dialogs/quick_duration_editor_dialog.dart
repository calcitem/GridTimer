import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// A dialog that allows users to quickly adjust the duration of a timer slot.
/// Designed for senior-friendly interaction with large buttons.
class QuickDurationEditorDialog extends StatefulWidget {
  final int initialDurationSeconds;
  final String slotName;
  final AppThemeTokens tokens;

  const QuickDurationEditorDialog({
    super.key,
    required this.initialDurationSeconds,
    required this.slotName,
    required this.tokens,
  });

  static Future<int?> show(
    BuildContext context, {
    required int initialDurationSeconds,
    required String slotName,
    required AppThemeTokens tokens,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuickDurationEditorDialog(
        initialDurationSeconds: initialDurationSeconds,
        slotName: slotName,
        tokens: tokens,
      ),
    );
  }

  @override
  State<QuickDurationEditorDialog> createState() =>
      _QuickDurationEditorDialogState();
}

class _QuickDurationEditorDialogState
    extends State<QuickDurationEditorDialog> {
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialDurationSeconds;
  }

  int get _minutes => _totalSeconds ~/ 60;
  int get _seconds => _totalSeconds % 60;

  void _addMinutes(int minutes) {
    setState(() {
      _totalSeconds += minutes * 60;
      if (_totalSeconds < 0) _totalSeconds = 0;
      if (_totalSeconds > 59940) _totalSeconds = 59940; // 999 minutes max
    });
  }

  void _addSeconds(int seconds) {
    setState(() {
      _totalSeconds += seconds;
      if (_totalSeconds < 0) _totalSeconds = 0;
      if (_totalSeconds > 59940) _totalSeconds = 59940;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        l10n.adjustTimeTitle(widget.slotName),
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: widget.tokens.textPrimary,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Large Time Display
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 280),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1976D2),
                      width: 3,
                    ),
                  ),
                  child: Text(
                    '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: widget.tokens.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
              const SizedBox(height: 20),
              // Minutes adjustment buttons
              _buildAdjustmentSection(
                label: l10n.minutes,
                buttons: [
                  _buildAdjustButton(
                    label: '-5',
                    icon: Icons.fast_rewind,
                    onPressed: () => _addMinutes(-5),
                  ),
                  _buildAdjustButton(
                    label: '-1',
                    icon: Icons.remove,
                    onPressed: () => _addMinutes(-1),
                  ),
                  _buildAdjustButton(
                    label: '+1',
                    icon: Icons.add,
                    onPressed: () => _addMinutes(1),
                  ),
                  _buildAdjustButton(
                    label: '+5',
                    icon: Icons.fast_forward,
                    onPressed: () => _addMinutes(5),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Seconds adjustment buttons
              _buildAdjustmentSection(
                label: l10n.seconds,
                buttons: [
                  _buildAdjustButton(
                    label: '-10',
                    icon: Icons.fast_rewind,
                    onPressed: () => _addSeconds(-10),
                  ),
                  _buildAdjustButton(
                    label: '-1',
                    icon: Icons.remove,
                    onPressed: () => _addSeconds(-1),
                  ),
                  _buildAdjustButton(
                    label: '+1',
                    icon: Icons.add,
                    onPressed: () => _addSeconds(1),
                  ),
                  _buildAdjustButton(
                    label: '+10',
                    icon: Icons.fast_forward,
                    onPressed: () => _addSeconds(10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  if (_totalSeconds <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.durationMustBePositive),
                        backgroundColor: widget.tokens.danger,
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop(_totalSeconds);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF1976D2), // Material Blue 700 for high contrast
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Text(
                  l10n.ok,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: widget.tokens.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: widget.tokens.surfacePressed,
                ),
                child: Text(
                  l10n.actionCancel,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    );
  }

  Widget _buildAdjustmentSection({
    required String label,
    required List<Widget> buttons,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.tokens.textPrimary,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: buttons,
        ),
      ],
    );
  }

  Widget _buildAdjustButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isNegative = label.startsWith('-');

    // Use high-contrast colors for better visibility
    final Color backgroundColor;
    final Color textColor;

    if (isNegative) {
      // Negative buttons: Red background with white text
      backgroundColor = const Color(0xFFD32F2F); // Material Red 700 (high contrast)
      textColor = Colors.white;
    } else {
      // Positive buttons: Green background with white text for better contrast
      backgroundColor = const Color(0xFF388E3C); // Material Green 700 (high contrast)
      textColor = Colors.white;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
              child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 36,
                    color: textColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
