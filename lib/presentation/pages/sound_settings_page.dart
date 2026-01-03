import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';

/// Volume settings page for configuring alarm volume.
class SoundSettingsPage extends ConsumerStatefulWidget {
  const SoundSettingsPage({super.key});

  @override
  ConsumerState<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends ConsumerState<SoundSettingsPage> {
  bool _isPlaying = false;

  Future<void> _testSound(double volume) async {
    if (_isPlaying) return;

    final audioService = ref.read(audioServiceProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    // Read current audio playback mode from settings
    final settingsAsync = ref.read(appSettingsProvider);
    final settings = settingsAsync.value;

    setState(() => _isPlaying = true);

    try {
      // Play test sound with current volume and configured playback mode
      await audioService.playWithMode(
        soundKey: 'default',
        volume: volume,
        mode: settings?.audioPlaybackMode ?? AudioPlaybackMode.loopIndefinitely,
        loopDurationMinutes: settings?.audioLoopDurationMinutes ?? 5,
        intervalPauseMinutes: settings?.audioIntervalPauseMinutes ?? 2,
      );

      // Stop after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      await audioService.stop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorText(e.toString()))));
      }
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
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
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.soundSettings)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // Test Sound Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.testSound,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isPlaying
                        ? null
                        : () => _testSound(settings.soundVolume),
                    icon: _isPlaying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isPlaying ? l10n.playing : l10n.testSound),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Volume Slider
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
                      Row(
                        children: [
                          const Icon(Icons.volume_up),
                          const SizedBox(width: 8),
                          Text(
                            l10n.volume,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Text(
                        '${(settings.soundVolume * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: l10n.volume,
                    value: '${(settings.soundVolume * 100).round()}%',
                    increasedValue:
                        '${((settings.soundVolume * 100).round() + 1)}%',
                    decreasedValue:
                        '${((settings.soundVolume * 100).round() - 1)}%',
                    slider: true,
                    child: Slider(
                      value: settings.soundVolume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: '${(settings.soundVolume * 100).round()}%',
                      onChanged: (value) {
                        ref
                            .read(appSettingsProvider.notifier)
                            .updateSoundVolume(value);
                      },
                    ),
                  ),
                  Text(
                    l10n.volumeDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70, // Ensure high contrast
                    ),
                  ),
                ],
              ),
            ),

            // System volume hint
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withAlpha(76)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.systemVolumeHint,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(),

            // Android system alarm volume boost
            SwitchListTile(
              secondary: const Icon(Icons.alarm),
              title: Text(l10n.autoRaiseAlarmVolumeTitle),
              subtitle: Text(l10n.autoRaiseAlarmVolumeDesc),
              value: settings.autoRaiseAlarmVolumeEnabled,
              onChanged: (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .toggleAutoRaiseAlarmVolume(value);
              },
            ),

            if (settings.autoRaiseAlarmVolumeEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  l10n.alarmVolumeBoostLevelTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              RadioListTile<AlarmVolumeBoostLevel>(
                value: AlarmVolumeBoostLevel.minimumAudible,
                groupValue: settings.alarmVolumeBoostLevel,
                onChanged: (value) {
                  if (value == null) return;
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateAlarmVolumeBoostLevel(value);
                },
                title: Text(l10n.alarmVolumeBoostLevelMinAudible),
              ),
              RadioListTile<AlarmVolumeBoostLevel>(
                value: AlarmVolumeBoostLevel.maximum,
                groupValue: settings.alarmVolumeBoostLevel,
                onChanged: (value) {
                  if (value == null) return;
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateAlarmVolumeBoostLevel(value);
                },
                title: Text(l10n.alarmVolumeBoostLevelMax),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withAlpha(76)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.autoRaiseAlarmVolumeNote(
                            settings.alarmVolumeBoostRestoreAfterMinutes,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(l10n.errorText(err.toString()))),
      ),
    );
  }
}
