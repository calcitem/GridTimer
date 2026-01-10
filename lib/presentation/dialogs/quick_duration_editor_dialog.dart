import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// A dialog that allows users to quickly adjust the duration of a timer slot.
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
      builder:
          (context) => QuickDurationEditorDialog(
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

class _QuickDurationEditorDialogState extends State<QuickDurationEditorDialog> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialDurationSeconds ~/ 60;
    _seconds = widget.initialDurationSeconds % 60;
  }

  int get _totalSeconds => _minutes * 60 + _seconds;

  void _updateDuration() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        l10n.adjustTimeTitle(widget.slotName),
        style: TextStyle(color: widget.tokens.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Number pickers row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPickerColumn(
                  label: l10n.minutes,
                  value: _minutes,
                  maxValue: 999,
                  onChanged: (val) {
                    setState(() => _minutes = val);
                    _updateDuration();
                  },
                ),
                const SizedBox(width: 24),
                _buildPickerColumn(
                  label: l10n.seconds,
                  value: _seconds,
                  maxValue: 59,
                  onChanged: (val) {
                    setState(() => _seconds = val);
                    _updateDuration();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Current value preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.tokens.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.tokens.border.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                l10n.currentDuration(_minutes, _seconds),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: widget.tokens.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            l10n.actionCancel,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        TextButton(
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
            foregroundColor: widget.tokens.accent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(l10n.ok, style: const TextStyle(fontSize: 18)),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
    );
  }

  Widget _buildPickerColumn({
    required String label,
    required int value,
    required int maxValue,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: widget.tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.tokens.border),
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: () {
                  if (value < maxValue) {
                    onChanged(value + 1);
                  } else {
                    // Loop around or max out
                    onChanged(0);
                  }
                },
                color: widget.tokens.textPrimary,
              ),
              NumberPicker(
                value: value,
                minValue: 0,
                maxValue: maxValue,
                step: 1,
                itemHeight: 50,
                axis: Axis.vertical,
                onChanged: onChanged,
                textStyle: TextStyle(
                  fontSize: 18,
                  color: widget.tokens.textSecondary,
                ),
                selectedTextStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: widget.tokens.textPrimary,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: widget.tokens.border),
                    bottom: BorderSide(color: widget.tokens.border),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                  if (value > 0) {
                    onChanged(value - 1);
                  } else {
                    // Loop around
                    onChanged(maxValue);
                  }
                },
                color: widget.tokens.textPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
