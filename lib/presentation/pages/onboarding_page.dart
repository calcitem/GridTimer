import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
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

  // Permission statuses
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;
  bool _batteryOptimizationIgnored = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // Re-check permissions when returning from settings
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
  }

  @override
  void dispose() {
    _pageController.dispose();
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots indicator
          Row(
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
          // Next/Finish button
          ElevatedButton(
            onPressed: () {
              if (_currentPage == totalPages - 1) {
                _completeOnboarding();
              } else {
                _nextPage();
              }
            },
            child: Text(_currentPage == totalPages - 1 ? '开始使用' : '下一步'),
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
    return Padding(
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
    );
  }

  Widget _buildWelcomeStep() {
    return _buildStepContainer(
      title: '欢迎使用 GridTimer',
      description: '为了确保计时器准确运行，我们需要进行一些简单的设置。\n\n这只需要一分钟。',
      icon: Icons.timer,
      action: const SizedBox.shrink(),
    );
  }

  Widget _buildNotificationStep(bool isAndroid) {
    return _buildStepContainer(
      title: '通知权限',
      description: 'GridTimer 需要通知权限，以便在倒计时结束时提醒您。\n\n如果没有此权限，您可能会错过计时结束的提醒。',
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
              icon: const Icon(Icons.check),
              label: const Text('授予通知权限'),
            ),
    );
  }

  Widget _buildExactAlarmStep() {
    return _buildStepContainer(
      title: '精确闹钟权限',
      description: '为了确保计时精确到秒，GridTimer 需要“精确闹钟”权限。\n\n请在接下来的弹窗或设置中允许。',
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
              label: const Text('授予精确闹钟权限'),
            ),
    );
  }

  Widget _buildBatteryStep() {
    return _buildStepContainer(
      title: '电池优化',
      description:
          '为了防止系统在后台关闭计时器，建议将 GridTimer 设为“不优化电池使用”。\n\n这能确保长时间计时不会被中断。',
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
              label: const Text('打开电池优化设置'),
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
    return _buildStepContainer(
      title: '准备就绪',
      description: '所有设置已完成！\n\n您可以随时在设置页面重新配置这些选项。',
      icon: Icons.check_circle_outline,
      action: const SizedBox.shrink(), // Button is in bottom bar
    );
  }
}

class _GrantedLabel extends StatelessWidget {
  const _GrantedLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: Colors.green),
          SizedBox(width: 8),
          Text(
            '已授权',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
