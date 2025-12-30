import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../core/domain/entities/timer_session.dart';
import '../core/domain/enums.dart';

/// Android 桌面小部件服务
/// 负责更新桌面小部件显示的数据
class WidgetService {
  /// 初始化小部件服务
  Future<void> init() async {
    if (!Platform.isAndroid) return;
    
    try {
      // 注册小部件更新回调
      await HomeWidget.registerInteractivityCallback(_onWidgetInteraction);
      debugPrint('WidgetService: 已初始化');
    } catch (e) {
      debugPrint('WidgetService 初始化失败: $e');
    }
  }

  /// 更新小部件数据
  /// 
  /// [sessions] 当前所有计时器会话
  Future<void> updateWidget(List<TimerSession> sessions) async {
    if (!Platform.isAndroid) return;
    
    try {
      // 统计活跃和响铃的计时器
      final activeSessions = sessions.where(
        (s) => s.status == TimerStatus.running || s.status == TimerStatus.paused
      ).toList();
      
      final ringingSessions = sessions.where(
        (s) => s.status == TimerStatus.ringing
      ).toList();
      
      // 找出最近即将结束的计时器
      TimerSession? nearestTimer;
      int? nearestRemaining;
      
      if (activeSessions.isNotEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final session in activeSessions) {
          if (session.status == TimerStatus.running && session.endAtEpochMs != null) {
            final remaining = session.endAtEpochMs! - now;
            if (remaining > 0 && (nearestRemaining == null || remaining < nearestRemaining)) {
              nearestRemaining = remaining;
              nearestTimer = session;
            }
          }
        }
      }
      
      // 保存数据到 SharedPreferences
      await HomeWidget.saveWidgetData<int>('active_timers_count', activeSessions.length);
      await HomeWidget.saveWidgetData<int>('ringing_timers_count', ringingSessions.length);
      
      if (nearestTimer != null && nearestRemaining != null) {
        // 格式化剩余时间
        final remaining = _formatDuration(nearestRemaining);
        await HomeWidget.saveWidgetData<String>('nearest_timer_name', 'Timer ${nearestTimer.slotIndex + 1}');
        await HomeWidget.saveWidgetData<String>('nearest_timer_remaining', remaining);
      } else {
        await HomeWidget.saveWidgetData<String?>('nearest_timer_name', null);
        await HomeWidget.saveWidgetData<String?>('nearest_timer_remaining', null);
      }
      
      // 触发小部件更新
      await HomeWidget.updateWidget(
        name: 'GridTimerWidgetProvider',
        androidName: 'GridTimerWidgetProvider',
      );
      
      debugPrint('WidgetService: 已更新小部件 (活跃: ${activeSessions.length}, 响铃: ${ringingSessions.length})');
    } catch (e) {
      debugPrint('WidgetService 更新失败: $e');
    }
  }

  /// 格式化时长为可读字符串
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

  /// 处理来自小部件的交互
  static Future<void> _onWidgetInteraction(Uri? uri) async {
    if (uri == null) return;
    
    debugPrint('WidgetService: 收到小部件交互: $uri');
    // 这里可以处理从小部件点击传递的数据
    // 例如：打开特定的计时器、暂停/继续等操作
  }
}

