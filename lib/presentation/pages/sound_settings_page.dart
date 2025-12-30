import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';

/// Sound settings page for configuring alarm sound and volume.
class SoundSettingsPage extends ConsumerWidget {
  const SoundSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final audioService = ref.read(audioServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.soundSettings),
      ),
      body: ListView(
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
                  onPressed: () async {
                    try {
                      // Play test sound
                      await audioService.playLoop(soundKey: 'default');
                      
                      // Stop after 2 seconds
                      await Future.delayed(const Duration(seconds: 2));
                      await audioService.stop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorText(e.toString())),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.testSound),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Sound Information
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.alarmSound),
            subtitle: const Text('Default'),
          ),
          
          // Volume Note
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: Text(l10n.volume),
            subtitle: Text(l10n.volumeDesc),
            trailing: const Text('System'),
          ),
        ],
      ),
    );
  }
}

