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
import '../dialogs/version_info_dialog.dart';
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

  /// Open version info dialog and enable developer mode if activated.
  Future<void> _openVersionInfo() async {
    final developerModeEnabled = await VersionInfoDialog.show(context);
    if (developerModeEnabled && !_isDeveloperMode && mounted) {
      setState(() {
        _isDeveloperMode = true;
      });
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
            Consumer(
              builder: (context, ref, child) {
                final packageInfoAsync = ref.watch(packageInfoProvider);
                return ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.version),
                  subtitle: packageInfoAsync.when(
                    data: (info) => Text('${info.version}+${info.buildNumber}'),
                    loading: () => const Text('...'),
                    error: (error, _) => const Text('--'),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _openVersionInfo,
                );
              },
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

            // Notification Permission with status
            _PermissionStatusTile(
              icon: Icons.notifications_active,
              title: l10n.notificationPermission,
              description: l10n.notificationPermissionDesc,
              statusFuture: ref
                  .read(permissionServiceProvider)
                  .canPostNotifications(),
              grantedText: l10n.permissionStatusGranted,
              deniedText: l10n.permissionStatusDenied,
              buttonText: l10n.grantPermission,
              onButtonPressed: () async {
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
                  // Refresh the UI to show updated status
                  setState(() {});
                }
              },
            ),

            // Exact Alarm Permission with status
            _PermissionStatusTile(
              icon: Icons.alarm,
              title: l10n.exactAlarmPermission,
              description: l10n.exactAlarmPermissionDesc,
              statusFuture: ref
                  .read(permissionServiceProvider)
                  .canScheduleExactAlarms(),
              grantedText: l10n.exactAlarmStatusGranted,
              deniedText: l10n.exactAlarmStatusDenied,
              buttonText: l10n.settingsButton,
              onButtonPressed: () async {
                final permissionService = ref.read(permissionServiceProvider);
                await permissionService.openExactAlarmSettings();
                // Refresh the UI after returning from settings
                if (context.mounted) {
                  setState(() {});
                }
              },
            ),

            // Battery Optimization with status
            _BatteryOptimizationTile(
              title: l10n.batteryOptimizationSettings,
              description: l10n.batteryOptimizationDesc,
              statusFuture: ref
                  .read(permissionServiceProvider)
                  .isBatteryOptimizationDisabled(),
              isMiuiFuture: ref.read(permissionServiceProvider).isMiuiDevice(),
              disabledText: l10n.batteryOptimizationStatusDisabled,
              enabledText: l10n.batteryOptimizationStatusEnabled,
              unknownText: l10n.batteryOptimizationStatusUnknown,
              miuiHint: l10n.batteryOptimizationMiuiHint,
              buttonText: l10n.settingsButton,
              onButtonPressed: () async {
                final permissionService = ref.read(permissionServiceProvider);
                await permissionService.openBatteryOptimizationSettings();
                // Refresh the UI after returning from settings
                if (context.mounted) {
                  setState(() {});
                }
              },
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
              onTap: EnvironmentConfig.test
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LicenseAgreementPage(),
                        ),
                      );
                    },
            ),
            // OSS Licenses (third-party libraries)
            Consumer(
              builder: (context, ref, child) {
                return ListTile(
                  leading: const Icon(Icons.library_books),
                  title: Text(l10n.ossLicenses),
                  subtitle: Text(l10n.ossLicensesDesc),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: EnvironmentConfig.test
                      ? null
                      : () async {
                          final packageInfo = await ref.read(
                            packageInfoProvider.future,
                          );
                          if (context.mounted) {
                            showLicensePage(
                              context: context,
                              applicationName: 'GridTimer',
                              applicationVersion: packageInfo.version,
                            );
                          }
                        },
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
                    onPressed: EnvironmentConfig.test
                        ? null
                        : () => _showResetConfirmDialog(ref),
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
              _buildSectionHeader(l10n.debugTools),

              // 10-Second Test Timer
              ListTile(
                leading: Icon(Icons.timer_10, color: tokens.focusRing),
                title: Text(l10n.testTimer10s),
                subtitle: Text(l10n.testTimer10sDesc),
                trailing: ElevatedButton(
                  onPressed: () => _start10SecondTestTimer(ref),
                  child: Text(l10n.start),
                ),
              ),

              // Audio Test (for debugging)
              ListTile(
                leading: Icon(Icons.bug_report, color: tokens.warning),
                title: Text(l10n.audioTestDebug),
                subtitle: Text(l10n.audioTestDebugDesc),
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
                  title: Text(l10n.errorTestDebug),
                  subtitle: Text(l10n.errorTestDebugDesc),
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
                title: Text(l10n.exitDeveloperMode),
                subtitle: Text(l10n.exitDeveloperModeDesc),
                onTap: () {
                  setState(() {
                    _isDeveloperMode = false;
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
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToStartTestTimer(e.toString())),
              duration: const Duration(seconds: 3),
            ),
          );
        }
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
    // Block URL launching in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint('URL launch blocked in test environment');
      return;
    }

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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.languageEnglish),
                leading: const Icon(Icons.language),
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(l10n.languageChineseSimplified),
                leading: const Icon(Icons.language),
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('zh'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
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
        content: SingleChildScrollView(
          child: Column(
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
    // Block app exit in test environment to prevent interference with Monkey testing
    if (EnvironmentConfig.test) {
      debugPrint('App exit blocked in test environment');
      return;
    }

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
        content: SingleChildScrollView(
          child: Column(
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
      ),
    );
  }
}

/// Widget to display a permission status with icon, text and action button.
class _PermissionStatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Future<bool> statusFuture;
  final String grantedText;
  final String deniedText;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const _PermissionStatusTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusFuture,
    required this.grantedText,
    required this.deniedText,
    required this.buttonText,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: statusFuture,
      builder: (context, snapshot) {
        final isGranted = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: 4),
              if (isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Row(
                  children: [
                    Icon(
                      isGranted ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: isGranted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isGranted ? grantedText : deniedText,
                        style: TextStyle(
                          color: isGranted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          isThreeLine: true,
          trailing: ElevatedButton(
            onPressed: onButtonPressed,
            child: Text(buttonText),
          ),
        );
      },
    );
  }
}

/// Widget to display battery optimization status.
/// Note: For battery optimization, "disabled" (true) is the recommended state.
class _BatteryOptimizationTile extends StatelessWidget {
  final String title;
  final String description;
  final Future<bool?> statusFuture;
  final Future<bool> isMiuiFuture;
  final String disabledText; // Battery optimization disabled (recommended)
  final String enabledText; // Battery optimization enabled (may affect alarms)
  final String unknownText; // Status cannot be determined (e.g., MIUI)
  final String miuiHint; // Hint for MIUI users
  final String buttonText;
  final VoidCallback onButtonPressed;

  const _BatteryOptimizationTile({
    required this.title,
    required this.description,
    required this.statusFuture,
    required this.isMiuiFuture,
    required this.disabledText,
    required this.enabledText,
    required this.unknownText,
    required this.miuiHint,
    required this.buttonText,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([statusFuture, isMiuiFuture]),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        // status can be: true (disabled/good), false (enabled/bad), null (unknown)
        final bool? status = snapshot.data?[0] as bool?;
        final bool isMiui = (snapshot.data?[1] as bool?) ?? false;

        // Determine display state
        final bool isUnknown = status == null;
        final bool isDisabled = status == true;

        // Choose icon and color
        IconData statusIcon;
        Color statusColor;
        String statusText;

        if (isUnknown) {
          statusIcon = Icons.help_outline;
          statusColor = Colors.blue;
          statusText = unknownText;
        } else if (isDisabled) {
          statusIcon = Icons.check_circle;
          statusColor = Colors.green;
          statusText = disabledText;
        } else {
          statusIcon = Icons.warning;
          statusColor = Colors.orange;
          statusText = enabledText;
        }

        return ListTile(
          leading: const Icon(Icons.battery_saver),
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: 4),
              if (isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // Show MIUI hint if on MIUI device
                if (isMiui) ...[
                  const SizedBox(height: 4),
                  Text(
                    miuiHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ],
          ),
          isThreeLine: true,
          trailing: ElevatedButton(
            onPressed: onButtonPressed,
            child: Text(buttonText),
          ),
        );
      },
    );
  }
}
