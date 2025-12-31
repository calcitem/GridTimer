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
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,

        // 高对比度配色方案：基于暗黑模式，使用鲜明的黄色作为主色调
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD600), // 鲜亮的黄色，高可见度
          onPrimary: Colors.black, // 黄底黑字，最高对比度
          secondary: Color(0xFF00B0FF), // 鲜亮的浅蓝色，区分次要操作
          onSecondary: Colors.black,
          surface: Color(0xFF1E1E1E), // 深灰色卡片背景
          onSurface: Colors.white, // 白字
          error: Color(0xFFFF5252), // 鲜亮红
          onError: Colors.black,
        ),

        // AppBar 主题：黑底黄字
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Color(0xFFFFD600),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD600),
          ),
          iconTheme: IconThemeData(
            color: Color(0xFFFFD600),
            size: 28,
          ),
        ),

        // 卡片主题：增加边框以区分背景
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
        ),

        // 图标主题：默认大尺寸白色
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 28,
        ),

        // 开关主题：高对比度
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black; // 开启时滑块为黑色 (在黄色轨道上)
            }
            return Colors.white; // 关闭时滑块为白色
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFFFD600); // 开启时轨道为亮黄色
            }
            return Colors.grey.shade800; // 关闭时轨道为深灰
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.white), // 白色边框增强可见性
        ),

        // 针对长辈优化的大号对话框主题
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFFFD600), width: 2), // 醒目的边框
          ),
          titleTextStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          contentTextStyle: TextStyle(fontSize: 20, color: Color(0xFFEEEEEE)),
          actionsPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),

        // 增大按钮尺寸和文字
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600), // 黄色背景
            foregroundColor: Colors.black, // 黑色文字
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
            foregroundColor: const Color(0xFFFFD600), // 黄色文字
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 列表项主题：大字号，高舒适度
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // 增加间距
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          subtitleTextStyle: TextStyle(
            fontSize: 18,
            color: Colors.white70,
            height: 1.4, // 增加行高，提升可读性
          ),
          iconColor: Colors.white,
          tileColor: Colors.transparent,
        ),

        // 全局文本主题调整
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 20, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 18, color: Colors.white),
          bodySmall: TextStyle(fontSize: 16, color: Colors.white70), // 增加小字号
          titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          titleSmall: TextStyle(fontSize: 18, color: Colors.white70),
        ),

        // 分割线主题
        dividerTheme: const DividerThemeData(
          color: Colors.white24,
          thickness: 1,
        ),

        // 增大输入框文字，增强对比度
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          labelStyle: const TextStyle(fontSize: 18, color: Colors.white70),
          floatingLabelStyle: const TextStyle(fontSize: 20, color: Color(0xFFFFD600)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD600), width: 2),
          ),
        ),
      ),
      home: const GridPage(),
    );
  }
}
