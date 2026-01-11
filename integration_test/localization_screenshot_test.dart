/*
 * localization_screenshot_test.dart
 *
 * This integration test captures screenshots for a SINGLE specified locale,
 * passed via the TEST_LOCALE environment variable (e.g., "en").
 *
 * It includes screenshots of:
 * 1. Home screen (GridPage with 3x3 timer grid)
 * 2. Settings screen (SettingsPage with all settings options)
 *
 * All screenshots are saved to /storage/emulated/0/Pictures/GridTimer/
 * with timestamps in the format YYYY-MM-DD_HH-MM-SS.
 */

import 'dart:io' show Platform, Directory, File;
import 'dart:typed_data' show Uint8List, ByteData;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiMode, SystemUiOverlay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'package:grid_timer/app/providers.dart';
import 'package:grid_timer/core/domain/entities/app_settings.dart';
import 'package:grid_timer/core/domain/entities/idle_grid_click_behavior.dart';
import 'package:grid_timer/l10n/app_localizations.dart';
import 'package:grid_timer/presentation/pages/grid_page.dart';
import 'package:grid_timer/presentation/pages/settings_page.dart';
import 'package:grid_timer/presentation/widgets/timer_grid_cell.dart';

/// Pre-configured settings for screenshot tests.
/// This ensures dialogs don't appear during screenshots.
const AppSettings _testSettings = AppSettings(
  activeModeId: 'default',
  safetyDisclaimerAccepted: true,
  privacyPolicyAccepted: true,
  onboardingCompleted: true,
  idleGridClickBehavior:
      IdleGridClickBehavior.directStart, // Click starts timer directly
);

/// Test AppSettingsNotifier that returns pre-configured settings.
/// This prevents dialogs from appearing during screenshot capture.
class _TestAppSettingsNotifier extends AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    // Return pre-configured test settings directly
    // This skips the disclaimer/privacy policy dialogs
    return _testSettings;
  }
}

// List to track created screenshots within a single run
final List<String> createdScreenshots = <String>[];

// Define the target screenshot directory - centralized for consistency
const String targetScreenshotDir = '/storage/emulated/0/Pictures/GridTimer';

// Global key for RepaintBoundary used in screenshot capture
final GlobalKey _repaintBoundaryKey = GlobalKey();

// Define the pages to capture screenshots for
enum ScreenshotPage { home, homeWithDialog, settings }

// Map the enum values to string identifiers for filenames
extension ScreenshotPageExtension on ScreenshotPage {
  String get fileNamePart {
    switch (this) {
      case ScreenshotPage.home:
        return 'home_screen';
      case ScreenshotPage.homeWithDialog:
        return 'home_screen_dialog';
      case ScreenshotPage.settings:
        return 'settings_screen';
    }
  }
}

// Helper function to parse locale string (e.g., "en", "zh_Hant", "pt_BR")
// into Locale object
Locale? parseLocale(String? localeString) {
  if (localeString == null || localeString.isEmpty) {
    return null;
  }

  // Handle locales with underscores (e.g., "zh_Hant", "pt_BR")
  if (localeString.contains('_')) {
    final List<String> parts = localeString.split('_');
    if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      final String languageCode = parts[0];
      final String secondPart = parts[1];

      // Script codes are 4 letters (e.g., 'Hant', 'Hans')
      // Country codes are 2 letters (e.g., 'BR', 'US', 'TW')
      if (secondPart.length == 4) {
        return Locale.fromSubtags(
          languageCode: languageCode,
          scriptCode: secondPart,
        );
      } else if (secondPart.length == 2) {
        return Locale.fromSubtags(
          languageCode: languageCode,
          countryCode: secondPart,
        );
      }
    }
    return null;
  }

  // Simple locale code (e.g., "en", "zh", "ja")
  return Locale(localeString);
}

// Convert Locale to filename-safe string
String localeToFilename(Locale locale) {
  if (locale.scriptCode != null) {
    return '${locale.languageCode}_${locale.scriptCode}';
  } else if (locale.countryCode != null) {
    return '${locale.languageCode}_${locale.countryCode}';
  }
  return locale.languageCode;
}

void main() {
  // Get the binding instance required for integration tests
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Read the target locale using String.fromEnvironment
  const String targetLocaleString = String.fromEnvironment('TEST_LOCALE');
  final Locale? targetLocale = parseLocale(targetLocaleString);

  // Add extra debug logging here to see the raw value from fromEnvironment
  debugPrint(
    "Raw value from String.fromEnvironment('TEST_LOCALE'): '$targetLocaleString'",
  );

  setUpAll(() async {
    debugPrint('=== GLOBAL SETUP STARTING ===');
    // Check if the parsed locale is valid
    if (targetLocale == null) {
      throw Exception(
        "ERROR: TEST_LOCALE from --dart-define was not set, empty, or invalid. "
        "Raw value: '$targetLocaleString'. "
        "Expected format e.g., 'en', 'zh', 'zh_Hant', 'pt_BR'.",
      );
    }
    debugPrint(
      'Target Locale for this run: $targetLocaleString ($targetLocale)',
    );

    // Initialize necessary systems
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize timezone data (required for notification scheduling)
    debugPrint('Initializing timezone data...');
    tz_data.initializeTimeZones();
    debugPrint('Timezone initialized.');

    // Initialize Hive
    debugPrint('Initializing Hive...');
    await Hive.initFlutter('Grid Timer Test');
    debugPrint('Hive initialized.');

    // Print device storage paths for debugging
    if (!kIsWeb && Platform.isAndroid) {
      try {
        // Check standard picture directories
        const String sdcardPictures = '/sdcard/Pictures';
        const String storagePictures = '/storage/emulated/0/Pictures';

        debugPrint('Checking if standard picture directories exist:');
        debugPrint(
          '$sdcardPictures exists: ${Directory(sdcardPictures).existsSync()}',
        );
        debugPrint(
          '$storagePictures exists: ${Directory(storagePictures).existsSync()}',
        );
      } catch (e) {
        debugPrint('Error checking storage directories: $e');
      }
    }

    debugPrint('=== GLOBAL SETUP COMPLETE ===');
  });

  tearDownAll(() async {
    debugPrint('=== GLOBAL TEARDOWN STARTING ===');
    await Hive.close();

    // Print the paths of all created screenshots for this specific locale run
    if (createdScreenshots.isNotEmpty) {
      debugPrint('Created screenshots for $targetLocaleString:');
      for (final String path in createdScreenshots) {
        debugPrint('- $path');
      }
    } else {
      debugPrint('No screenshots were created for $targetLocaleString.');
    }

    debugPrint('=== GLOBAL TEARDOWN COMPLETE FOR $targetLocaleString ===');
  });

  // Reset state before the single testWidgets block runs
  setUp(() async {
    debugPrint('=== TEST CASE SETUP - Resetting State ===');
    // Clear screenshot list for this specific test run
    createdScreenshots.clear();
  });

  // Single testWidgets block that processes the targetLocale
  group(
    'GridTimer App Localization Screenshot Test for $targetLocaleString',
    () {
      testWidgets('Take screenshots for locale: $targetLocaleString', (
        WidgetTester tester,
      ) async {
        // Use the locale parsed earlier, re-checking it here
        if (targetLocale == null) {
          fail(
            "Target locale is null, cannot proceed. "
            "Check --dart-define value. Raw: '$targetLocaleString'",
          );
        }

        debugPrint('--- Starting processing for locale: $targetLocale ---');

        // Run the processing logic for the single specified locale.
        await _processLocale(tester, binding, targetLocale);

        debugPrint(
          '--- Finished processing for locale: $targetLocale successfully ---',
        );
      }); // End single testWidgets block
    },
  ); // End group
}

// Helper function to process all steps for a single locale
Future<void> _processLocale(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Locale locale,
) async {
  int screenshotCounter = 0;
  final String localeStr = localeToFilename(locale);

  debugPrint('Processing locale: $locale...');

  // --- Step 1: Home Screen (GridPage) with timer and dialog ---
  debugPrint('Pumping GridPage for Home Screen...');
  screenshotCounter = await _captureHomePage(
    tester,
    binding,
    locale,
    screenshotCounter,
  );
  debugPrint('Finished capturing Home Page.');

  // Force clean up by pumping an empty container
  debugPrint('Cleaning up UI tree...');
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // --- Step 2: Settings Screen ---
  debugPrint('Capturing Settings Page...');
  screenshotCounter = await _captureSettingsPage(
    tester,
    binding,
    locale,
    screenshotCounter,
  );
  debugPrint('Finished capturing Settings Page for $localeStr.');
  await Future<void>.delayed(const Duration(seconds: 1));
}

// Helper function to check if a file exists and get its size
String _fileInfoSync(String path) {
  try {
    final File file = File(path);
    if (file.existsSync()) {
      final int size = file.lengthSync();
      return 'Exists: Yes, Size: $size bytes';
    }
    return 'Exists: No';
  } catch (e) {
    return 'Error checking file: $e';
  }
}

// Helper function to take a screenshot and ensure it's saved
Future<void> _takeAndSaveScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String baseName, // e.g., "en_home_screen"
  int counter, // The sequential number for this screenshot
) async {
  // Format counter with leading zero if needed (e.g., 01, 02, ..., 10)
  final String counterStr = counter.toString().padLeft(2, '0');
  final String nameWithCounter =
      '${baseName}_$counterStr'; // e.g., "en_home_screen_01"

  debugPrint('====== TAKING SCREENSHOT: $nameWithCounter.png ======');

  // Create timestamp in format: YYYY-MM-DD_HH-MM-SS
  final DateTime now = DateTime.now();
  final String timestamp =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
      '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';

  // Include counter and timestamp in filename
  // Format: locale_(number)_pageIdentifier_timestamp.png
  final List<String> parts = baseName.split('_');
  // For simple locales like 'en', parts = ['en', 'home', 'screen']
  // For complex locales like 'zh_Hant', parts = ['zh', 'Hant', 'home', 'screen']
  // For country code locales like 'pt_BR', parts = ['pt', 'BR', 'home', 'screen']

  String localePart;
  String pageIdentifier;

  // Determine locale part and page identifier based on parts structure
  if (parts.length >= 4 && (parts[1].length == 4 || parts[1].length == 2)) {
    // Complex locale with script code (e.g., zh_Hant) or country code (e.g., pt_BR)
    localePart = '${parts[0]}_${parts[1]}';
    pageIdentifier = parts.sublist(2).join('_');
  } else {
    // Simple locale (e.g., en, zh)
    localePart = parts[0];
    pageIdentifier = parts.sublist(1).join('_');
  }

  final String filename =
      '${localePart}_${counterStr}_${pageIdentifier}_$timestamp.png';
  // Example: en_01_home_screen_2025-01-11_10-30-00.png

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      // Ensure target directory exists - Use synchronous method
      final Directory directory = Directory(targetScreenshotDir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
        debugPrint('Created directory: $targetScreenshotDir');
      }

      final String targetPath = '$targetScreenshotDir/$filename';
      debugPrint('Target path: $targetPath');

      // Hide system UI (status bar and navigation bar) before taking screenshot
      debugPrint('Hiding system UI (status bar)...');
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      Uint8List? screenshotBytes;

      // Approach 1: Use RepaintBoundary with GlobalKey (most reliable)
      debugPrint('Approach 1: Using RepaintBoundary with GlobalKey...');
      try {
        final RenderRepaintBoundary? boundary =
            _repaintBoundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        if (boundary != null) {
          final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
          final ByteData? byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData != null) {
            screenshotBytes = byteData.buffer.asUint8List();
            debugPrint(
              'RepaintBoundary screenshot: ${screenshotBytes.length} bytes',
            );
          }
        } else {
          debugPrint('RepaintBoundary not found');
        }
      } catch (e) {
        debugPrint('RepaintBoundary approach failed: $e');
      }

      // Approach 2: Fallback to binding.takeScreenshot
      if (screenshotBytes == null || screenshotBytes.isEmpty) {
        debugPrint('Approach 2: Fallback to binding.takeScreenshot...');
        try {
          final List<int> bytes = await binding.takeScreenshot(nameWithCounter);
          if (bytes.isNotEmpty) {
            screenshotBytes = Uint8List.fromList(bytes);
            debugPrint('takeScreenshot: ${screenshotBytes.length} bytes');
          } else {
            debugPrint('takeScreenshot returned empty bytes');
          }
        } catch (e) {
          debugPrint('takeScreenshot failed: $e');
        }
      }

      // Save the screenshot if we got bytes
      if (screenshotBytes != null && screenshotBytes.isNotEmpty) {
        final File file = File(targetPath);
        file.writeAsBytesSync(screenshotBytes);
        createdScreenshots.add(targetPath);
        debugPrint('Screenshot saved to: $targetPath');
      } else {
        debugPrint('Failed to capture screenshot for $nameWithCounter');
      }

      // Verify file exists - Use synchronous method
      final String fileStatus = _fileInfoSync(targetPath);
      debugPrint('File status for $targetPath: $fileStatus');

      // Restore system UI (status bar and navigation bar) after screenshot
      debugPrint('Restoring system UI...');
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    } catch (e, stackTrace) {
      debugPrint('Screenshot error for $nameWithCounter: $e\n$stackTrace');

      // Ensure system UI is restored even on error
      try {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      } catch (_) {
        // Ignore errors during cleanup
      }
    }
  } else {
    debugPrint('Skipping screenshot on unsupported platform');
  }
  debugPrint(
    '====== SCREENSHOT PROCESS COMPLETED FOR: $nameWithCounter.png ======',
  );
}

// Capture the Home Page (GridPage)
Future<int> _captureHomePage(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Locale locale,
  int currentCounter,
) async {
  int counter = currentCounter;
  final String localeStr = localeToFilename(locale);
  final String baseName = '${localeStr}_${ScreenshotPage.home.fileNamePart}';

  debugPrint('Building GridPage for screenshot: $baseName');

  try {
    // Build the GridPage with proper localization, wrapped in RepaintBoundary
    // Override appSettingsProvider to skip dialogs during screenshots
    await tester.pumpWidget(
      RepaintBoundary(
        key: _repaintBoundaryKey,
        child: ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(() => _TestAppSettingsNotifier()),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            home: const GridPage(),
          ),
        ),
      ),
    );

    // Wait for the page to settle
    await tester.pumpAndSettle(const Duration(seconds: 3));
    debugPrint('GridPage settled with $locale locale.');

    // Click on the 5th grid cell (index 4, center cell) to start timer
    debugPrint('Clicking on grid cell #5 (center) to start timer...');
    try {
      // Find all timer grid cells
      final Finder gridCells = find.byType(TimerGridCell);
      if (gridCells.evaluate().length >= 5) {
        // Tap the 5th cell (index 4, which is the center of 3x3 grid)
        await tester.tap(gridCells.at(4));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        debugPrint('Timer started on grid cell #5');

        // Additional delay to let timer UI stabilize
        await Future<void>.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      } else {
        debugPrint('Warning: Could not find enough grid cells');
      }
    } catch (e) {
      debugPrint('Warning: Failed to tap grid cell: $e');
    }

    // Take screenshot #1: GridPage with timer running
    counter++;
    debugPrint('Taking screenshot #$counter for $baseName (timer running)');
    await _takeAndSaveScreenshot(binding, tester, baseName, counter);
    await Future<void>.delayed(const Duration(seconds: 1));

    // Tap again on grid cell #5 to show timer actions dialog
    debugPrint('Tapping grid cell #5 again to show timer actions dialog...');
    try {
      final Finder gridCells = find.byType(TimerGridCell);
      if (gridCells.evaluate().length >= 5) {
        // Second tap on running timer shows actions dialog
        await tester.tap(gridCells.at(4));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        debugPrint('Timer actions dialog shown');

        // Additional delay to ensure dialog animation completes
        await Future<void>.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        // Take screenshot #2: GridPage with dialog
        final String dialogBaseName =
            '${localeStr}_${ScreenshotPage.homeWithDialog.fileNamePart}';
        counter++;
        debugPrint(
          'Taking screenshot #$counter for $dialogBaseName (with dialog)',
        );
        await _takeAndSaveScreenshot(binding, tester, dialogBaseName, counter);
        await Future<void>.delayed(const Duration(seconds: 1));

        // Close the dialog by tapping the cancel button
        debugPrint('Closing timer actions dialog by tapping Cancel button...');
        // Try to find and tap the cancel/dismiss button
        final Finder dismissButtons = find.byType(TextButton);
        if (dismissButtons.evaluate().isNotEmpty) {
          // Tap the last button (usually Cancel/Close)
          await tester.tap(dismissButtons.last);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          debugPrint('Dialog closed via button');
        } else {
          // Fallback: Tap outside the dialog to dismiss
          debugPrint('Cancel button not found, tapping outside dialog...');
          await tester.tapAt(const Offset(50, 50));
          await tester.pumpAndSettle(const Duration(seconds: 1));
          debugPrint('Dialog closed via tap outside');
        }

        // Wait significantly to ensure dialog is fully dismissed and overlay removed
        debugPrint('Waiting for dialog overlay to be removed...');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Extra check: try to find dialog and if it exists, tap escape/back
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          debugPrint('Dialog still found, sending back event...');
          // Simulate back button to close any remaining dialogs
          await binding.handlePopRoute();
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }
    } catch (e) {
      debugPrint('Warning: Failed to capture dialog screenshot: $e');
    }
  } catch (e, stackTrace) {
    debugPrint('Error capturing GridPage for $locale: $e');
    debugPrint('$stackTrace');
  }

  return counter;
}

// Capture the Settings Page
Future<int> _captureSettingsPage(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  Locale locale,
  int currentCounter,
) async {
  int counter = currentCounter;
  final String localeStr = localeToFilename(locale);
  final String baseName =
      '${localeStr}_${ScreenshotPage.settings.fileNamePart}';

  debugPrint('Building SettingsPage for screenshot: $baseName');

  try {
    // Build the SettingsPage with proper localization, wrapped in RepaintBoundary
    // Override appSettingsProvider to skip dialogs during screenshots
    await tester.pumpWidget(
      RepaintBoundary(
        key: _repaintBoundaryKey,
        child: ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(() => _TestAppSettingsNotifier()),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            home: const SettingsPage(),
          ),
        ),
      ),
    );

    // Wait for the page to settle
    await tester.pumpAndSettle(const Duration(seconds: 3));
    debugPrint('SettingsPage settled with $locale locale.');

    // Additional delay to ensure:
    // 1. All async operations complete (FutureBuilders, etc.)
    // 2. No lingering dialogs or animations from previous page
    debugPrint('Waiting for SettingsPage to fully stabilize...');
    await Future<void>.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    debugPrint('SettingsPage fully stabilized, ready for screenshot');

    // Take screenshot #3: SettingsPage top view
    counter++;
    debugPrint('Taking screenshot #$counter for $baseName (top view)');
    await _takeAndSaveScreenshot(binding, tester, baseName, counter);
    await Future<void>.delayed(const Duration(seconds: 1));

    // Scroll down to capture more settings
    debugPrint('Scrolling down Settings page for second screenshot...');
    final Finder scrollableFinder = find.byType(Scrollable).first;
    if (scrollableFinder.evaluate().isNotEmpty) {
      final Size size = tester.getSize(scrollableFinder);
      final Offset scrollVector = Offset(0, -size.height * 0.6);
      await tester.drag(scrollableFinder, scrollVector, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final String baseNameScrolled = '${localeStr}_settings_screen_scrolled';
      counter++;
      debugPrint('Taking screenshot #$counter for $baseNameScrolled');
      await _takeAndSaveScreenshot(binding, tester, baseNameScrolled, counter);
      await Future<void>.delayed(const Duration(seconds: 1));
    } else {
      debugPrint('Scrollable not found in SettingsPage');
    }
  } catch (e, stackTrace) {
    debugPrint('Error capturing SettingsPage for $locale: $e');
    debugPrint('$stackTrace');
  }

  return counter;
}
