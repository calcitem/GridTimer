import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/providers.dart';
import 'presentation/pages/grid_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      
      // Ensure notification channels for all sound keys
      await notification.ensureAndroidChannels(soundKeys: {
        'bell01',
        'bell02',
        'beep_soft',
        'chime',
        'ding',
        'gentle',
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridTimer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const GridPage(),
    );
  }
}

