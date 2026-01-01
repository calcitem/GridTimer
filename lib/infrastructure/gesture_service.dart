import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import '../core/domain/services/i_gesture_service.dart';
import '../core/domain/enums.dart';

/// Gesture detection service implementation using sensors and hardware buttons.
class GestureService implements IGestureService {
  static const EventChannel _volumeKeyEventChannel = EventChannel(
    'com.calcitem.gridtimer/volume_key_events',
  );

  final StreamController<AlarmGestureType> _gestureController =
      StreamController<AlarmGestureType>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<dynamic>? _volumeKeySubscription;

  bool _isMonitoring = false;
  double _shakeSensitivity = 2.5;
  double? _lastVolume;
  DateTime? _lastNativeVolumeKeyAt;

  /// Check if current platform supports sensors (mobile platforms only)
  /// Note: sensors_plus supports both Android and iOS
  bool get _isSensorSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if volume controller is supported (Android only)
  /// Note: iOS has strict limitations on volume button detection
  bool get _isVolumeControllerSupported => !kIsWeb && Platform.isAndroid;

  // Shake detection variables
  DateTime? _lastShakeTime;
  static const Duration _shakeCooldown = Duration(milliseconds: 500);

  // Flip detection variables (using accelerometer only for better reliability)
  bool _isFaceDown = false;
  DateTime? _lastFlipTime;
  static const Duration _flipCooldown = Duration(milliseconds: 500);
  int _flipConfirmationCount = 0;
  static const int _flipConfirmationThreshold =
      3; // Require 3 consecutive readings

  @override
  Future<void> init() async {
    // Volume controller is only available on Android
    if (!_isVolumeControllerSupported) {
      debugPrint(
        'Volume controller not supported on current platform, skipping initialization',
      );
      return;
    }

    // Prefer direct volume key events (more reliable across OEM ROMs than volume-change
    // broadcasts), but keep volume_controller as a best-effort fallback.
    try {
      _volumeKeySubscription =
          _volumeKeyEventChannel.receiveBroadcastStream().listen(
        (event) {
          final gestureType = _parseVolumeKeyEvent(event);
          if (gestureType == null) return;

          _lastNativeVolumeKeyAt = DateTime.now();
          if (!_isMonitoring) return;

          _gestureController.add(gestureType);
        },
        onError: (error) {
          debugPrint('GestureService: volume key event channel error: $error');
        },
      );
    } catch (e) {
      debugPrint('GestureService: Failed to init volume key event channel: $e');
    }

    try {
      VolumeController.instance.showSystemUI = false;
      VolumeController.instance.addListener((volume) {
        // If we already got a direct volume key event, suppress the volume-change callback
        // to avoid duplicate gesture triggers.
        final lastNative = _lastNativeVolumeKeyAt;
        if (lastNative != null &&
            DateTime.now().difference(lastNative) <
                const Duration(milliseconds: 200)) {
          _lastVolume = volume;
          return;
        }

        // Volume button was pressed (we don't care about the actual volume value)
        final last = _lastVolume;
        _lastVolume = volume;

        if (!_isMonitoring) return;

        // Best-effort: infer which button was pressed by comparing the new volume value.
        // Some devices/ROMs may not report direction reliably; treat "unknown" as volumeUp.
        if (last == null) {
          _gestureController.add(AlarmGestureType.volumeUp);
          return;
        }

        const eps = 0.0001;
        final delta = volume - last;
        if (delta.abs() < eps) {
          _gestureController.add(AlarmGestureType.volumeUp);
          return;
        }
        _gestureController.add(
          delta > 0 ? AlarmGestureType.volumeUp : AlarmGestureType.volumeDown,
        );
      });
    } catch (e) {
      debugPrint('GestureService init error: $e');
    }
  }

  AlarmGestureType? _parseVolumeKeyEvent(dynamic event) {
    if (event is String) {
      switch (event) {
        case 'up':
          return AlarmGestureType.volumeUp;
        case 'down':
          return AlarmGestureType.volumeDown;
      }
    }
    if (event is Map) {
      final direction = event['direction'];
      if (direction is String) {
        switch (direction) {
          case 'up':
            return AlarmGestureType.volumeUp;
          case 'down':
            return AlarmGestureType.volumeDown;
        }
      }
    }
    return null;
  }

  @override
  Stream<AlarmGestureType> get gestureStream => _gestureController.stream;

  @override
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Start sensor monitoring only on supported platforms
    if (!_isSensorSupported) {
      debugPrint(
        'Sensors not supported on current platform, skipping sensor monitoring',
      );
      return;
    }

    // Start accelerometer monitoring for both shake and flip detection
    // Using only accelerometer is more reliable on lockscreen
    _accelerometerSubscription = accelerometerEventStream().listen(
      _onAccelerometerEvent,
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
    );

    debugPrint('GestureService: Started monitoring (shake and flip)');
  }

  @override
  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _flipConfirmationCount = 0;
    _isFaceDown = false;
    debugPrint('GestureService: Stopped monitoring');
  }

  @override
  void updateShakeSensitivity(double sensitivity) {
    assert(
      sensitivity >= 1.0 && sensitivity <= 5.0,
      'Shake sensitivity must be between 1.0 and 5.0',
    );
    _shakeSensitivity = sensitivity;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isMonitoring || !_isSensorSupported) return;

    // Calculate acceleration magnitude
    final acceleration = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Shake detection: significant acceleration beyond gravity
    // Threshold inversely proportional to sensitivity (lower sensitivity = higher threshold)
    final shakeThreshold = 15.0 + (5.0 - _shakeSensitivity) * 5.0;

    if (acceleration > shakeThreshold) {
      final now = DateTime.now();
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!) > _shakeCooldown) {
        _lastShakeTime = now;
        _gestureController.add(AlarmGestureType.shake);
      }
    }

    // Flip detection: check if phone is face down using Z-axis gravity
    // When phone is face down (screen facing ground), z-axis shows negative gravity
    // Z < -7.0 means phone is face down (allowing for some sensor noise)
    final isFaceDownNow = event.z < -7.0;

    if (isFaceDownNow) {
      _flipConfirmationCount++;

      // Only trigger flip event after consecutive confirmations
      if (_flipConfirmationCount >= _flipConfirmationThreshold &&
          !_isFaceDown) {
        final now = DateTime.now();
        if (_lastFlipTime == null ||
            now.difference(_lastFlipTime!) > _flipCooldown) {
          _lastFlipTime = now;
          _isFaceDown = true;
          _gestureController.add(AlarmGestureType.flip);
          debugPrint('GestureService: Flip detected (face down)');
        }
      }
    } else {
      _flipConfirmationCount = 0;
      _isFaceDown = false;
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    _gestureController.close();
    _volumeKeySubscription?.cancel();
    _volumeKeySubscription = null;
    if (_isVolumeControllerSupported) {
      VolumeController.instance.removeListener();
    }
  }
}
