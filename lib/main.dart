import 'dart:async';
import 'dart:io';

import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
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

  // IMPORTANT: Check for single instance BEFORE initializing Hive
  // to avoid file lock conflicts
  if (!kIsWeb && _isDesktopPlatform()) {
    debugPrint('Grid Timer: Checking single instance...');

    // Check if this is the first instance (with timeout to avoid hanging)
    // Note: In debug mode, flutter_single_instance always returns true,
    // so we also check for Hive lock file as a backup mechanism
    bool isFirstInstance = true;
    try {
      isFirstInstance = await FlutterSingleInstance().isFirstInstance().timeout(
        const Duration(seconds: 3),
      );
      debugPrint('Grid Timer: isFirstInstance = $isFirstInstance');
    } catch (e) {
      // Timeout or error - assume first instance to avoid blocking
      debugPrint('Grid Timer: isFirstInstance check failed: $e');
      isFirstInstance = true;
    }

    // Additional check: try to acquire Hive lock file
    // This works even in debug mode where flutter_single_instance always returns true
    if (isFirstInstance) {
      final canAcquireLock = await _tryAcquireHiveLock();
      if (!canAcquireLock) {
        debugPrint('Grid Timer: Hive lock file is held by another instance.');
        isFirstInstance = false;
      }
    }

    if (!isFirstInstance) {
      // Another instance is already running
      debugPrint('Grid Timer: Another instance is already running.');

      // Try to focus the existing instance (with timeout to avoid hanging)
      try {
        final focusError = await FlutterSingleInstance().focus().timeout(
          const Duration(seconds: 2),
        );
        if (focusError != null) {
          debugPrint(
            'Grid Timer: Failed to focus existing instance: $focusError',
          );
        } else {
          debugPrint('Grid Timer: Successfully focused existing instance.');
        }
      } catch (e) {
        debugPrint('Grid Timer: Focus timeout or error: $e');
      }

      // Show brief warning and exit immediately
      _showSingleInstanceWarningAndExit();
      return; // Prevent further execution
    }

    debugPrint('Grid Timer: This is the first instance.');
  }

  // Explicitly show status bar and navigation bar
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  debugPrint('Environment [catcher]: ${EnvironmentConfig.catcher}');
  debugPrint('Environment [dev_mode]: ${EnvironmentConfig.devMode}');
  debugPrint('Environment [test]: ${EnvironmentConfig.test}');

  // Initialize Hive (only reached by the first instance)
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

/// Check if the current platform is desktop (Windows/Linux/macOS).
bool _isDesktopPlatform() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

/// Global lock file handle to keep the lock alive during app lifecycle.
RandomAccessFile? _hiveLockFile;

/// Try to acquire Hive lock file to detect if another instance is running.
///
/// This is a backup mechanism for debug mode where flutter_single_instance
/// always returns true.
Future<bool> _tryAcquireHiveLock() async {
  try {
    final appDir = await getApplicationSupportDirectory();
    final lockFilePath = '${appDir.path}/Grid Timer/grid_timer.lock';

    // Create directory if it doesn't exist
    final lockFile = File(lockFilePath);
    if (!await lockFile.parent.exists()) {
      await lockFile.parent.create(recursive: true);
    }

    // Create lock file if it doesn't exist
    if (!await lockFile.exists()) {
      await lockFile.create();
    }

    // Try to open and lock the file exclusively
    _hiveLockFile = await lockFile.open(mode: FileMode.write);

    try {
      // Try to acquire exclusive lock (non-blocking)
      await _hiveLockFile!.lock(FileLock.exclusive);

      // Write PID to lock file
      await _hiveLockFile!.writeString(
        '${Platform.resolvedExecutable}\n$pid\n',
      );
      await _hiveLockFile!.flush();

      debugPrint('Grid Timer: Acquired Hive lock file successfully.');
      return true;
    } on FileSystemException catch (e) {
      // Lock failed - another instance has the lock
      debugPrint('Grid Timer: Failed to acquire lock: $e');
      await _hiveLockFile?.close();
      _hiveLockFile = null;
      return false;
    }
  } catch (e) {
    // Any other error - assume we can proceed
    debugPrint('Grid Timer: Lock check error (proceeding anyway): $e');
    return true;
  }
}

/// Get AppLocalizations instance based on system locale.
///
/// This helper is used when we need localized strings before the app is fully
/// initialized (e.g., in main() before runApp).
AppLocalizations _getLocalizationsForSystemLocale() {
  final systemLocale = PlatformDispatcher.instance.locale;

  try {
    return lookupAppLocalizations(systemLocale);
  } catch (_) {
    // Fallback to English for unsupported languages
    return lookupAppLocalizations(const Locale('en'));
  }
}

/// Show a brief warning and exit immediately (non-blocking).
/// This is used when focus() fails to avoid hanging on Hive initialization.
void _showSingleInstanceWarningAndExit() {
  // Get localized strings for system locale
  final l10n = _getLocalizationsForSystemLocale();

  // Run a minimal app to show the warning without blocking
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: AlertDialog(
            title: Text(l10n.appTitle),
            content: Text(l10n.singleInstanceWarningMessage),
            actions: [
              TextButton(
                onPressed: () => exit(0),
                child: Text(l10n.actionCancel),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Auto-exit after 3 seconds in case user doesn't click
  Future<void>.delayed(const Duration(seconds: 3), () => exit(0));
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
      // Initialize notification service (permission prompts are triggered explicitly
      // from onboarding or settings).
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
