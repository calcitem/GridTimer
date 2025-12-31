import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../app/providers.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';

/// Sound settings page for configuring alarm sound and volume.
class SoundSettingsPage extends ConsumerStatefulWidget {
  const SoundSettingsPage({super.key});

  @override
  ConsumerState<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends ConsumerState<SoundSettingsPage> {
  bool _isPlaying = false;

  Future<void> _testSound(double volume, String? customAudioPath) async {
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
        customAudioPath: customAudioPath,
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

  Future<void> _pickAudioFile() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await ref
            .read(appSettingsProvider.notifier)
            .updateCustomAudioPath(filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.customAudioSelected),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorText(e.toString())),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearCustomAudio() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    await ref.read(appSettingsProvider.notifier).updateCustomAudioPath(null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.customAudioCleared),
          duration: const Duration(seconds: 2),
        ),
      );
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
                            settings.customAudioPath,
                          ),
                    icon: _isPlaying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isPlaying ? 'Playing...' : l10n.testSound),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Custom Audio Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.customAudio,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (settings.customAudioPath != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.customAudioActive,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  settings.customAudioPath!.split('/').last,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  // Remove maxLines and ellipsis, allow filename to wrap
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickAudioFile,
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            settings.customAudioPath != null
                                ? l10n.changeCustomAudio
                                : l10n.uploadCustomAudio,
                          ),
                        ),
                      ),
                      if (settings.customAudioPath != null) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _clearCustomAudio,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.clearCustomAudio),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withAlpha(25),
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.customAudioDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70, // Ensure high contrast
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Sound Information
            ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(l10n.alarmSound),
              subtitle: Text(settings.selectedSoundKey),
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
                  Slider(
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
