import 'dart:async';
import 'dart:io';
import 'dart:ui';

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
  await Hive.initFlutter('GridTimer');

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

    return MaterialApp(
      /// Add navigator key from Catcher.
      /// It will be used to navigate user to report page or to show dialog.
      navigatorKey: (EnvironmentConfig.catcher && !kIsWeb && !Platform.isIOS)
          ? Catcher2.navigatorKey
          : null,
      title: 'GridTimer',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,

        // High contrast color scheme: dark mode based, using bright yellow as primary color
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD600), // Bright yellow, high visibility
          onPrimary: Colors.black, // Black text on yellow, highest contrast
          secondary: Color(0xFF00B0FF), // Bright cyan, for secondary actions
          onSecondary: Colors.black,
          surface: Color(0xFF1E1E1E), // Dark gray card background
          onSurface: Colors.white, // White text
          error: Color(0xFFFF5252), // Bright red
          onError: Colors.black,
        ),

        // AppBar theme: black background with yellow text
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
          iconTheme: IconThemeData(color: Color(0xFFFFD600), size: 28),
        ),

        // Card theme: add border to distinguish from background
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
        ),

        // Icon theme: default large white icons
        iconTheme: const IconThemeData(color: Colors.white, size: 28),

        // Switch theme: high contrast
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black; // Black thumb when on (on yellow track)
            }
            return Colors.white; // White thumb when off
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFFFD600); // Bright yellow track when on
            }
            return Colors.grey.shade800; // Dark gray track when off
          }),
          trackOutlineColor: WidgetStateProperty.all(
            Colors.white,
          ), // White border enhances visibility
        ),

        // Large dialog theme optimized for elderly users
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(
              color: Color(0xFFFFD600),
              width: 2,
            ), // Prominent border
          ),
          titleTextStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          contentTextStyle: TextStyle(fontSize: 20, color: Color(0xFFEEEEEE)),
          actionsPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),

        // Larger button size and text
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600), // Yellow background
            foregroundColor: Colors.black, // Black text
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
            foregroundColor: const Color(0xFFFFD600), // Yellow text
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // List tile theme: large text, high comfort
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ), // Increased spacing
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          subtitleTextStyle: TextStyle(
            fontSize: 18,
            color: Colors.white70,
            height: 1.4, // Increased line height, improved readability
          ),
          iconColor: Colors.white,
          tileColor: Colors.transparent,
        ),

        // Global text theme adjustments
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 20, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 18, color: Colors.white),
          bodySmall: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ), // Increased small font size
          titleMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleSmall: TextStyle(fontSize: 18, color: Colors.white70),
        ),

        // Divider theme
        dividerTheme: const DividerThemeData(
          color: Colors.white24,
          thickness: 1,
        ),

        // Larger input field text, enhanced contrast
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          labelStyle: const TextStyle(fontSize: 18, color: Colors.white70),
          floatingLabelStyle: const TextStyle(
            fontSize: 20,
            color: Color(0xFFFFD600),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
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
