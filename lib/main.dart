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
      // Initialize all services
      final notification = ref.read(notificationServiceProvider);
      await notification.init();

      final audio = ref.read(audioServiceProvider);
      await audio.init();

      final tts = ref.read(ttsServiceProvider);
      await tts.init();

      final timerService = ref.read(timerServiceProvider);
      await timerService.init();

      // Ensure notification channels (all timers use same sound)
      await notification.ensureAndroidChannels(soundKeys: {'default'});
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
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
      ),
      home: const GridPage(),
    );
  }
}
