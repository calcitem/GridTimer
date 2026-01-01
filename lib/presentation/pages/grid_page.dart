import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/locale_provider.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_grid_set.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';
import '../dialogs/privacy_policy_dialog.dart';
import '../dialogs/safety_disclaimer_dialog.dart';
import '../widgets/timer_grid_cell.dart';
import 'settings_page.dart';

/// Main grid page showing 3x3 timer grid.
class GridPage extends ConsumerStatefulWidget {
  const GridPage({super.key});

  @override
  ConsumerState<GridPage> createState() => _GridPageState();
}

class _GridPageState extends ConsumerState<GridPage> {
  bool _disclaimerChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check and show disclaimers on first launch only
    if (!_disclaimerChecked) {
      _disclaimerChecked = true;
      _checkAndShowDisclaimers();
    }
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

  /// Check if disclaimers need to be shown and display them if necessary.
  ///
  /// For Chinese locale users:
  /// 1. Show privacy policy dialog first (if not yet accepted)
  /// 2. Then show safety disclaimer (if not yet accepted)
  ///
  /// For non-Chinese users:
  /// - Only show safety disclaimer (if not yet accepted)
  Future<void> _checkAndShowDisclaimers() async {
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
      debugPrint('GridPage: Settings not loaded, skipping disclaimer check');
      return;
    }

    // Wait for first frame to complete to avoid showing during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Check if Chinese locale and privacy policy not yet accepted
      final isChinese = _isChineseLocale(context);
      debugPrint('GridPage: Is Chinese locale = $isChinese');
      debugPrint(
        'GridPage: Privacy policy accepted = ${settings.privacyPolicyAccepted}',
      );

      if (isChinese && !settings.privacyPolicyAccepted) {
        debugPrint('GridPage: Showing privacy policy dialog');

        final accepted = await PrivacyPolicyDialog.show(context);

        debugPrint(
          'GridPage: User ${accepted ? "accepted" : "dismissed"} privacy policy',
        );

        if (accepted && mounted) {
          await ref
              .read(appSettingsProvider.notifier)
              .updatePrivacyPolicyAccepted(true);
          debugPrint('GridPage: Saved privacy policy acceptance to storage');
        }
      }

      if (!mounted) return;

      // Now check safety disclaimer
      debugPrint(
        'GridPage: Safety disclaimer accepted = ${settings.safetyDisclaimerAccepted}',
      );

      if (!settings.safetyDisclaimerAccepted) {
        debugPrint('GridPage: Showing safety disclaimer dialog');

        final accepted = await SafetyDisclaimerDialog.show(context);

        debugPrint(
          'GridPage: User ${accepted ? "accepted" : "dismissed"} disclaimer',
        );

        if (accepted && mounted) {
          await ref
              .read(appSettingsProvider.notifier)
              .updateSafetyDisclaimerAccepted(true);
          debugPrint('GridPage: Saved disclaimer acceptance to storage');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gridState = ref.watch(gridStateProvider);
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = l10nNullable;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () {
              // Navigate to settings page
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: gridState.when(
        data: (state) {
          final (grid, sessions) = state;
          return _buildGrid(context, ref, grid, sessions);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text(l10n.errorText(error.toString()))),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    TimerGridSet grid,
    List<TimerSession> sessions,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          for (int row = 0; row < 3; row++)
            Expanded(
              child: Row(
                children: [
                  for (int col = 0; col < 3; col++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: _buildCell(row, col, grid, sessions),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(
    int row,
    int col,
    TimerGridSet grid,
    List<TimerSession> sessions,
  ) {
    final index = row * 3 + col;
    final session = sessions.firstWhere(
      (s) => s.slotIndex == index,
      orElse: () => TimerSession(
        timerId: 'unknown:$index',
        modeId: 'unknown',
        slotIndex: index,
        status: TimerStatus.idle,
      ),
    );
    final config = grid.slots[index];
    return TimerGridCell(session: session, config: config, slotIndex: index);
  }
}
