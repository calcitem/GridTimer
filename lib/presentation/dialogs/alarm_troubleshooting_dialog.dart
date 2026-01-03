import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import 'safety_disclaimer_dialog.dart';

/// Alarm troubleshooting dialog.
///
/// This dialog helps users understand why alarm behavior can differ across
/// Android versions and OEM ROMs, and provides quick links to the most relevant
/// system settings.
class AlarmTroubleshootingDialog extends ConsumerStatefulWidget {
  const AlarmTroubleshootingDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const AlarmTroubleshootingDialog(),
    );
  }

  @override
  ConsumerState<AlarmTroubleshootingDialog> createState() =>
      _AlarmTroubleshootingDialogState();
}

class _AlarmTroubleshootingDialogState
    extends ConsumerState<AlarmTroubleshootingDialog> {
  // Android SDK version (0 = non-Android or unknown)
  int _androidSdkVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadAndroidSdkVersion();
  }

  Future<void> _loadAndroidSdkVersion() async {
    if (!Platform.isAndroid) return;

    final permissionService = ref.read(permissionServiceProvider);
    final sdkVersion = await permissionService.getAndroidSdkVersion();
    if (mounted) {
      setState(() {
        _androidSdkVersion = sdkVersion;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final permissionService = ref.read(permissionServiceProvider);
    final notificationService = ref.read(notificationServiceProvider);

    return AlertDialog(
      title: Semantics(
        header: true,
        child: Row(
          children: [
            const Icon(Icons.help_outline, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.alarmTroubleshootingDialogTitle)),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.alarmTroubleshootingDialogIntro),
            const SizedBox(height: 16),
            Text(
              l10n.alarmTroubleshootingSteps,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.alarmTroubleshootingMiui,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.alarmTroubleshootingQuickActions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Notification channel settings only for Android 8.0+ (API 26+)
                if (_androidSdkVersion >= 26) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await notificationService.ensureAndroidChannels(
                          soundKeys: {'default'},
                        );
                        await permissionService.openNotificationChannelSettings(
                          channelId: 'gt.alarm.timeup.default.v3',
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
                    icon: const Icon(Icons.volume_up),
                    label: Text(l10n.alarmTroubleshootingOpenChannel),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await permissionService.openNotificationSettings();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.errorText(e.toString()))),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: Text(l10n.alarmTroubleshootingOpenNotifications),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await permissionService.openExactAlarmSettings();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.errorText(e.toString()))),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.alarm),
                  label: Text(l10n.alarmTroubleshootingOpenExactAlarm),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await permissionService.openBatteryOptimizationSettings();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.errorText(e.toString()))),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.battery_saver),
                  label: Text(l10n.alarmTroubleshootingOpenBattery),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    SafetyDisclaimerDialog.show(context);
                  },
                  child: Text(l10n.alarmTroubleshootingViewSafetyNotice),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
