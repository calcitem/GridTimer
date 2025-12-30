import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
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
      body: SafeArea(
        child: gridState.when(
          data: (state) {
            final (grid, sessions) = state;
            return _buildGrid(context, ref, sessions);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to settings
        },
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref, List<TimerSession> sessions) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      padding: const EdgeInsets.all(4),
      itemCount: 9,
      itemBuilder: (context, index) {
        final session = sessions.firstWhere(
          (s) => s.slotIndex == index,
          orElse: () => TimerSession(
            timerId: 'unknown:$index',
            modeId: 'unknown',
            slotIndex: index,
            status: TimerStatus.idle,
          ),
        );
        return TimerGridCell(
          session: session,
          slotIndex: index,
        );
      },
    );
  }
}

