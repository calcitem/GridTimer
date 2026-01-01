import 'dart:async';
import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/locale_provider.dart';
import '../../app/providers.dart';
import '../../core/config/environment_config.dart';
import '../../l10n/app_localizations.dart';
import '../dialogs/alarm_troubleshooting_dialog.dart';
import '../dialogs/safety_disclaimer_dialog.dart';
import 'audio_playback_settings_page.dart';
import 'audio_test_page.dart';
import 'gesture_settings_page.dart';
import 'grid_durations_settings_page.dart';
import 'license_agreement_page.dart';
import 'sound_settings_page.dart';
import 'tts_settings_page.dart';

/// Settings page for configuring app preferences and timer settings.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Developer mode state
  bool _isDeveloperMode = false;
  int _versionTapCount = 0;
  DateTime? _lastTapTime;

  // Tap on version to enable developer mode (5 taps within 3 seconds)
  void _onVersionTap() {
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) return;
    final l10n = l10nNullable;

    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 3)) {
      // Reset if too much time has passed
      _versionTapCount = 1;
    } else {
      _versionTapCount++;
    }
    _lastTapTime = now;

    if (_versionTapCount >= 5 && !_isDeveloperMode) {
      setState(() {
        _isDeveloperMode = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.developerModeEnabled),
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
    final currentLocale = ref.watch(localeProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final tokens = ref.watch(themeProvider).tokens;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // Display & Accessibility Section
            _buildSectionHeader(l10n.displaySettings),
            ListTile(
              leading: const Icon(Icons.brightness_medium),
              title: Text(l10n.themeMode),
              subtitle: Text(_getThemeName(settings.themeId, l10n)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () =>
                  _showThemeDialog(context, ref, l10n, settings.themeId),
            ),
            const Divider(),

            // App Information Section
            _buildSectionHeader(l10n.appInformation),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.version),
              subtitle: const Text('1.0.0+1'),
              onTap: _onVersionTap,
            ),

            // Language
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.languageSettings),
              subtitle: Text(_getLanguageName(currentLocale, l10n)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context, ref, l10n),
            ),
            const Divider(),

            // Timer Settings Section
            _buildSectionHeader(l10n.timerSettings),

            // Grid Durations Settings
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: Text(l10n.gridDurationsSettings),
              subtitle: Text(l10n.gridDurationsSettingsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GridDurationsSettingsPage(),
                  ),
                );
              },
            ),

            // Minutes:Seconds Format Display
            SwitchListTile(
              secondary: const Icon(Icons.timer),
              title: Text(l10n.showMinutesSecondsFormat),
              subtitle: Text(l10n.showMinutesSecondsFormatDesc),
              value: settings.showMinutesSecondsFormat,
              onChanged: (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .toggleMinutesSecondsFormat(value);
              },
            ),

            // Keep Screen On
            SwitchListTile(
              secondary: const Icon(Icons.screen_lock_portrait),
              title: Text(l10n.keepScreenOn),
              subtitle: Text(l10n.keepScreenOnDesc),
              value: settings.keepScreenOnWhileRunning,
              onChanged: (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .toggleKeepScreenOn(value);
              },
            ),

            const Divider(),

            // Sound Settings
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: Text(l10n.soundSettings),
              subtitle: Text(l10n.soundSettingsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SoundSettingsPage()),
                );
              },
            ),

            // Audio Playback Settings
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(l10n.audioPlaybackSettings),
              subtitle: Text(l10n.audioPlaybackSettingsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AudioPlaybackSettingsPage(),
                  ),
                );
              },
            ),

            // Vibration
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: Text(l10n.vibration),
              subtitle: Text(l10n.vibrationDesc),
              value: settings.vibrationEnabled,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).toggleVibration(value);
              },
            ),

            // Flash Animation
            SwitchListTile(
              secondary: const Icon(Icons.flash_on),
              title: Text(l10n.flashAnimation),
              subtitle: Text(l10n.flashAnimationDesc),
              value: settings.flashEnabled,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).toggleFlash(value);
              },
            ),

            // TTS Global Enable
            SwitchListTile(
              secondary: const Icon(Icons.record_voice_over),
              title: Text(l10n.ttsEnabled),
              subtitle: Text(l10n.ttsEnabledDesc),
              value: settings.ttsGlobalEnabled,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).toggleTts(value);
              },
            ),

            // TTS Settings
            ListTile(
              leading: const Icon(Icons.settings_voice),
              title: Text(l10n.ttsSettings),
              subtitle: Text(l10n.ttsSettingsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TtsSettingsPage()),
                );
              },
            ),

            // Gesture Settings
            ListTile(
              leading: const Icon(Icons.touch_app),
              title: Text(l10n.gestureSettings),
              subtitle: Text(l10n.gestureSettingsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GestureSettingsPage(),
                  ),
                );
              },
            ),

            // Alarm Channel Sound (Android 8+)
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: Text(l10n.alarmSoundSettings),
              subtitle: Text(l10n.alarmSoundSettingsDesc),
              trailing: ElevatedButton(
                onPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  try {
                    await permissionService.openNotificationChannelSettings(
                      channelId: 'gt.alarm.timeup.default.v2',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.failedToOpenChannelSettings(e.toString()),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(l10n.goToSettings),
              ),
            ),

            // Alarm Troubleshooting / Compatibility Guide
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(l10n.alarmTroubleshooting),
              subtitle: Text(l10n.alarmTroubleshootingDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => AlarmTroubleshootingDialog.show(context),
            ),

            const Divider(),

            // Permissions Section
            _buildSectionHeader(l10n.permissions),

            // Notification Permission
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(l10n.notificationPermission),
              subtitle: Text(l10n.notificationPermissionDesc),
              trailing: ElevatedButton(
                onPressed: () async {
                  final notification = ref.read(notificationServiceProvider);
                  final granted = await notification
                      .requestPostNotificationsPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? l10n.notificationPermissionGranted
                              : l10n.notificationPermissionDenied,
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text(l10n.grantPermission),
              ),
            ),

            // Exact Alarm Permission
            ListTile(
              leading: const Icon(Icons.alarm),
              title: Text(l10n.exactAlarmPermission),
              subtitle: Text(l10n.exactAlarmPermissionDesc),
              trailing: ElevatedButton(
                onPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  await permissionService.openExactAlarmSettings();
                },
                child: Text(l10n.settingsButton),
              ),
            ),

            // Battery Optimization
            ListTile(
              leading: const Icon(Icons.battery_saver),
              title: Text(l10n.batteryOptimizationSettings),
              subtitle: Text(l10n.batteryOptimizationDesc),
              trailing: ElevatedButton(
                onPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  await permissionService.openBatteryOptimizationSettings();
                },
                child: Text(l10n.settingsButton),
              ),
            ),

            const Divider(),

            // About Section
            _buildSectionHeader(l10n.about),
            // Safety Disclaimer
            ListTile(
              leading: Icon(Icons.info_outline, color: tokens.warning),
              title: Text(l10n.aboutDisclaimer),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => SafetyDisclaimerDialog.show(context),
            ),
            // Privacy Policy
            ListTile(
              leading: Icon(Icons.privacy_tip, color: tokens.accent),
              title: Text(l10n.privacyPolicy),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => _openPrivacyPolicy(currentLocale),
            ),
            // App License (Apache 2.0)
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(l10n.license),
              subtitle: const Text('Apache License 2.0'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LicenseAgreementPage(),
                  ),
                );
              },
            ),
            // OSS Licenses (third-party libraries)
            ListTile(
              leading: const Icon(Icons.library_books),
              title: Text(l10n.ossLicenses),
              subtitle: Text(l10n.ossLicensesDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'GridTimer',
                  applicationVersion: '1.0.0',
                );
              },
            ),

            const Divider(),

            // Reset All Settings
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.resetAllSettings,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.resetAllSettingsDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showResetConfirmDialog(ref),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.resetAllSettings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.warning,
                      foregroundColor: tokens.bg,
                    ),
                  ),
                ],
              ),
            ),

            // Debug Tools Section (only shown in developer mode)
            if (_isDeveloperMode) ...[
              const Divider(),
              _buildSectionHeader('Debug Tools'),

              // 10-Second Test Timer
              ListTile(
                leading: Icon(Icons.timer_10, color: tokens.focusRing),
                title: const Text('10s Test Timer (Debug)'),
                subtitle: const Text('Start a real 10-second timer'),
                trailing: ElevatedButton(
                  onPressed: () => _start10SecondTestTimer(ref),
                  child: const Text('Start'),
                ),
              ),

              // Audio Test (for debugging)
              ListTile(
                leading: Icon(Icons.bug_report, color: tokens.warning),
                title: const Text('Audio Test (Debug)'),
                subtitle: const Text('Diagnose sound issues'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AudioTestPage(),
                    ),
                  );
                },
              ),

              // Catcher Error Test (only shown when catcher is enabled)
              if (EnvironmentConfig.catcher)
                ListTile(
                  leading: Icon(Icons.error_outline, color: tokens.danger),
                  title: const Text('Error Test (Debug)'),
                  subtitle: const Text('Test error reporting system'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Throw a test exception to verify Catcher is working
                    throw Exception(
                      'This is a test exception to verify Catcher error reporting system is working properly',
                    );
                  },
                ),

              // Exit Developer Mode
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.grey),
                title: const Text('Exit Developer Mode'),
                subtitle: const Text('Tap to hide debug tools'),
                onTap: () {
                  setState(() {
                    _isDeveloperMode = false;
                    _versionTapCount = 0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.developerModeDisabled),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
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

  /// Build a section header widget.
  Widget _buildSectionHeader(String title) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        24,
        16,
        12,
      ), // Increased vertical spacing
      child: Text(
        title,
        style: TextStyle(
          fontSize: 26, // Increased font size (18 -> 26)
          fontWeight: FontWeight.w900, // Bolder font
          color: color,
          letterSpacing: 1.2, // Increased letter spacing
        ),
      ),
    );
  }

  /// Start a 10-second test timer (Debug Tool).
  Future<void> _start10SecondTestTimer(WidgetRef ref) async {
    try {
      final timerService = ref.read(timerServiceProvider);

      // Check if any timer is already running
      if (timerService.hasActiveTimers()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please stop all active timers before starting test timer',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Get current settings
      final currentSettings = await ref.read(appSettingsProvider.future);
      final currentDurations = List<int>.from(
        currentSettings.gridDurationsInSeconds,
      );

      // Temporarily modify first slot to 10 seconds
      final testDurations = List<int>.from(currentDurations);
      testDurations[0] = 10;

      // Update settings with test duration
      await ref
          .read(appSettingsProvider.notifier)
          .updateGridDurations(testDurations);

      // Refresh timer grid with new configuration
      await timerService.updateDefaultGridDurations();

      // Start first timer (slot 0)
      await timerService.start(modeId: 'default', slotIndex: 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '10-second test timer started! First slot now set to 10s.',
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // Close settings and return to main page
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start test timer: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Get display name for current language.
  String _getLanguageName(Locale? locale, AppLocalizations l10n) {
    if (locale == null) {
      return '${l10n.languageChineseSimplified} / ${l10n.languageEnglish}';
    }
    switch (locale.languageCode) {
      case 'zh':
        return l10n.languageChineseSimplified;
      case 'en':
        return l10n.languageEnglish;
      default:
        return locale.languageCode;
    }
  }

  /// Open privacy policy URL based on locale.
  ///
  /// Chinese locale: https://calcitem.github.io/GridTimer/privacy-policy_zh
  /// Non-Chinese: https://calcitem.github.io/GridTimer/privacy-policy
  Future<void> _openPrivacyPolicy(Locale? locale) async {
    final isChinese = _isChineseLocale(locale);
    final url = isChinese
        ? 'https://calcitem.github.io/GridTimer/privacy-policy_zh'
        : 'https://calcitem.github.io/GridTimer/privacy-policy';

    final uri = Uri.parse(url);
    // Try to launch URL directly without canLaunchUrl check
    // canLaunchUrl can return false on some devices even when URL can be launched
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }

  /// Check if the effective locale is Chinese.
  bool _isChineseLocale(Locale? userLocale) {
    // If user has explicitly set a locale, use that
    if (userLocale != null) {
      return userLocale.languageCode == 'zh';
    }

    // Otherwise, check the system locale
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return systemLocale.languageCode == 'zh';
  }

  /// Show language selection dialog.
  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.languageEnglish),
              leading: const Icon(Icons.language),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.languageChineseSimplified),
              leading: const Icon(Icons.language),
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('zh'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
        ],
      ),
    );
  }

  /// Show reset all settings confirmation dialog.
  void _showResetConfirmDialog(WidgetRef ref) {
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) return;
    final l10n = l10nNullable;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetAllSettingsConfirmTitle),
        content: Text(l10n.resetAllSettingsConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performReset(ref);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(l10n.resetAllSettings),
          ),
        ],
      ),
    );
  }

  /// Perform settings reset and show exit countdown.
  Future<void> _performReset(WidgetRef ref) async {
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) return;
    final l10n = l10nNullable;

    try {
      // Reset settings
      await ref.read(appSettingsProvider.notifier).resetToDefault();

      // Show countdown dialog and exit
      if (mounted) {
        await _showExitCountdown(l10n);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorText(e.toString()))));
      }
    }
  }

  String _getThemeName(String themeId, AppLocalizations l10n) {
    if (themeId == 'light_high_contrast') return l10n.themeLightHighContrast;
    if (themeId == 'high_contrast') return l10n.themeHighContrast;
    return l10n.themeSoftDark;
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String currentThemeId,
  ) {
    void selectTheme(String themeId) {
      ref.read(appSettingsProvider.notifier).updateTheme(themeId);
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.themeMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              selected: currentThemeId == 'soft_dark',
              child: ListTile(
                leading: const Icon(Icons.nightlight_round),
                title: Text(l10n.themeSoftDark),
                trailing: currentThemeId == 'soft_dark'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => selectTheme('soft_dark'),
              ),
            ),
            Semantics(
              button: true,
              selected: currentThemeId == 'high_contrast',
              child: ListTile(
                leading: const Icon(Icons.contrast),
                title: Text(l10n.themeHighContrast),
                trailing: currentThemeId == 'high_contrast'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => selectTheme('high_contrast'),
              ),
            ),
            Semantics(
              button: true,
              selected: currentThemeId == 'light_high_contrast',
              child: ListTile(
                leading: const Icon(Icons.wb_sunny),
                title: Text(l10n.themeLightHighContrast),
                trailing: currentThemeId == 'light_high_contrast'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => selectTheme('light_high_contrast'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
        ],
      ),
    );
  }

  /// Show countdown dialog and exit app after 10 seconds.
  Future<void> _showExitCountdown(AppLocalizations l10n) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          _CountdownDialog(l10n: l10n, onComplete: _exitApp),
    );
  }

  /// Exit the application.
  void _exitApp() {
    if (kIsWeb) {
      // Web platform cannot exit
      return;
    }

    // Try platform-specific exit methods
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}

/// Countdown dialog widget for showing exit countdown.
class _CountdownDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final VoidCallback onComplete;

  const _CountdownDialog({required this.l10n, required this.onComplete});

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog> {
  int _remainingSeconds = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop();
        }
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(widget.l10n.resetAllSettingsSuccess),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              widget.l10n.resetAllSettingsExitMessage(_remainingSeconds),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
