import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/locale_provider.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import 'audio_test_page.dart';
import 'grid_durations_settings_page.dart';
import 'sound_settings_page.dart';
import 'tts_settings_page.dart';

/// Settings page for configuring app preferences and timer settings.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            // App Information Section
            _buildSectionHeader(l10n.appInformation),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.version),
              subtitle: const Text('1.0.0+1'),
            ),
            const Divider(),

            // Timer Settings Section
            _buildSectionHeader(l10n.timerSettings),
            
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
            
            // Keep Screen On
            SwitchListTile(
              secondary: const Icon(Icons.screen_lock_portrait),
              title: Text(l10n.keepScreenOn),
              subtitle: Text(l10n.keepScreenOnDesc),
              value: settings.keepScreenOnWhileRunning,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).toggleKeepScreenOn(value);
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
            
            const Divider(),
            
            // Audio Test (for debugging)
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text('音频测试 (调试用)'),
              subtitle: const Text('诊断声音问题'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AudioTestPage()),
                );
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
                  MaterialPageRoute(
                    builder: (_) => const SoundSettingsPage(),
                  ),
                );
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
                  MaterialPageRoute(
                    builder: (_) => const TtsSettingsPage(),
                  ),
                );
              },
            ),
            
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
            
            // Language
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.languageSettings),
              subtitle: Text(_getLanguageName(currentLocale, l10n)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context, ref, l10n),
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
                  final granted = await notification.requestPostNotificationsPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(granted ? '通知权限已授予' : '通知权限被拒绝，请在系统设置中手动授予'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('授予权限'),
              ),
            ),
            
            // Exact Alarm Permission
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('精确闹钟权限'),
              subtitle: const Text('确保计时器准时提醒（Android 14+ 需要）'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  await permissionService.openExactAlarmSettings();
                },
                child: const Text('设置'),
              ),
            ),
            
            // Battery Optimization
            ListTile(
              leading: const Icon(Icons.battery_saver),
              title: const Text('电池优化设置'),
              subtitle: const Text('关闭电池优化以确保后台提醒可靠'),
              trailing: ElevatedButton(
                onPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  await permissionService.openBatteryOptimizationSettings();
                },
                child: const Text('设置'),
              ),
            ),
            
            const Divider(),

            // About Section
            _buildSectionHeader(l10n.about),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(l10n.license),
              subtitle: Text(l10n.licenseDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'GridTimer',
                  applicationVersion: '1.0.0',
                );
              },
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

  /// Build a section header widget.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
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
}

