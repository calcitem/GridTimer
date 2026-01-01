import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Check if running on desktop platform
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void dispose() {
    _ttsCompletionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _testTts(
    double volume,
    double speechRate,
    double pitch,
    String? ttsLanguage,
  ) async {
    if (_isSpeaking) return;

    final ttsService = ref.read(ttsServiceProvider);
    final currentLocale = ref.read(localeProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    // Use user-selected language, or fall back to app/system language
    final localeTag =
        ttsLanguage ??
        currentLocale?.toLanguageTag() ??
        Localizations.localeOf(context).toLanguageTag();

    setState(() => _isSpeaking = true);

    // Cancel any existing subscription
    await _ttsCompletionSubscription?.cancel();

    try {
      // Log diagnostic info (won't block - we'll try to speak anyway)
      await ttsService.checkTtsAvailability(localeTag);

      // Apply current settings
      await ttsService.setVolume(volume);
      await ttsService.setSpeechRate(speechRate);
      await ttsService.setPitch(pitch);

      // Test TTS with sample message
      // Use localized test message based on selected language
      final testMessage = localeTag.startsWith('zh')
          ? '计时器 1 时间到了'
          : 'Timer 1 time is up';

      // Flag to track if completion was received
      bool completionReceived = false;

      // Listen for completion
      _ttsCompletionSubscription = ttsService.completionStream.listen((
        completed,
      ) {
        completionReceived = true;
        if (mounted) {
          setState(() => _isSpeaking = false);
          // On desktop, completion callback fires from the fallback timer,
          // so we consider it successful if we received any completion.
          if (!completed && !_isDesktop) {
            // TTS failed - show diagnostic dialog (only on mobile)
            _showTtsFailedDialog();
          }
        }
      });

      // Speak the test message
      await ttsService.speak(text: testMessage, localeTag: localeTag);

      // Add a timeout in case completion handler doesn't fire
      // Use longer timeout on desktop where completion may come from fallback
      final timeoutSeconds = _isDesktop ? 8 : 5;
      Future.delayed(Duration(seconds: timeoutSeconds), () {
        if (mounted && _isSpeaking && !completionReceived) {
          setState(() => _isSpeaking = false);
          // On desktop, if timeout occurs, we don't show failure dialog
          // since TTS may have actually worked
          if (!_isDesktop) {
            _showTtsFailedDialog();
          }
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

  Future<void> _openTtsSettings() async {
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.openTtsSettings();
  }

  void _showTtsFailedDialog() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final permissionService = ref.read(permissionServiceProvider);
    final canOpenSettings = permissionService.canOpenTtsSettings;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ttsTestFailedTitle),
        content: Text(l10n.ttsTestFailedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showDiagnosticInfo();
            },
            child: Text(l10n.viewDiagnostics),
          ),
          // Only show "Open TTS Settings" button on platforms that support it
          if (canOpenSettings)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openTtsSettings();
              },
              icon: const Icon(Icons.settings),
              label: Text(l10n.openTtsSettings),
            ),
        ],
      ),
    );
  }

  Future<void> _showDiagnosticInfo() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final ttsService = ref.read(ttsServiceProvider);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final info = await ttsService.getDiagnosticInfo();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      final engines = info['engines'];
      final defaultEngine = info['defaultEngine'];
      final languages = info['languages'];

      // Format diagnostic info
      final buffer = StringBuffer();
      buffer.writeln('${l10n.ttsEngine}: $defaultEngine');
      buffer.writeln('');
      buffer.writeln('${l10n.availableEngines}:');
      if (engines is List) {
        for (final engine in engines) {
          buffer.writeln('  • $engine');
        }
      }
      buffer.writeln('');
      buffer.writeln('${l10n.availableLanguages}:');
      if (languages is List) {
        final langList = languages.take(20).toList();
        for (final lang in langList) {
          buffer.writeln('  • $lang');
        }
        if (languages.length > 20) {
          buffer.writeln('  ... ${l10n.andMore((languages.length - 20))}');
        }
      }

      final permissionService = ref.read(permissionServiceProvider);
      final canOpenSettings = permissionService.canOpenTtsSettings;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.ttsDiagnostics),
          content: SingleChildScrollView(
            child: SelectableText(
              buffer.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
            // Only show "Open TTS Settings" button on platforms that support it
            if (canOpenSettings)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _openTtsSettings();
                },
                icon: const Icon(Icons.settings),
                label: Text(l10n.openTtsSettings),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorText(e.toString()))));
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
                            settings.ttsLanguage,
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

            // Language Selection
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.ttsLanguage),
              subtitle: Text(_getTtsLanguageName(settings.ttsLanguage, l10n)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageSelector(settings.ttsLanguage),
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
                  Semantics(
                    label: l10n.volume,
                    value: '${(settings.ttsVolume * 100).round()}%',
                    increasedValue:
                        '${((settings.ttsVolume * 100).round() + 1)}%',
                    decreasedValue:
                        '${((settings.ttsVolume * 100).round() - 1)}%',
                    slider: true,
                    child: Slider(
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
                  Semantics(
                    label: l10n.ttsSpeechRate,
                    value: _getSpeechRateLabel(settings.ttsSpeechRate),
                    slider: true,
                    child: Slider(
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
                  Semantics(
                    label: l10n.ttsPitch,
                    value: _getPitchLabel(settings.ttsPitch),
                    slider: true,
                    child: Slider(
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

  String _getTtsLanguageName(String? ttsLanguage, AppLocalizations l10n) {
    if (ttsLanguage == null) {
      return l10n.followSystem;
    }
    switch (ttsLanguage) {
      case 'zh-CN':
        return l10n.simplifiedChinese;
      case 'en-US':
        return l10n.english;
      default:
        return ttsLanguage;
    }
  }

  void _showLanguageSelector(String? currentLanguage) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ttsLanguage),
        content: RadioGroup<String?>(
          groupValue: currentLanguage,
          onChanged: (value) {
            Navigator.of(dialogContext).pop();
            ref.read(appSettingsProvider.notifier).updateTtsLanguage(value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                title: Text(l10n.followSystem),
                subtitle: Text(l10n.ttsLanguageAutoDesc),
                value: null,
              ),
              RadioListTile<String?>(
                title: Text(l10n.simplifiedChinese),
                subtitle: const Text('zh-CN'),
                value: 'zh-CN',
              ),
              RadioListTile<String?>(
                title: Text(l10n.english),
                subtitle: const Text('en-US'),
                value: 'en-US',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
        ],
      ),
    );
  }
}
