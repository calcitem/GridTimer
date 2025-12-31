import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import '../core/domain/services/i_gesture_service.dart';
import '../core/domain/enums.dart';

/// Gesture detection service implementation using sensors and hardware buttons.
class GestureService implements IGestureService {
  final StreamController<AlarmGestureType> _gestureController =
      StreamController<AlarmGestureType>.broadcast();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  bool _isMonitoring = false;
  double _shakeSensitivity = 2.5;

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

    try {
      VolumeController.instance.showSystemUI = false;
      VolumeController.instance.addListener((volume) {
        // Volume button was pressed (we don't care about the actual volume value)
        if (_isMonitoring) {
          // Emit both volume up and down events
          // Note: We can't distinguish which button was pressed on most devices
          _gestureController.add(AlarmGestureType.volumeUp);
        }
      });
    } catch (e) {
      debugPrint('GestureService init error: $e');
    }
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
    if (_isVolumeControllerSupported) {
      VolumeController.instance.removeListener();
    }
  }
}
