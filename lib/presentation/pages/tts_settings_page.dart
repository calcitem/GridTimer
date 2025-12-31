import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/locale_provider.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';

/// TTS settings page for configuring voice announcements.
class TtsSettingsPage extends ConsumerStatefulWidget {
  const TtsSettingsPage({super.key});

  @override
  ConsumerState<TtsSettingsPage> createState() => _TtsSettingsPageState();
}

class _TtsSettingsPageState extends ConsumerState<TtsSettingsPage> {
  bool _isSpeaking = false;

  Future<void> _testTts(double volume, double speechRate, double pitch) async {
    if (_isSpeaking) return;

    final ttsService = ref.read(ttsServiceProvider);
    final currentLocale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isSpeaking = true);

    try {
      // Get locale tag for TTS
      final localeTag = currentLocale?.toLanguageTag() ??
          Localizations.localeOf(context).toLanguageTag();

      // Apply current settings
      await ttsService.setVolume(volume);
      await ttsService.setSpeechRate(speechRate);
      await ttsService.setPitch(pitch);

      // Test TTS with sample message
      final testMessage = l10n.timeUpTts('计时器 1');

      await ttsService.speak(
        text: testMessage,
        localeTag: localeTag,
      );

      // Wait a bit before resetting speaking state
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorText(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(appSettingsProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ttsSettings),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
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
                    onPressed: _isSpeaking
                        ? null
                        : () => _testTts(
                              settings.ttsVolume,
                              settings.ttsSpeechRate,
                              settings.ttsPitch,
                            ),
                    icon: _isSpeaking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.record_voice_over),
                    label: Text(_isSpeaking ? '播报中...' : l10n.testTts),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Language Information
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.ttsLanguage),
              subtitle: Text(_getLanguageName(currentLocale)),
              trailing: const Icon(Icons.info_outline),
            ),
            const Divider(),

            // TTS Volume Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        '${(settings.ttsVolume * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: settings.ttsVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: '${(settings.ttsVolume * 100).round()}%',
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).updateTtsVolume(value);
                    },
                  ),
                  Text(
                    '调整语音播报音量',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Speech Rate Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed),
                          const SizedBox(width: 8),
                          Text(
                            '语速',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Text(
                        _getSpeechRateLabel(settings.ttsSpeechRate),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: settings.ttsSpeechRate,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: _getSpeechRateLabel(settings.ttsSpeechRate),
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).updateTtsSpeechRate(value);
                    },
                  ),
                  Text(
                    '调整语音播报速度（0.5 为正常速度）',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Pitch Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.graphic_eq),
                          const SizedBox(width: 8),
                          Text(
                            '音调',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Text(
                        _getPitchLabel(settings.ttsPitch),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: settings.ttsPitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 150,
                    label: _getPitchLabel(settings.ttsPitch),
                    onChanged: (value) {
                      ref.read(appSettingsProvider.notifier).updateTtsPitch(value);
                    },
                  ),
                  Text(
                    '调整语音播报音调（1.0 为正常音调）',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),

            // Note
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '语音播报语言跟随应用语言设置。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(l10n.errorText(err.toString())),
        ),
      ),
    );
  }

  String _getLanguageName(Locale? locale) {
    if (locale == null) {
      return '跟随系统';
    }
    switch (locale.languageCode) {
      case 'zh':
        return '简体中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }

  String _getSpeechRateLabel(double rate) {
    if (rate < 0.3) return '很慢';
    if (rate < 0.45) return '慢';
    if (rate < 0.55) return '正常';
    if (rate < 0.7) return '快';
    return '很快';
  }

  String _getPitchLabel(double pitch) {
    if (pitch < 0.8) return '很低';
    if (pitch < 0.95) return '低';
    if (pitch < 1.05) return '正常';
    if (pitch < 1.2) return '高';
    return '很高';
  }
}

