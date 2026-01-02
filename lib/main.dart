import 'dart:async';
import 'dart:io';

import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app/locale_provider.dart';
import 'app/providers.dart';
import 'core/config/constants.dart';
import 'core/config/environment_config.dart';
import 'l10n/app_localizations.dart';
import 'presentation/pages/grid_page.dart';
import 'presentation/pages/onboarding_page.dart';

part 'core/services/catcher_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Environment [catcher]: ${EnvironmentConfig.catcher}');
  debugPrint('Environment [dev_mode]: ${EnvironmentConfig.devMode}');
  debugPrint('Environment [test]: ${EnvironmentConfig.test}');

  // Initialize Hive before anything else
  await Hive.initFlutter('Grid Timer');

  if (EnvironmentConfig.catcher && !kIsWeb && !Platform.isIOS) {
    catcher = Catcher2(
      rootWidget: const ProviderScope(child: GridTimerApp()),
      ensureInitialized: true,
    );

    await _initCatcher(catcher);

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (EnvironmentConfig.catcher == true) {
        Catcher2.reportCheckedError(error, stack);
      }
      return true;
    };
  } else {
    runApp(const ProviderScope(child: GridTimerApp()));
  }
}

class GridTimerApp extends ConsumerStatefulWidget {
  const GridTimerApp({super.key});

  @override
  ConsumerState<GridTimerApp> createState() => _GridTimerAppState();
}

class _GridTimerAppState extends ConsumerState<GridTimerApp> {
  ProviderSubscription<AsyncValue<dynamic>>? _gridStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _gridStateSubscription?.close();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // First request notification permission (Android 13+)
      final notification = ref.read(notificationServiceProvider);
      await notification.init();

      // Initialize all services
      final audio = ref.read(audioServiceProvider);
      await audio.init();

      final tts = ref.read(ttsServiceProvider);
      await tts.init();

      final widget = ref.read(widgetServiceProvider);
      await widget.init();

      // Timer service initialization is now handled by timerServiceInitProvider
      // which is triggered when gridStateProvider is watched.
      // No need to call timerService.init() here.

      // Ensure notification channels (all timers use same sound)
      await notification.ensureAndroidChannels(soundKeys: {'default'});

      // Listen for timer state changes and update widgets
      _setupWidgetUpdates();
    } catch (e, st) {
      debugPrint('Initialization error: $e');
      if (EnvironmentConfig.catcher && !kIsWeb && !Platform.isIOS) {
        Catcher2.reportCheckedError(e, st);
      }
    }
  }

  /// Set up automatic widget updates
  ///
  /// Listen to timer state changes and update home screen widgets accordingly.
  /// Only updates when there are actual changes to avoid unnecessary updates.
  void _setupWidgetUpdates() {
    if (_gridStateSubscription != null) {
      return;
    }

    _gridStateSubscription = ref.listenManual(gridStateProvider, (
      previous,
      next,
    ) {
      next.whenData((state) {
        final (_, sessions) = state;

        // Only update widget if there are changes from previous state
        if (previous?.value != null) {
          final (_, prevSessions) = previous!.value!;

          // Check if sessions have actually changed
          bool hasChanged = false;
          if (sessions.length != prevSessions.length) {
            hasChanged = true;
          } else {
            for (int i = 0; i < sessions.length; i++) {
              if (sessions[i].status != prevSessions[i].status ||
                  sessions[i].endAtEpochMs != prevSessions[i].endAtEpochMs) {
                hasChanged = true;
                break;
              }
            }
          }

          if (!hasChanged) {
            return; // Skip update if nothing changed
          }
        }

        // Update widgets when state changes
        ref.read(widgetServiceProvider).updateWidget(sessions);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final appTheme = ref.watch(themeProvider);

    return MaterialApp(
      /// Add navigator key from Catcher.
      /// It will be used to navigate user to report page or to show dialog.
      navigatorKey: EnvironmentConfig.catcher ? Catcher2.navigatorKey : null,
      title: 'Grid Timer',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: appTheme.themeData,
      home: settingsAsync.when(
        data: (settings) {
          if (settings.onboardingCompleted) {
            return const GridPage();
          } else {
            return const OnboardingPage();
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => const GridPage(),
      ),
    );
  }
}
