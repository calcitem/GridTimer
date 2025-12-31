import 'dart:async';
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
  StreamSubscription<bool>? _ttsCompletionSubscription;

  @override
  void dispose() {
    _ttsCompletionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _testTts(double volume, double speechRate, double pitch) async {
    if (_isSpeaking) return;

    final ttsService = ref.read(ttsServiceProvider);
    final currentLocale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    setState(() => _isSpeaking = true);

    // Cancel any existing subscription
    await _ttsCompletionSubscription?.cancel();

    try {
      // Get locale tag for TTS
      final localeTag =
          currentLocale?.toLanguageTag() ??
          Localizations.localeOf(context).toLanguageTag();

      // Apply current settings
      await ttsService.setVolume(volume);
      await ttsService.setSpeechRate(speechRate);
      await ttsService.setPitch(pitch);

      // Test TTS with sample message
      // Use localized test message based on current locale
      final testMessage = localeTag.startsWith('zh')
          ? '计时器 1 时间到了'
          : 'Timer 1 time is up';

      // Listen for completion
      _ttsCompletionSubscription = ttsService.completionStream.listen(
        (completed) {
          if (mounted) {
            setState(() => _isSpeaking = false);
          }
        },
      );

      // Speak the test message
      await ttsService.speak(text: testMessage, localeTag: localeTag);

      // Add a timeout in case completion handler doesn't fire
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isSpeaking) {
          setState(() => _isSpeaking = false);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorText(e.toString()))));
        setState(() => _isSpeaking = false);
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
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ttsSettings)),
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
                    label: Text(_isSpeaking ? l10n.speaking : l10n.testTts),
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
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateTtsVolume(value);
                    },
                  ),
                  Text(
                    l10n.ttsVolumeDesc,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Speech Rate Slider
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
                          const Icon(Icons.speed),
                          const SizedBox(width: 8),
                          Text(
                            l10n.ttsSpeechRate,
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
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateTtsSpeechRate(value);
                    },
                  ),
                  Text(
                    l10n.ttsSpeechRateDesc,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Pitch Slider
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
                          const Icon(Icons.graphic_eq),
                          const SizedBox(width: 8),
                          Text(
                            l10n.ttsPitch,
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
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateTtsPitch(value);
                    },
                  ),
                  Text(
                    l10n.ttsPitchDesc,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Note
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.ttsLanguageNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
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

  String _getLanguageName(Locale? locale) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return '';
    
    if (locale == null) {
      return l10n.followSystem;
    }
    switch (locale.languageCode) {
      case 'zh':
        return l10n.simplifiedChinese;
      case 'en':
        return l10n.english;
      default:
        return locale.languageCode;
    }
  }

  String _getSpeechRateLabel(double rate) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return '';
    
    if (rate < 0.3) return l10n.speedVerySlow;
    if (rate < 0.45) return l10n.speedSlow;
    if (rate < 0.55) return l10n.speedNormal;
    if (rate < 0.7) return l10n.speedFast;
    return l10n.speedVeryFast;
  }

  String _getPitchLabel(double pitch) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return '';
    
    if (pitch < 0.8) return l10n.pitchVeryLow;
    if (pitch < 0.95) return l10n.pitchLow;
    if (pitch < 1.05) return l10n.pitchNormal;
    if (pitch < 1.2) return l10n.pitchHigh;
    return l10n.pitchVeryHigh;
  }
}
