import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../core/domain/entities/timer_session.dart';
import '../core/domain/enums.dart';

/// Android home screen widget service
/// Responsible for updating widget display data
/// Note: home_widget supports both Android and iOS, but implementation is Android-only for now
class WidgetService {
  /// Initialize widget service
  Future<void> init() async {
    if (!Platform.isAndroid) return;

    try {
      // Register widget interaction callback
      await HomeWidget.registerInteractivityCallback(_onWidgetInteraction);
      debugPrint('WidgetService: Initialized');
    } catch (e) {
      debugPrint('WidgetService initialization failed: $e');
    }
  }

  /// Update widget data
  ///
  /// [sessions] Current timer sessions
  Future<void> updateWidget(List<TimerSession> sessions) async {
    if (!Platform.isAndroid) return;

    try {
      // Count active and ringing timers
      final activeSessions = sessions
          .where(
            (s) =>
                s.status == TimerStatus.running ||
                s.status == TimerStatus.paused,
          )
          .toList();

      final ringingSessions = sessions
          .where((s) => s.status == TimerStatus.ringing)
          .toList();

      // Find nearest timer that will finish soon
      TimerSession? nearestTimer;
      int? nearestRemaining;

      if (activeSessions.isNotEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final session in activeSessions) {
          if (session.status == TimerStatus.running &&
              session.endAtEpochMs != null) {
            final remaining = session.endAtEpochMs! - now;
            if (remaining > 0 &&
                (nearestRemaining == null || remaining < nearestRemaining)) {
              nearestRemaining = remaining;
              nearestTimer = session;
            }
          }
        }
      }

      // Save data to SharedPreferences
      await HomeWidget.saveWidgetData<int>(
        'active_timers_count',
        activeSessions.length,
      );
      await HomeWidget.saveWidgetData<int>(
        'ringing_timers_count',
        ringingSessions.length,
      );

      if (nearestTimer != null && nearestRemaining != null) {
        // Format remaining time
        final remaining = _formatDuration(nearestRemaining);
        await HomeWidget.saveWidgetData<String>(
          'nearest_timer_name',
          'Timer ${nearestTimer.slotIndex + 1}',
        );
        await HomeWidget.saveWidgetData<String>(
          'nearest_timer_remaining',
          remaining,
        );
      } else {
        await HomeWidget.saveWidgetData<String?>('nearest_timer_name', null);
        await HomeWidget.saveWidgetData<String?>(
          'nearest_timer_remaining',
          null,
        );
      }

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: 'GridTimerWidgetProvider',
        androidName: 'GridTimerWidgetProvider',
      );

      // Only log in debug mode to avoid log spam
      if (kDebugMode) {
        debugPrint(
          'WidgetService: Updated widget (active: ${activeSessions.length}, ringing: ${ringingSessions.length})',
        );
      }
    } catch (e) {
      debugPrint('WidgetService update failed: $e');
    }
  }

  /// Format duration to readable string
  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Handle widget interaction
  static Future<void> _onWidgetInteraction(Uri? uri) async {
    if (uri == null) return;

    debugPrint('WidgetService: Received widget interaction: $uri');
    // Handle data passed from widget click
    // For example: open specific timer, pause/resume operations, etc.
  }
}
