import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/locale_provider.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';

/// TTS settings page for configuring voice announcements.
class TtsSettingsPage extends ConsumerWidget {
  const TtsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ttsService = ref.read(ttsServiceProvider);
    final currentLocale = ref.read(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ttsSettings),
      ),
      body: ListView(
        children: [
          // Test TTS Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.testTts,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // Get locale tag for TTS
                      final localeTag = currentLocale?.toLanguageTag() ?? 
                                       Localizations.localeOf(context).toLanguageTag();
                      
                      // Test TTS with sample message
                      final testMessage = l10n.timeUpTts('Timer 1');
                      
                      await ttsService.speak(
                        text: testMessage,
                        localeTag: localeTag,
                      );
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
                  icon: const Icon(Icons.record_voice_over),
                  label: Text(l10n.testTts),
                ),
              ],
            ),
          ),
          const Divider(),
          
          // Language Information
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.ttsLanguage),
            subtitle: Text(l10n.ttsLanguageDesc),
            trailing: const Text('System'),
          ),
          
          // Note
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'TTS language follows system settings.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

