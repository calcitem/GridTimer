import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app/locale_provider.dart';
import 'app/providers.dart';
import 'l10n/app_localizations.dart';
import 'presentation/pages/grid_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before anything else
  await Hive.initFlutter('GridTimer');

  runApp(const ProviderScope(child: GridTimerApp()));
}

class GridTimerApp extends ConsumerStatefulWidget {
  const GridTimerApp({super.key});

  @override
  ConsumerState<GridTimerApp> createState() => _GridTimerAppState();
}

class _GridTimerAppState extends ConsumerState<GridTimerApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // 首先请求通知权限（Android 13+）
      final notification = ref.read(notificationServiceProvider);
      await notification.init();

      // 主动请求通知权限
      await notification.requestPostNotificationsPermission();

      // 尝试请求精确闹钟权限（Android 14+，用户可能需要手动授予）
      await notification.requestExactAlarmPermission();

      // Initialize all services
      final audio = ref.read(audioServiceProvider);
      await audio.init();

      final tts = ref.read(ttsServiceProvider);
      await tts.init();

      final widget = ref.read(widgetServiceProvider);
      await widget.init();

      final timerService = ref.read(timerServiceProvider);
      await timerService.init();

      // Ensure notification channels (all timers use same sound)
      await notification.ensureAndroidChannels(soundKeys: {'default'});

      // 监听计时器状态变化并更新小部件
      _setupWidgetUpdates();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  /// 设置小部件自动更新
  void _setupWidgetUpdates() {
    ref.listen(gridStateProvider, (previous, next) {
      next.whenData((state) {
        final (_, sessions) = state;
        // 更新小部件
        ref.read(widgetServiceProvider).updateWidget(sessions);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'GridTimer',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,

        // 针对长辈优化的大号对话框主题
        dialogTheme: const DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          titleTextStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          contentTextStyle: TextStyle(fontSize: 20, color: Colors.black87),
          actionsPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),

        // 增大按钮尺寸和文字
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 增大输入框文字
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(fontSize: 18),
          floatingLabelStyle: TextStyle(fontSize: 20),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const GridPage(),
    );
  }
}
