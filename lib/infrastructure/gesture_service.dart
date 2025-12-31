import 'dart:async';
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
  VolumeController? _volumeController;

  bool _isMonitoring = false;
  double _shakeSensitivity = 2.5;

  // Shake detection variables
  DateTime? _lastShakeTime;
  static const Duration _shakeCooldown = Duration(milliseconds: 500);

  // Flip detection variables
  bool _isFaceDown = false;
  DateTime? _lastFlipTime;
  static const Duration _flipCooldown = Duration(milliseconds: 500);

  @override
  Future<void> init() async {
    try {
      _volumeController = VolumeController();
      _volumeController?.showSystemUI = false;
      _volumeController?.listener((volume) {
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

    // Start accelerometer monitoring for shake detection
    _accelerometerSubscription = accelerometerEventStream().listen(
      _onAccelerometerEvent,
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
    );

    // Start gyroscope monitoring for flip detection
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      _onGyroscopeEvent,
      onError: (error) {
        debugPrint('Gyroscope error: $error');
      },
    );
  }

  @override
  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
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
    if (!_isMonitoring) return;

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
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!_isMonitoring) return;

    // Flip detection: check if phone is face down
    // This is a simplified approach - in production you might want to use
    // accelerometer gravity vector for more accurate orientation detection
    final rotationMagnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // If device is relatively stable and upside down
    if (rotationMagnitude < 1.0) {
      // Check accelerometer to determine if face down
      accelerometerEventStream().first.then((accelEvent) {
        final isFaceDownNow = accelEvent.z < -8.0; // Gravity pointing up

        if (isFaceDownNow && !_isFaceDown) {
          // Phone was just flipped face down
          final now = DateTime.now();
          if (_lastFlipTime == null ||
              now.difference(_lastFlipTime!) > _flipCooldown) {
            _lastFlipTime = now;
            _gestureController.add(AlarmGestureType.flip);
          }
        }

        _isFaceDown = isFaceDownNow;
      }).catchError((error) {
        debugPrint('Flip detection error: $error');
      });
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    _gestureController.close();
    _volumeController?.removeListener();
  }
}
