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
                        : () => _testSound(
                            settings.soundVolume,
                          ),
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
                    increasedValue: '${((settings.soundVolume * 100).round() + 1)}%',
                    decreasedValue: '${((settings.soundVolume * 100).round() - 1)}%',
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
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(l10n.errorText(err.toString()))),
      ),
    );
  }
}
