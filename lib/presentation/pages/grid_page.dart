import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/locale_provider.dart';
import '../../app/providers.dart';
import '../../core/config/environment_config.dart';
import '../../core/config/supported_locales.dart';
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

  /// Check if disclaimers need to be shown and display them if necessary.
  ///
  /// NOTE: For new users, privacy policy is shown in OnboardingPage before
  /// the wizard starts. This check here serves as a fallback for:
  /// - Users who completed onboarding before privacy policy was added
  /// - Direct navigation to GridPage (error recovery scenarios)
  ///
  /// For locales that require privacy policy (configured in SupportedLocales):
  /// 1. Show privacy policy dialog first (if not yet accepted)
  /// 2. Then show safety disclaimer (if not yet accepted)
  ///
  /// For other locales:
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

    // Wait for first frame to complete to avoid showing during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Re-read settings to get the latest state
      // This prevents showing duplicate dialogs if this callback is registered multiple times
      final settings = ref.read(appSettingsProvider).value;

      if (settings == null) {
        debugPrint('GridPage: Settings not loaded, skipping disclaimer check');
        return;
      }

      // Check if locale requires privacy policy and not yet accepted
      final userLocale = ref.read(localeProvider);
      final systemLocale = Localizations.localeOf(context);
      final requiresPrivacyPolicy = SupportedLocales.requiresPrivacyPolicy(
        userLocale,
        systemLocale,
      );
      debugPrint('GridPage: Requires privacy policy = $requiresPrivacyPolicy');
      debugPrint(
        'GridPage: Privacy policy accepted = ${settings.privacyPolicyAccepted}',
      );

      if (requiresPrivacyPolicy && !settings.privacyPolicyAccepted) {
        debugPrint('GridPage: Showing privacy policy dialog');

        final privacyPolicyUrl = SupportedLocales.getPrivacyPolicyUrl(
          userLocale,
          systemLocale,
        );
        final accepted = await PrivacyPolicyDialog.show(
          context,
          privacyPolicyUrl: privacyPolicyUrl,
        );

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

      // Re-read settings again to get the latest state after privacy policy update
      final latestSettings = ref.read(appSettingsProvider).value;
      if (latestSettings == null) return;

      // Now check safety disclaimer
      debugPrint(
        'GridPage: Safety disclaimer accepted = ${latestSettings.safetyDisclaimerAccepted}',
      );

      if (!latestSettings.safetyDisclaimerAccepted) {
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
    final theme = ref.watch(themeProvider);
    final tokens = theme.tokens;

    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = l10nNullable;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            if (EnvironmentConfig.test) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            }
          },
          child: Text(
            l10n.appTitle,
            style: TextStyle(color: tokens.accent, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: tokens.textPrimary, size: 32),
            color: tokens.surface,
            tooltip: l10n.settings,
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: tokens.textPrimary),
                    const SizedBox(width: 12),
                    Text(
                      l10n.settings,
                      style: TextStyle(color: tokens.textPrimary, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: gridState.when(
        data: (state) {
          final (grid, sessions) = state;
          return _buildGrid(context, ref, grid, sessions);
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: tokens.accent)),
        error: (error, stack) => Center(
          child: Text(
            l10n.errorText(error.toString()),
            style: TextStyle(color: tokens.danger),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    TimerGridSet grid,
    List<TimerSession> sessions,
  ) {
    // Determine number of columns based on text scale factor (Accessibility)
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    int crossAxisCount = 3;
    if (textScale > 2.0) {
      crossAxisCount = 1;
    } else if (textScale > 1.3) {
      crossAxisCount = 2;
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate number of rows based on crossAxisCount
          final rowCount = (9 / crossAxisCount).ceil();

          // Detect landscape orientation
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          // In landscape, center the grid and limit its width to maintain better cell proportions
          final double maxGridWidth = isLandscape
              ? constraints.maxHeight *
                    1.5 // Limit width to 1.5x height
              : constraints.maxWidth;

          final gridContent = Column(
            children: List.generate(rowCount, (rowIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(crossAxisCount, (colIndex) {
                    final index = rowIndex * crossAxisCount + colIndex;
                    if (index >= 9) {
                      // Empty placeholder for incomplete last row
                      return const Expanded(child: SizedBox.shrink());
                    }
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: colIndex < crossAxisCount - 1 ? 12 : 0,
                          bottom: rowIndex < rowCount - 1 ? 12 : 0,
                        ),
                        child: _buildCell(index, grid, sessions),
                      ),
                    );
                  }),
                ),
              );
            }),
          );

          // If landscape and grid would be too wide, center it
          if (isLandscape && maxGridWidth < constraints.maxWidth) {
            return Center(
              child: SizedBox(width: maxGridWidth, child: gridContent),
            );
          }

          return gridContent;
        },
      ),
    );
  }

  Widget _buildCell(int index, TimerGridSet grid, List<TimerSession> sessions) {
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
