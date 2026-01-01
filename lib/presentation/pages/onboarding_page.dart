import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/locale_provider.dart';
import '../../app/providers.dart';
import '../../core/config/environment_config.dart';
import '../../l10n/app_localizations.dart';
import '../dialogs/privacy_policy_dialog.dart';
import 'grid_page.dart';

/// Onboarding page for first-time users.
/// Guides the user through necessary permissions.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final _LifecycleObserver _lifecycleObserver;
  bool _privacyPolicyChecked = false;

  // Permission statuses
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;
  bool _batteryOptimizationIgnored = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // Re-check permissions when returning from settings
    _lifecycleObserver = _LifecycleObserver(this);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check and show privacy policy on first launch only, before onboarding starts
    if (!_privacyPolicyChecked) {
      _privacyPolicyChecked = true;
      _checkAndShowPrivacyPolicy();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final permissionService = ref.read(permissionServiceProvider);

    final notification = await permissionService.canPostNotifications();
    final exactAlarm = await permissionService.canScheduleExactAlarms();
    // Battery optimization: checking if *ignoring* optimizations is enabled.
    // The service doesn't expose a direct check for "isIgnoringBatteryOptimizations",
    // but typically we can check permission_handler's ignoreBatteryOptimizations status.
    // Since the service wrapper might not expose it, we'll check directly via permission_handler for now
    // or assume we need to ask if we can't check.
    // Let's check using Permission.ignoreBatteryOptimizations.status
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final batteryIgnored = batteryStatus.isGranted;

    // Full screen intent (Android 14+)
    // Permission.scheduleExactAlarm covers exact alarms.
    // Full screen intent is special.
    // We'll trust the service or basic checks.

    if (mounted) {
      setState(() {
        _notificationGranted = notification;
        _exactAlarmGranted = exactAlarm;
        _batteryOptimizationIgnored = batteryIgnored;
      });
    }
  }

  void _refreshPermissions() {
    _checkPermissions();
  }

  /// Check if the effective locale is Chinese.
  ///
  /// Returns true if:
  /// - User explicitly selected Chinese, OR
  /// - User is following system and system locale is Chinese
  bool _isChineseLocale(BuildContext context) {
    final userLocale = ref.read(localeProvider);

    // If user has explicitly set a locale, use that
    if (userLocale != null) {
      return userLocale.languageCode == 'zh';
    }

    // Otherwise, check the system locale via Localizations
    final systemLocale = Localizations.localeOf(context);
    return systemLocale.languageCode == 'zh';
  }

  /// Check if privacy policy needs to be shown and display it if necessary.
  ///
  /// For Chinese locale users:
  /// - Show privacy policy dialog first (if not yet accepted)
  ///
  /// This runs BEFORE the onboarding wizard starts, ensuring users see
  /// the privacy policy before any permission requests.
  Future<void> _checkAndShowPrivacyPolicy() async {
    // Wait for settings to be loaded asynchronously
    final settingsAsync = ref.read(appSettingsProvider);

    // Wait for the future to complete if still loading
    await settingsAsync.when(
      data: (_) async {}, // Already loaded, continue
      loading: () async {
        // Wait for settings to load
        await ref.read(appSettingsProvider.future);
      },
      error: (_, _) async {}, // Skip on error
    );

    // Now read the loaded settings
    final settings = ref.read(appSettingsProvider).value;

    if (settings == null) {
      debugPrint(
        'OnboardingPage: Settings not loaded, skipping privacy policy check',
      );
      return;
    }

    // Wait for first frame to complete to avoid showing during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Check if Chinese locale and privacy policy not yet accepted
      final isChinese = _isChineseLocale(context);
      debugPrint('OnboardingPage: Is Chinese locale = $isChinese');
      debugPrint(
        'OnboardingPage: Privacy policy accepted = ${settings.privacyPolicyAccepted}',
      );

      if (isChinese && !settings.privacyPolicyAccepted) {
        debugPrint('OnboardingPage: Showing privacy policy dialog');

        final accepted = await PrivacyPolicyDialog.show(context);

        debugPrint(
          'OnboardingPage: User ${accepted ? "accepted" : "dismissed"} privacy policy',
        );

        if (accepted && mounted) {
          await ref
              .read(appSettingsProvider.notifier)
              .updatePrivacyPolicyAccepted(true);
          debugPrint(
            'OnboardingPage: Saved privacy policy acceptance to storage',
          );
        } else if (!accepted && mounted) {
          // User did not accept privacy policy - they cannot proceed
          // Block exiting app in test environment to prevent interference with Monkey testing
          if (EnvironmentConfig.test) {
            debugPrint(
              'OnboardingPage: User did not accept privacy policy, but exit blocked in test environment',
            );
            // In test mode, just mark it as accepted to allow testing to continue
            await ref
                .read(appSettingsProvider.notifier)
                .updatePrivacyPolicyAccepted(true);
          } else {
            // Exit the app
            debugPrint(
              'OnboardingPage: User did not accept privacy policy, exiting app',
            );
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
          }
        }
      }
    });
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    await ref.read(appSettingsProvider.notifier).setOnboardingCompleted(true);
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const GridPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only Android needs complex permissions for this app usually.
    // iOS handles notifications, but exact alarm/battery/overlay are Android specific concepts.
    final isAndroid = Platform.isAndroid;
    final l10n = AppLocalizations.of(context)!;

    final steps = <Widget>[
      _buildWelcomeStep(),
      _buildNotificationStep(isAndroid),
      if (isAndroid) _buildExactAlarmStep(),
      if (isAndroid) _buildBatteryStep(),
      if (isAndroid) _buildAlarmSoundStep(l10n),
      // Full screen intent is implicitly handled or less critical to nag about upfront if exact alarm works
      // but let's include it if we want to be "comprehensive"
      _buildCompletionStep(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: steps,
              ),
            ),
            _buildBottomControls(steps.length),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(int totalPages) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots indicator
          Semantics(
            label: 'Page ${_currentPage + 1} of $totalPages',
            child: Row(
              children: List.generate(
                totalPages,
                (index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
          // Next/Finish button
          ElevatedButton(
            onPressed: () {
              if (_currentPage == totalPages - 1) {
                _completeOnboarding();
              } else {
                _nextPage();
              }
            },
            child: Text(
              _currentPage == totalPages - 1
                  ? l10n.onboardingStartUsing
                  : l10n.onboardingNext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String description,
    required IconData icon,
    required Widget action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 80, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    action,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeStep() {
    final l10n = AppLocalizations.of(context)!;

    return _buildStepContainer(
      title: l10n.onboardingWelcomeTitle,
      description: l10n.onboardingWelcomeDesc,
      icon: Icons.timer,
      action: const SizedBox.shrink(),
    );
  }

  Widget _buildNotificationStep(bool isAndroid) {
    final l10n = AppLocalizations.of(context)!;

    return _buildStepContainer(
      title: l10n.onboardingNotificationTitle,
      description: l10n.onboardingNotificationDesc,
      icon: Icons.notifications_active,
      action: _notificationGranted
          ? const _GrantedLabel()
          : ElevatedButton.icon(
              onPressed: () async {
                final service = ref.read(notificationServiceProvider);
                // On Android 13+, this triggers the dialog.
                // On iOS, it triggers the dialog.
                await service.requestPostNotificationsPermission();
                await _checkPermissions();
              },
              icon: const Icon(Icons.notification_add),
              label: Text(l10n.onboardingGrantNotification),
            ),
    );
  }

  Widget _buildExactAlarmStep() {
    final l10n = AppLocalizations.of(context)!;

    return _buildStepContainer(
      title: l10n.onboardingExactAlarmTitle,
      description: l10n.onboardingExactAlarmDesc,
      icon: Icons.access_alarm,
      action: _exactAlarmGranted
          ? const _GrantedLabel()
          : ElevatedButton.icon(
              onPressed: () async {
                final service = ref.read(notificationServiceProvider);
                // This might open system settings on some Android versions
                await service.requestExactAlarmPermission();
                await _checkPermissions();
              },
              icon: const Icon(Icons.settings),
              label: Text(l10n.onboardingGrantExactAlarm),
            ),
    );
  }

  Widget _buildBatteryStep() {
    final l10n = AppLocalizations.of(context)!;

    return _buildStepContainer(
      title: l10n.onboardingBatteryTitle,
      description: l10n.onboardingBatteryDesc,
      icon: Icons.battery_alert,
      action: _batteryOptimizationIgnored
          ? const _GrantedLabel()
          : ElevatedButton.icon(
              onPressed: () async {
                final service = ref.read(permissionServiceProvider);
                await service.openBatteryOptimizationSettings();
                // User has to manually change it, so we can't auto-detect immediately often,
                // but checking on resume helps.
              },
              icon: const Icon(Icons.settings_power),
              label: Text(l10n.onboardingOpenBatterySettings),
            ),
    );
  }

  Widget _buildAlarmSoundStep(AppLocalizations l10n) {
    return _buildStepContainer(
      title: l10n.onboardingCheckSoundTitle,
      description: l10n.onboardingCheckSoundDesc,
      icon: Icons.volume_up,
      action: ElevatedButton.icon(
        onPressed: () async {
          // Ensure notification channel exists before opening settings.
          // This avoids the issue where Android immediately returns to the app
          // if the channel doesn't exist.
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.ensureAndroidChannels(
            soundKeys: {'default'},
          );

          final service = ref.read(permissionServiceProvider);
          try {
            await service.openNotificationChannelSettings(
              channelId: 'gt.alarm.timeup.default.v2',
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.errorText(e.toString()))),
              );
            }
          }
        },
        icon: const Icon(Icons.settings_voice),
        label: Text(l10n.onboardingCheckSoundBtn),
      ),
    );
  }

  Widget _buildCompletionStep() {
    final l10n = AppLocalizations.of(context)!;

    return _buildStepContainer(
      title: l10n.onboardingCompletionTitle,
      description: l10n.onboardingCompletionDesc,
      icon: Icons.check_circle_outline,
      action: const SizedBox.shrink(), // Button is in bottom bar
    );
  }
}

class _GrantedLabel extends StatelessWidget {
  const _GrantedLabel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            l10n.onboardingGranted,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final _OnboardingPageState state;

  _LifecycleObserver(this.state);

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      state._refreshPermissions();
    }
  }
}
