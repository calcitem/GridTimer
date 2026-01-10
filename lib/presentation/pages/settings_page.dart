import 'dart:async';
import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/locale_provider.dart';
import '../../app/providers.dart';
import '../../core/config/environment_config.dart';
import '../../core/config/platform_capabilities.dart';
import '../../core/domain/entities/app_settings.dart';
import '../../core/domain/enums.dart';
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

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  // Developer mode state
  bool _isDeveloperMode = false;

  // Android SDK version (0 = non-Android or unknown)
  int _androidSdkVersion = 0;

  // Whether this is a MIUI device
  bool _isMiuiDevice = false;

  // Unique key to force rebuild of permission-related FutureBuilders
  // when returning from system settings
  int _permissionRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadAndroidSdkVersion();
    _loadMiuiDeviceInfo();
    // Add lifecycle observer to refresh permission status when returning from settings
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh permission status when app resumes (e.g., returning from system settings)
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatus();
    }
  }

  /// Refresh permission status by incrementing the key and triggering rebuild.
  void _refreshPermissionStatus() {
    if (mounted) {
      setState(() {
        _permissionRefreshKey++;
      });
    }
  }

  Future<void> _loadAndroidSdkVersion() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final permissionService = ref.read(permissionServiceProvider);
    final sdkVersion = await permissionService.getAndroidSdkVersion();
    if (mounted) {
      setState(() {
        _androidSdkVersion = sdkVersion;
      });
    }
  }

  Future<void> _loadMiuiDeviceInfo() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final permissionService = ref.read(permissionServiceProvider);
    final isMiui = await permissionService.isMiuiDevice();
    if (mounted) {
      setState(() {
        _isMiuiDevice = isMiui;
      });
    }
  }

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

            // Alarm Channel Sound (Android 8.0+ only, API 26+)
            // Notification channels were introduced in Android 8.0 (Oreo).
            // On older versions or non-Android platforms, this setting is not applicable.
            if (PlatformCapabilities.supportsNotificationChannels &&
                _androidSdkVersion >= 26)
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.volume_up),
                    title: Text(l10n.alarmSoundSettings),
                    subtitle: Text(l10n.alarmSoundSettingsDesc),
                  ),
                  // Show MIUI-specific hint
                  if (_isMiuiDevice)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.alarmSoundSettingsMiuiHint,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final permissionService = ref.read(
                            permissionServiceProvider,
                          );
                          try {
                            await permissionService
                                .openNotificationChannelSettings(
                                  channelId: 'gt.alarm.timeup.default.v3',
                                );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.failedToOpenChannelSettings(
                                      e.toString(),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(l10n.goToSettings),
                      ),
                    ),
                  ),
                ],
              ),

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

            // Vibration (mobile platforms only)
            if (PlatformCapabilities.supportsVibration)
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: Text(l10n.vibration),
                subtitle: Text(l10n.vibrationDesc),
                value: settings.vibrationEnabled,
                onChanged: (value) {
                  // Show dialog to warn about system vibration settings
                  _showVibrationWarningDialog(context, ref, l10n, value);
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

            // Gesture Settings (mobile platforms only - requires sensors)
            if (PlatformCapabilities.supportsGestureControls)
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

            const Divider(),

            // App Killed Warning (Android only - iOS handles background differently)
            if (PlatformCapabilities.canBeKilledBySystem)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.appKilledWarning,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Alarm Troubleshooting / Compatibility Guide (Android only)
            if (PlatformCapabilities.needsAlarmTroubleshooting)
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l10n.alarmTroubleshooting),
                subtitle: Text(l10n.alarmTroubleshootingDesc),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => AlarmTroubleshootingDialog.show(context),
              ),

            // Only show permissions section if any permissions are relevant
            if (PlatformCapabilities.requiresNotificationPermission ||
                PlatformCapabilities.hasExactAlarmPermission ||
                PlatformCapabilities.hasFullScreenIntentPermission ||
                PlatformCapabilities.hasBatteryOptimization)
              const Divider(),

            // Permissions Section (mobile platforms only)
            if (PlatformCapabilities.requiresNotificationPermission ||
                PlatformCapabilities.hasExactAlarmPermission ||
                PlatformCapabilities.hasFullScreenIntentPermission ||
                PlatformCapabilities.hasBatteryOptimization)
              _buildSectionHeader(l10n.permissions),

            // Notification Permission with status (mobile platforms only)
            // Use key to force rebuild when returning from system settings
            if (PlatformCapabilities.requiresNotificationPermission)
              _PermissionStatusTile(
                key: ValueKey('notification_$_permissionRefreshKey'),
                icon: Icons.notifications_active,
                title: l10n.notificationPermission,
                description: l10n.notificationPermissionDesc,
                statusFuture: ref
                    .read(permissionServiceProvider)
                    .canPostNotifications(),
                grantedText: l10n.permissionStatusGranted,
                deniedText: l10n.permissionStatusDenied,
                notRequiredText: l10n.permissionNotRequiredStatus,
                buttonText: l10n.grantPermission,
                androidSdkVersion: _androidSdkVersion,
                // Android 13 (API 33)+ requires runtime notification permission
                minSdkVersionRequired: 33,
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
                    _refreshPermissionStatus();
                  }
                },
              ),

            // Exact Alarm Permission with status (Android 12+ only)
            // Description varies by Android version:
            // - Android < 31: Not required
            // - Android 31-32: Required, user must manually grant
            // - Android 33: Pre-granted by system
            // - Android 34+: Required, user must manually grant
            if (PlatformCapabilities.hasExactAlarmPermission)
              _PermissionStatusTile(
                key: ValueKey('exact_alarm_$_permissionRefreshKey'),
                icon: Icons.alarm,
                title: l10n.exactAlarmPermission,
                description: _androidSdkVersion == 33
                    ? l10n.exactAlarmPermissionDescApi33
                    : l10n.exactAlarmPermissionDesc,
                statusFuture: ref
                    .read(permissionServiceProvider)
                    .canScheduleExactAlarms(),
                grantedText: l10n.exactAlarmStatusGranted,
                deniedText: l10n.exactAlarmStatusDenied,
                notRequiredText: l10n.permissionNotRequiredStatus,
                buttonText: l10n.settingsButton,
                androidSdkVersion: _androidSdkVersion,
                // Android 12 (API 31)+ restricts exact alarms
                minSdkVersionRequired: 31,
                onButtonPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  await permissionService.openExactAlarmSettings();
                  // Status will be refreshed when app resumes via lifecycle observer
                },
              ),

            // Full-Screen Intent Permission with status (Android 14+ only)
            if (PlatformCapabilities.hasFullScreenIntentPermission)
              _PermissionStatusTile(
                key: ValueKey('fullscreen_$_permissionRefreshKey'),
                icon: Icons.fullscreen,
                title: l10n.fullScreenIntentPermission,
                description: l10n.fullScreenIntentPermissionDesc,
                statusFuture: ref
                    .read(permissionServiceProvider)
                    .canUseFullScreenIntent(),
                grantedText: l10n.fullScreenIntentStatusGranted,
                deniedText: l10n.fullScreenIntentStatusDenied,
                notRequiredText: l10n.permissionNotRequiredStatus,
                buttonText: l10n.settingsButton,
                androidSdkVersion: _androidSdkVersion,
                // Android 14 (API 34)+ restricts full-screen intents
                minSdkVersionRequired: 34,
                onButtonPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  await permissionService.openFullScreenIntentSettings();
                  // Status will be refreshed when app resumes via lifecycle observer
                },
              ),

            // Battery Optimization with status (Android only)
            if (PlatformCapabilities.hasBatteryOptimization)
              _BatteryOptimizationTile(
                key: ValueKey('battery_$_permissionRefreshKey'),
                title: l10n.batteryOptimizationSettings,
                description: l10n.batteryOptimizationDesc,
                legacyDescription: l10n.batteryOptimizationLegacyDesc,
                statusFuture: ref
                    .read(permissionServiceProvider)
                    .isBatteryOptimizationDisabled(),
                manufacturerTypeFuture: ref
                    .read(permissionServiceProvider)
                    .getDeviceManufacturerType(),
                disabledText: l10n.batteryOptimizationStatusDisabled,
                enabledText: l10n.batteryOptimizationStatusEnabled,
                unknownText: l10n.batteryOptimizationStatusUnknown,
                l10n: l10n,
                buttonText: l10n.settingsButton,
                androidSdkVersion: _androidSdkVersion,
                onButtonPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  await permissionService.openBatteryOptimizationSettings();
                  // Status will be refreshed when app resumes via lifecycle observer
                },
              ),

            const Divider(),

            // About Section
            _buildSectionHeader(l10n.about),
            // Version
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
                              applicationName: 'Grid Timer',
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

              // Alarm Reliability Mode (Debug only)
              ListTile(
                leading: const Icon(Icons.settings_suggest),
                title: Text(l10n.alarmReliabilityMode),
                subtitle: Text(
                  _getAlarmReliabilityModeName(
                    settings.alarmReliabilityMode,
                    l10n,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showAlarmReliabilityModeDialog(
                  context,
                  ref,
                  l10n,
                  settings,
                ),
              ),

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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    try {
      final timerService = ref.read(timerServiceProvider);

      // Check if any timer is already running
      if (timerService.hasActiveTimers()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.stopActiveTimersBeforeTest),
              duration: const Duration(seconds: 3),
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
          SnackBar(
            content: Text(l10n.testTimerStarted),
            duration: const Duration(seconds: 3),
          ),
        );

        // Close settings and return to main page
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToStartTestTimer(e.toString())),
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
    // On Web, accessing Platform.localeName can fail or give different results.
    // However, platformDispatcher.locale is generally safe.
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return systemLocale.languageCode == 'zh';
  }

  /// Show vibration warning dialog.
  void _showVibrationWarningDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool newValue,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vibration),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.vibrationSystemWarning),
              if (!kIsWeb && Platform.isAndroid) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () =>
                      _openSystemVibrationSettings(dialogContext, l10n),
                  child: Text(
                    l10n.openSystemVibrationSettings,
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).toggleVibration(newValue);
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  /// Open system vibration settings (Android only).
  Future<void> _openSystemVibrationSettings(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    const channel = MethodChannel('com.calcitem.gridtimer/system_settings');
    try {
      await channel.invokeMethod<void>('openVibrationSettings');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorText(e.toString()))));
      }
    }
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
    if (themeId == 'traditional') return l10n.themeTraditional;
    if (themeId == 'pastel_garden') return l10n.themePastelGarden;
    if (themeId == 'ink_vermilion') return l10n.themeInkVermilion;
    if (themeId == 'glacial_blue') return l10n.themeGlacialBlue;
    if (themeId == 'classic_navy') return l10n.themeClassicNavy;
    return l10n.themeSoftDark;
  }

  String _getAlarmReliabilityModeName(
    AlarmReliabilityMode mode,
    AppLocalizations l10n,
  ) {
    switch (mode) {
      case AlarmReliabilityMode.appOnly:
        return l10n.alarmReliabilityModeAppOnly;
      case AlarmReliabilityMode.notification:
        return l10n.alarmReliabilityModeNotification;
      case AlarmReliabilityMode.alarmClock:
        return l10n.alarmReliabilityModeAlarmClock;
    }
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
              Semantics(
                button: true,
                selected: currentThemeId == 'traditional',
                child: ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(l10n.themeTraditional),
                  trailing: currentThemeId == 'traditional'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => selectTheme('traditional'),
                ),
              ),
              Semantics(
                button: true,
                selected: currentThemeId == 'pastel_garden',
                child: ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(l10n.themePastelGarden),
                  trailing: currentThemeId == 'pastel_garden'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => selectTheme('pastel_garden'),
                ),
              ),
              Semantics(
                button: true,
                selected: currentThemeId == 'ink_vermilion',
                child: ListTile(
                  leading: const Icon(Icons.brush),
                  title: Text(l10n.themeInkVermilion),
                  trailing: currentThemeId == 'ink_vermilion'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => selectTheme('ink_vermilion'),
                ),
              ),
              Semantics(
                button: true,
                selected: currentThemeId == 'glacial_blue',
                child: ListTile(
                  leading: const Icon(Icons.snowing),
                  title: Text(l10n.themeGlacialBlue),
                  trailing: currentThemeId == 'glacial_blue'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => selectTheme('glacial_blue'),
                ),
              ),
              Semantics(
                button: true,
                selected: currentThemeId == 'classic_navy',
                child: ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(l10n.themeClassicNavy),
                  trailing: currentThemeId == 'classic_navy'
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => selectTheme('classic_navy'),
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

  void _showAlarmReliabilityModeDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AppSettings settings,
  ) {
    void selectMode(AlarmReliabilityMode mode) {
      ref.read(appSettingsProvider.notifier).updateAlarmReliabilityMode(mode);
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.alarmReliabilityMode),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.alarmReliabilityModeDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                selected:
                    settings.alarmReliabilityMode ==
                    AlarmReliabilityMode.appOnly,
                child: ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(l10n.alarmReliabilityModeAppOnly),
                  subtitle: Text(l10n.alarmReliabilityModeAppOnlyDesc),
                  trailing:
                      settings.alarmReliabilityMode ==
                          AlarmReliabilityMode.appOnly
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => selectMode(AlarmReliabilityMode.appOnly),
                ),
              ),
              Semantics(
                button: true,
                selected:
                    settings.alarmReliabilityMode ==
                    AlarmReliabilityMode.notification,
                child: ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: Text(l10n.alarmReliabilityModeNotification),
                  subtitle: Text(l10n.alarmReliabilityModeNotificationDesc),
                  trailing:
                      settings.alarmReliabilityMode ==
                          AlarmReliabilityMode.notification
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => selectMode(AlarmReliabilityMode.notification),
                ),
              ),
              Semantics(
                button: true,
                selected:
                    settings.alarmReliabilityMode ==
                    AlarmReliabilityMode.alarmClock,
                child: ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(l10n.alarmReliabilityModeAlarmClock),
                  subtitle: Text(l10n.alarmReliabilityModeAlarmClockDesc),
                  trailing:
                      settings.alarmReliabilityMode ==
                          AlarmReliabilityMode.alarmClock
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => selectMode(AlarmReliabilityMode.alarmClock),
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
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemNavigator.pop();
    } else if (!kIsWeb) {
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
  final String notRequiredText;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final int androidSdkVersion;
  final int minSdkVersionRequired;

  const _PermissionStatusTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.statusFuture,
    required this.grantedText,
    required this.deniedText,
    required this.notRequiredText,
    required this.buttonText,
    required this.onButtonPressed,
    required this.androidSdkVersion,
    required this.minSdkVersionRequired,
  });

  @override
  Widget build(BuildContext context) {
    // Check if permission is not required on this Android version
    // androidSdkVersion == 0 means we don't know yet or it's not Android
    final isNotRequired =
        androidSdkVersion > 0 && androidSdkVersion < minSdkVersionRequired;

    return FutureBuilder<bool>(
      future: statusFuture,
      builder: (context, snapshot) {
        final isGranted = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        // Determine status display
        IconData statusIcon;
        Color statusColor;
        String statusText;

        if (isNotRequired) {
          statusIcon = Icons.info_outline;
          statusColor = Colors.blue;
          statusText = notRequiredText;
        } else if (isGranted) {
          statusIcon = Icons.check_circle;
          statusColor = Colors.green;
          statusText = grantedText;
        } else {
          statusIcon = Icons.warning;
          statusColor = Colors.orange;
          statusText = deniedText;
        }

        return Column(
          children: [
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description),
                  const SizedBox(height: 4),
                  if (isLoading && !isNotRequired)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
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
                ],
              ),
              isThreeLine: true,
            ),
            // Hide the button if permission is not required on this Android version
            if (!isNotRequired)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    child: Text(buttonText),
                  ),
                ),
              ),
          ],
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
  final String legacyDescription;
  final Future<bool?> statusFuture;
  final Future<String> manufacturerTypeFuture;
  final String disabledText; // Battery optimization disabled (recommended)
  final String enabledText; // Battery optimization enabled (may affect alarms)
  final String unknownText; // Status cannot be determined (e.g., MIUI)
  final AppLocalizations l10n; // Localization delegate
  final String buttonText;
  final VoidCallback onButtonPressed;
  final int androidSdkVersion;

  const _BatteryOptimizationTile({
    super.key,
    required this.title,
    required this.description,
    required this.legacyDescription,
    required this.statusFuture,
    required this.manufacturerTypeFuture,
    required this.disabledText,
    required this.enabledText,
    required this.unknownText,
    required this.l10n,
    required this.buttonText,
    required this.onButtonPressed,
    required this.androidSdkVersion,
  });

  @override
  Widget build(BuildContext context) {
    // For older Android versions (< Android 8 / API 26), use legacy description
    final useLegacyDesc = androidSdkVersion > 0 && androidSdkVersion < 26;
    final effectiveDescription = useLegacyDesc
        ? legacyDescription
        : description;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([statusFuture, manufacturerTypeFuture]),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        // status can be: true (disabled/good), false (enabled/bad), null (unknown)
        final bool? status = snapshot.data?[0] as bool?;
        final String manufacturerType =
            (snapshot.data?[1] as String?) ?? 'standard';

        // Determine display state
        final bool isUnknown = status == null;
        final bool isDisabled = status == true;
        // Determine hint text based on manufacturer (only for newer Android)
        // Show hints when battery optimization is NOT disabled (needs user action)
        String? specificHint;
        if (!useLegacyDesc && !isDisabled) {
          if (manufacturerType == 'miui') {
            specificHint = l10n.batteryOptimizationMiuiHint;
          } else if (manufacturerType == 'honor_huawei') {
            specificHint = l10n.batteryOptimizationHuaweiHint;
          } else if (manufacturerType == 'coloros') {
            specificHint = l10n.batteryOptimizationOppoHint;
          } else if (manufacturerType == 'funtouchos') {
            specificHint = l10n.batteryOptimizationVivoHint;
          } else if (manufacturerType == 'standard') {
            // Standard Android (e.g., Pixel): hint about tapping text vs toggle
            specificHint = l10n.batteryOptimizationStandardHint;
          } else {
            specificHint = l10n.batteryOptimizationOemHint;
          }
        }

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

        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.battery_saver),
              title: Text(title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(effectiveDescription),
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
                    // Show OEM-specific hint if applicable
                    if (specificHint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        specificHint,
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  child: Text(buttonText),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
