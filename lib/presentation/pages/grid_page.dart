import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/domain/entities/timer_grid_set.dart';
import '../../core/domain/entities/timer_session.dart';
import '../../core/domain/enums.dart';
import '../widgets/timer_grid_cell.dart';

/// Main grid page showing 3x3 timer grid.
class GridPage extends ConsumerWidget {
  const GridPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridState = ref.watch(gridStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GridTimer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
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
        error: (error, stack) => Center(child: Text('Error: $error')),
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
    return TimerGridCell(
      session: session,
      config: config,
      slotIndex: index,
    );
  }
}



