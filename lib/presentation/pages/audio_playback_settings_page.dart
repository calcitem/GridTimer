import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';

/// Audio playback settings page for configuring alarm playback modes.
class AudioPlaybackSettingsPage extends ConsumerWidget {
  const AudioPlaybackSettingsPage({super.key});

  String _getModeDescription(AudioPlaybackMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AudioPlaybackMode.loopIndefinitely:
        return l10n.audioPlaybackModeLoopIndefinitely;
      case AudioPlaybackMode.loopForDuration:
        return l10n.audioPlaybackModeLoopForDuration;
      case AudioPlaybackMode.loopWithInterval:
        return l10n.audioPlaybackModeLoopWithInterval;
      case AudioPlaybackMode.loopWithIntervalRepeating:
        return l10n.audioPlaybackModeLoopWithIntervalRepeating;
      case AudioPlaybackMode.playOnce:
        return l10n.audioPlaybackModePlayOnce;
    }
  }

  bool _needsLoopDuration(AudioPlaybackMode mode) {
    return mode != AudioPlaybackMode.loopIndefinitely &&
        mode != AudioPlaybackMode.playOnce;
  }

  bool _needsIntervalPause(AudioPlaybackMode mode) {
    return mode == AudioPlaybackMode.loopWithInterval ||
        mode == AudioPlaybackMode.loopWithIntervalRepeating;
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
      appBar: AppBar(title: Text(l10n.audioPlaybackSettings)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // Important Notice Card
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Colors.blue.shade700,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade300,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.audioPlaybackWhenEffectiveTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade300,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.audioPlaybackWhenEffectiveDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Playback Mode Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.audioPlaybackMode,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.audioPlaybackSettingsDesc,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Mode Selection Radio List
            ...AudioPlaybackMode.values.map((mode) {
              final isSelected = settings.audioPlaybackMode == mode;
              return Semantics(
                label: _getModeDescription(mode, l10n),
                selected: isSelected,
                inMutuallyExclusiveGroup: true,
                button: true,
                child: InkWell(
                  onTap: () {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateAudioPlaybackMode(mode);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _getModeDescription(mode, l10n),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Divider(),

            // Loop Duration (shown only when needed)
            if (_needsLoopDuration(settings.audioPlaybackMode))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.loopDuration,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${settings.audioLoopDurationMinutes} ${l10n.minutesUnit}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: l10n.loopDuration,
                      value:
                          '${settings.audioLoopDurationMinutes} ${l10n.minutesUnit}',
                      increasedValue:
                          '${settings.audioLoopDurationMinutes + 1} ${l10n.minutesUnit}',
                      decreasedValue:
                          '${settings.audioLoopDurationMinutes - 1} ${l10n.minutesUnit}',
                      slider: true,
                      child: Slider(
                        value: settings.audioLoopDurationMinutes.toDouble(),
                        min: 1,
                        max: 60,
                        divisions: 59,
                        label:
                            '${settings.audioLoopDurationMinutes} ${l10n.minutesUnit}',
                        onChanged: (value) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateAudioLoopDuration(value.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Interval Pause Duration (shown only when needed)
            if (_needsIntervalPause(settings.audioPlaybackMode))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.intervalPause,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${settings.audioIntervalPauseMinutes} ${l10n.minutesUnit}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: l10n.intervalPause,
                      value:
                          '${settings.audioIntervalPauseMinutes} ${l10n.minutesUnit}',
                      increasedValue:
                          '${settings.audioIntervalPauseMinutes + 1} ${l10n.minutesUnit}',
                      decreasedValue:
                          '${settings.audioIntervalPauseMinutes - 1} ${l10n.minutesUnit}',
                      slider: true,
                      child: Slider(
                        value: settings.audioIntervalPauseMinutes.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label:
                            '${settings.audioIntervalPauseMinutes} ${l10n.minutesUnit}',
                        onChanged: (value) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateAudioIntervalPause(value.round());
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(l10n.errorText(err.toString()))),
      ),
    );
  }
}
