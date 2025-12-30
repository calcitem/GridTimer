import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';

/// 九宫格时长配置页面
class GridDurationsSettingsPage extends ConsumerStatefulWidget {
  const GridDurationsSettingsPage({super.key});

  @override
  ConsumerState<GridDurationsSettingsPage> createState() =>
      _GridDurationsSettingsPageState();
}

class _GridDurationsSettingsPageState
    extends ConsumerState<GridDurationsSettingsPage> {
  // 默认时长配置（单位：秒）
  static const List<int> _defaultDurations = [
    10,
    120,
    180,
    300,
    480,
    600,
    900,
    1200,
    2700
  ];

  late List<TextEditingController> _controllers;
  late List<int> _durations;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final settings = ref.read(appSettingsProvider).value;
    _durations = List<int>.from(
        settings?.gridDurationsInSeconds ?? _defaultDurations);

    _controllers = List.generate(
      9,
      (i) => TextEditingController(text: _durations[i].toString()),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 保存配置
  Future<void> _saveDurations() async {
    final newDurations = <int>[];
    bool hasError = false;

    for (int i = 0; i < 9; i++) {
      final text = _controllers[i].text.trim();
      final value = int.tryParse(text);

      if (value == null || value <= 0) {
        hasError = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('宫格 ${i + 1} 的时长必须是大于 0 的整数'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      }

      newDurations.add(value);
    }

    if (!hasError) {
      // 先保存配置
      await ref.read(appSettingsProvider.notifier).updateSettings(
            (s) => s.copyWith(gridDurationsInSeconds: newDurations),
          );

      // 尝试立即更新 default grid 的时长配置
      try {
        final timerService = ref.read(timerServiceProvider);
        if (timerService.hasActiveTimers()) {
          // 有活动计时器，不能立即更新
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('有活动的计时器正在运行，配置将在下次启动应用时生效'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          // 没有活动计时器，立即更新
          await timerService.updateDefaultGridDurations();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('保存成功，九宫格时长已更新'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        // 出错时显示警告，但不阻止保存
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('配置已保存，但应用更新时出错：$e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// 恢复默认值
  Future<void> _resetToDefault() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetToDefault),
        content: Text(l10n.gridDurationsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionStart),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _durations = List<int>.from(_defaultDurations);
        for (int i = 0; i < 9; i++) {
          _controllers[i].text = _durations[i].toString();
        }
      });
    }
  }

  /// 格式化显示时长
  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '$minutes min';
      } else {
        return '$minutes min $remainingSeconds s';
      }
    } else {
      final hours = seconds ~/ 3600;
      final remainingMinutes = (seconds % 3600) ~/ 60;
      if (remainingMinutes == 0) {
        return '$hours h';
      } else {
        return '$hours h $remainingMinutes min';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gridDurationsSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: l10n.resetToDefault,
            onPressed: _resetToDefault,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 9,
              itemBuilder: (context, index) {
                return _buildDurationInput(index, l10n);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDurations,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  l10n.save,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInput(int index, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 宫格标签
            SizedBox(
              width: 80,
              child: Text(
                l10n.gridSlot(index + 1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 输入框
            Expanded(
              child: TextField(
                controller: _controllers[index],
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: l10n.seconds,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixText: l10n.seconds,
                ),
                onChanged: (value) {
                  // 实时预览
                  final seconds = int.tryParse(value);
                  if (seconds != null && seconds > 0) {
                    setState(() {
                      _durations[index] = seconds;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            // 显示格式化的时长
            SizedBox(
              width: 100,
              child: Text(
                _formatDuration(_durations[index]),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

