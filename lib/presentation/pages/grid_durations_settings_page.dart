import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/app_settings.dart';
import '../../l10n/app_localizations.dart';

/// Grid durations and names configuration page
class GridDurationsSettingsPage extends ConsumerStatefulWidget {
  const GridDurationsSettingsPage({super.key});

  @override
  ConsumerState<GridDurationsSettingsPage> createState() =>
      _GridDurationsSettingsPageState();
}

class _GridDurationsSettingsPageState
    extends ConsumerState<GridDurationsSettingsPage> {
  late List<TextEditingController> _minutesControllers;
  late List<TextEditingController> _secondsControllers;
  late List<TextEditingController> _nameControllers;
  late List<int> _durations;
  late List<String> _names;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final settings = ref.read(appSettingsProvider).value;
    _durations = List<int>.from(
      settings?.gridDurationsInSeconds ?? AppSettings.defaultGridDurations,
    );
    // Handle potential null or shorter list for names
    final savedNames = settings?.gridNames ?? AppSettings.defaultGridNames;
    _names = List<String>.generate(
      9,
      (i) => (i < savedNames.length) ? savedNames[i] : '',
    );

    // Split duration into minutes and seconds for separate input
    _minutesControllers = List.generate(9, (i) {
      final minutes = _durations[i] ~/ 60;
      return TextEditingController(text: minutes.toString());
    });
    _secondsControllers = List.generate(9, (i) {
      final seconds = _durations[i] % 60;
      return TextEditingController(text: seconds.toString());
    });
    _nameControllers = List.generate(
      9,
      (i) => TextEditingController(text: _names[i]),
    );
  }

  @override
  void dispose() {
    for (var controller in _minutesControllers) {
      controller.dispose();
    }
    for (var controller in _secondsControllers) {
      controller.dispose();
    }
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Save configuration
  Future<void> _saveDurations() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final newDurations = <int>[];
    final newNames = <String>[];
    bool hasError = false;

    for (int i = 0; i < 9; i++) {
      final minutesText = _minutesControllers[i].text.trim();
      final secondsText = _secondsControllers[i].text.trim();

      final minutes =
          int.tryParse(minutesText.isEmpty ? '0' : minutesText) ?? 0;
      final seconds =
          int.tryParse(secondsText.isEmpty ? '0' : secondsText) ?? 0;

      final totalSeconds = minutes * 60 + seconds;

      if (totalSeconds <= 0) {
        hasError = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.gridDurationMustBePositive(i + 1)),
            backgroundColor: Colors.red,
          ),
        );
        break;
      }

      newDurations.add(totalSeconds);
      newNames.add(_nameControllers[i].text.trim());
    }

    if (!hasError) {
      // Save configuration first
      await ref
          .read(appSettingsProvider.notifier)
          .updateSettings(
            (s) => s.copyWith(
              gridDurationsInSeconds: newDurations,
              gridNames: newNames,
            ),
          );

      // Try to immediately update default grid duration configuration
      try {
        final timerService = ref.read(timerServiceProvider);
        if (timerService.hasActiveTimers()) {
          // Active timers exist, cannot update immediately
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.activeTimersRunningConfigWillApplyOnRestart),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // No active timers, update immediately
          await timerService.updateDefaultGridDurations();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.savedSuccessfullyGridUpdated),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        // Show warning on error, but don't prevent saving
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.configurationSavedButErrorDuringUpdate(e.toString()),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Reset to default values
  Future<void> _resetToDefault() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetToDefault),
        content: SingleChildScrollView(
          child: Text(l10n.gridDurationsResetConfirm),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final defaultDurations = List<int>.from(AppSettings.defaultGridDurations);
      final defaultNames = List<String>.from(AppSettings.defaultGridNames);

      setState(() {
        _durations = List<int>.from(defaultDurations);
        _names = List<String>.from(defaultNames);
        for (int i = 0; i < 9; i++) {
          final minutes = _durations[i] ~/ 60;
          final seconds = _durations[i] % 60;
          _minutesControllers[i].text = minutes.toString();
          _secondsControllers[i].text = seconds.toString();
          _nameControllers[i].text = _names[i];
        }
      });

      // Persist defaults immediately so the reset actually takes effect.
      await ref
          .read(appSettingsProvider.notifier)
          .updateSettings(
            (s) => s.copyWith(
              gridDurationsInSeconds: defaultDurations,
              gridNames: defaultNames,
            ),
          );

      // Try to immediately update the active grid if possible.
      try {
        final timerService = ref.read(timerServiceProvider);
        if (timerService.hasActiveTimers()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.activeTimersRunningConfigWillApplyOnRestart),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          await timerService.updateDefaultGridDurations();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.savedSuccessfullyGridUpdated),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.configurationSavedButErrorDuringUpdate(e.toString()),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  /// Format duration for display
  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '$minutes min';
      } else {
        return '$minutes min $remainingSeconds s';
      }
    } else {
      final hours = seconds ~/ 3600;
      final remainingMinutes = (seconds % 3600) ~/ 60;
      if (remainingMinutes == 0) {
        return '$hours h';
      } else {
        return '$hours h $remainingMinutes min';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = l10nNullable;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gridDurationsSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: l10n.resetToDefault,
            onPressed: _resetToDefault,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 9,
              itemBuilder: (context, index) {
                return _buildGridConfigInput(index, l10n);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDurations,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.save, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridConfigInput(int index, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.gridSlot(index + 1),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Name Input field
            TextField(
              controller: _nameControllers[index],
              decoration: InputDecoration(
                labelText: '${l10n.name} (${l10n.optional})',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _names[index] = value;
                });
              },
            ),
            const SizedBox(height: 12),
            // Duration Input: Minutes and Seconds side by side
            Row(
              children: [
                // Minutes Input
                Expanded(
                  child: Semantics(
                    label: '${l10n.gridSlot(index + 1)}, ${l10n.minutes}',
                    textField: true,
                    child: TextField(
                      controller: _minutesControllers[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.minutes,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixText: 'min',
                      ),
                      onChanged: (value) {
                        // Real-time preview
                        final minutes =
                            int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                        final seconds =
                            int.tryParse(
                              _secondsControllers[index].text.isEmpty
                                  ? '0'
                                  : _secondsControllers[index].text,
                            ) ??
                            0;
                        setState(() {
                          _durations[index] = minutes * 60 + seconds;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Seconds Input
                Expanded(
                  child: Semantics(
                    label: '${l10n.gridSlot(index + 1)}, ${l10n.seconds}',
                    textField: true,
                    child: TextField(
                      controller: _secondsControllers[index],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.seconds,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixText: 's',
                      ),
                      onChanged: (value) {
                        // Real-time preview
                        final minutes =
                            int.tryParse(
                              _minutesControllers[index].text.isEmpty
                                  ? '0'
                                  : _minutesControllers[index].text,
                            ) ??
                            0;
                        final seconds =
                            int.tryParse(value.isEmpty ? '0' : value) ?? 0;
                        setState(() {
                          _durations[index] = minutes * 60 + seconds;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Display formatted duration
            Text(
              _formatDuration(_durations[index]),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
