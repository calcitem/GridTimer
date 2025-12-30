# Hive Initialization Fix

## Problem

Application crashed with error:
```
HiveError: You need to initialize Hive or provide a path to store the box.
```

## Root Cause

The `LocaleNotifier` was trying to access Hive storage in its constructor before Hive was initialized in `main()`. This created a race condition where:

1. `ProviderScope` was created
2. `localeProvider` was accessed during app build
3. `LocaleNotifier()` constructor ran
4. `_loadLocale()` tried to open Hive box
5. **Hive was not yet initialized** ❌

## Solution

### 1. Initialize Hive in `main()` Before App Starts

**File: `lib/main.dart`**

Added Hive initialization before creating `ProviderScope`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before anything else
  await Hive.initFlutter('GridTimer');

  runApp(const ProviderScope(child: GridTimerApp()));
}
```

### 2. Defer Locale Loading in LocaleNotifier

**File: `lib/app/locale_provider.dart`**

Modified `LocaleNotifier` to defer loading until after Hive is initialized:

```dart
class LocaleNotifier extends StateNotifier<Locale?> {
  static const String _boxName = 'settings';
  static const String _localeKey = 'app_locale';
  bool _initialized = false;

  LocaleNotifier() : super(null) {
    // Don't load immediately, wait for Hive to be initialized
    Future.microtask(_loadLocale);
  }

  /// Load saved locale from storage
  Future<void> _loadLocale() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final box = await Hive.openBox(_boxName);
      final savedLocale = box.get(_localeKey) as String?;
      if (savedLocale != null) {
        state = Locale(savedLocale);
      }
    } catch (e) {
      // Ignore errors, use system default
      debugPrint('Failed to load locale: $e');
    }
  }
  
  // ... rest of the code
}
```

## Key Changes

### Added Import
```dart
import 'package:hive_ce_flutter/hive_flutter.dart';
```

### Initialization Order
1. ✅ `WidgetsFlutterBinding.ensureInitialized()`
2. ✅ `await Hive.initFlutter('GridTimer')`
3. ✅ `runApp(ProviderScope(...))`
4. ✅ `LocaleNotifier` loads locale asynchronously

### Deferred Loading
- Used `Future.microtask()` to defer Hive access
- Added `_initialized` flag to prevent duplicate loading
- Graceful error handling if Hive fails

## Benefits

- ✅ No race condition
- ✅ Hive always initialized before use
- ✅ Locale loads asynchronously without blocking UI
- ✅ App starts with default locale, then updates when loaded
- ✅ Error handling in place

## Testing

Verified:
1. ✅ App starts without crash
2. ✅ Locale loads from storage
3. ✅ Language switching works
4. ✅ Locale persists across restarts

## Notes

- Hive initialization happens once in `main()`
- `StorageRepository.init()` also calls `Hive.initFlutter()` but it's safe to call multiple times
- The first call initializes, subsequent calls are no-ops
- Locale loading is non-blocking and graceful

## Code Quality

- ✅ No linter errors
- ✅ Proper error handling
- ✅ Thread-safe initialization
- ✅ Clear separation of concerns

