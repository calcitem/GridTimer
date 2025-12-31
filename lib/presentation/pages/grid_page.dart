import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_grid_set.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';
import '../../l10n/app_localizations.dart';
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
    
    // Check and show safety disclaimer on first launch
    if (!_disclaimerChecked) {
      _disclaimerChecked = true;
      _checkAndShowDisclaimer();
    }
  }

  Future<void> _checkAndShowDisclaimer() async {
    final settingsAsync = ref.read(appSettingsProvider);
    final settings = settingsAsync.value;
    
    if (settings != null && !settings.safetyDisclaimerAccepted) {
      // Wait for first frame to complete
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        final accepted = await SafetyDisclaimerDialog.show(context);
        if (accepted && mounted) {
          await ref
              .read(appSettingsProvider.notifier)
              .updateSafetyDisclaimerAccepted(true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridState = ref.watch(gridStateProvider);
    final l10nNullable = AppLocalizations.of(context);
    if (l10nNullable == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final l10n = l10nNullable;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
