import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';

/// Gesture settings page for configuring alarm control gestures.
class GestureSettingsPage extends ConsumerWidget {
  const GestureSettingsPage({super.key});

  String _getGestureTypeName(AlarmGestureType type, AppLocalizations l10n) {
    switch (type) {
      case AlarmGestureType.volumeUp:
        return l10n.gestureTypeVolumeUp;
      case AlarmGestureType.volumeDown:
        return l10n.gestureTypeVolumeDown;
      case AlarmGestureType.shake:
        return l10n.gestureTypeShake;
      case AlarmGestureType.flip:
        return l10n.gestureTypeFlip;
    }
  }

  String _getActionName(AlarmGestureAction action, AppLocalizations l10n) {
    switch (action) {
      case AlarmGestureAction.stopAndReset:
        return l10n.gestureActionStopAndReset;
      case AlarmGestureAction.pause:
        return l10n.gestureActionPause;
      case AlarmGestureAction.none:
        return l10n.gestureActionNone;
    }
  }

  IconData _getGestureIcon(AlarmGestureType type) {
    switch (type) {
      case AlarmGestureType.volumeUp:
        return Icons.volume_up;
      case AlarmGestureType.volumeDown:
        return Icons.volume_down;
      case AlarmGestureType.shake:
        return Icons.vibration;
      case AlarmGestureType.flip:
        return Icons.screen_rotation;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = l10nNullable;
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gestureSettings)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // Hint Card
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.gestureHint,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Gesture Actions Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                l10n.gestureActions,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // Gesture Type Cards
            ...AlarmGestureType.values.map((gestureType) {
              final currentAction =
                  settings.gestureActions[gestureType] ??
                  AlarmGestureAction.none;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: Icon(
                    _getGestureIcon(gestureType),
                    size: 32,
                    color: currentAction != AlarmGestureAction.none
                        ? Colors.green
                        : Colors.white54,
                  ),
                  title: Text(_getGestureTypeName(gestureType, l10n)),
                  subtitle: Text(
                    _getActionName(currentAction, l10n),
                    style: TextStyle(
                      color: currentAction != AlarmGestureAction.none
                          ? Colors.green
                          : Colors.white54,
                      fontWeight: currentAction != AlarmGestureAction.none
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  children: AlarmGestureAction.values.map((action) {
                    final isSelected = currentAction == action;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        _getActionName(action, l10n),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(appSettingsProvider.notifier)
                            .updateGestureAction(gestureType, action);
                      },
                    );
                  }).toList(),
                ),
              );
            }),

            const Divider(height: 32),

            // Shake Sensitivity Section
            if (settings.gestureActions[AlarmGestureType.shake] !=
                AlarmGestureAction.none)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shakeSensitivity,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.shakeSensitivityLow,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                settings.shakeSensitivity.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.shakeSensitivityHigh,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Semantics(
                            label: l10n.shakeSensitivity,
                            value: settings.shakeSensitivity.toStringAsFixed(1),
                            increasedValue: (settings.shakeSensitivity + 0.5)
                                .toStringAsFixed(1),
                            decreasedValue: (settings.shakeSensitivity - 0.5)
                                .toStringAsFixed(1),
                            slider: true,
                            child: Slider(
                              value: settings.shakeSensitivity,
                              min: 1.0,
                              max: 5.0,
                              divisions: 8,
                              label: settings.shakeSensitivity.toStringAsFixed(
                                1,
                              ),
                              onChanged: (value) {
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .updateShakeSensitivity(value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      l10n.shakeSensitivityDesc,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(l10n.errorText(err.toString()))),
      ),
    );
  }
}
