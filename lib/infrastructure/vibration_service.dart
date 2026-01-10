import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../core/domain/services/i_vibration_service.dart';

/// Vibration service implementation.
class VibrationService implements IVibrationService {
  bool _hasVibrator = false;
  bool _initialized = false;

  /// Check if the current platform supports vibration features.
  bool get _isPlatformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!_isPlatformSupported) {
      // Platform not supported is an expected state on Desktop/Web
      // Log as info/debug instead of warning
      return;
    }

    try {
      _hasVibrator = await Vibration.hasVibrator();
      debugPrint('VibrationService: Vibrator available = $_hasVibrator');
    } catch (e) {
      debugPrint('VibrationService init error: $e');
      _hasVibrator = false;
    }
  }

  @override
  Future<bool> hasVibrator() async {
    if (!_isPlatformSupported) return false;
    return _hasVibrator;
  }

  @override
  Future<void> vibrate({int duration = 500}) async {
    if (!_isPlatformSupported || !_hasVibrator) return;

    try {
      await Vibration.vibrate(duration: duration);
    } catch (e) {
      debugPrint('VibrationService vibrate error: $e');
    }
  }

  @override
  Future<void> vibrateWithPattern(List<int> pattern) async {
    if (!_isPlatformSupported || !_hasVibrator) return;

    try {
      // Check if custom vibration patterns are supported.
      final hasCustomVibrationsSupport =
          await Vibration.hasCustomVibrationsSupport();

      if (hasCustomVibrationsSupport) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        // Fallback to simple vibration if custom patterns are not supported.
        await Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      debugPrint('VibrationService vibrateWithPattern error: $e');
    }
  }

  @override
  Future<void> cancel() async {
    if (!_isPlatformSupported || !_hasVibrator) return;

    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('VibrationService cancel error: $e');
    }
  }
}
