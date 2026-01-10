import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/domain/enums.dart';
import '../core/domain/services/i_audio_service.dart';
import '../core/domain/types.dart';
import 'windows_wav_player.dart';

/// Windows-specific audio service implementation using winmm PlaySound API via FFI.
///
/// ## Why not use audioplayers on Windows?
///
/// The `audioplayers` plugin can crash on Windows when platform channel messages
/// are sent from non-platform threads, which is common in alarm/timer scenarios
/// where audio playback is triggered from background timers or system callbacks.
///
/// ## Implementation details:
///
/// - Uses native Windows **winmm.dll** `PlaySoundW` function via FFI
/// - Loads WAV file into memory once during initialization
/// - Supports both one-shot and looping playback modes
/// - No platform channel overhead - direct native calls
/// - Stable and reliable even when called from background threads
///
/// ## Limitations:
///
/// - Only supports WAV format (sufficient for alarm sounds)
/// - Single audio file loaded at initialization (all timers use same sound)
/// - Basic volume control (0.0 = stop playback, >0.0 = system volume)
/// - No audio session management (uses default Windows audio routing)
///
/// ## Platform compatibility:
///
/// This service is **only instantiated on Windows** (see `audioServiceProvider`
/// in `lib/app/providers.dart`). Other desktop platforms:
/// - **Linux & macOS**: Use `AudioService` (audioplayers plugin works well)
/// - **Android & iOS**: Use `AudioService` with mobile-specific AudioContext
///
/// ## See also:
/// - `windows_wav_player.dart` for the FFI abstraction layer
/// - `windows_wav_player_ffi.dart` for the native PlaySound implementation
class WindowsAudioService implements IAudioService {
  static const String _alarmAssetKey = 'assets/sounds/sound.wav';

  final WindowsWavPlayer _wavPlayer = createWindowsWavPlayer();

  double _currentVolume = 1.0;
  bool _isInitialized = false;
  bool _isPlaying = false;

  Timer? _autoStopTimer;
  Timer? _intervalTimer;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _wavPlayer.init(assetKey: _alarmAssetKey);
      _isInitialized = true;
    } catch (e) {
      // Fail fast in debug; in release, keep running without audio.
      assert(false, 'WindowsAudioService init failed: $e');
      debugPrint('WindowsAudioService: init failed: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      'Volume must be between 0.0 and 1.0',
    );
    _currentVolume = volume;
    if (_currentVolume <= 0.0 && _isPlaying) {
      await stop();
    }
  }

  @override
  Future<void> playLoop({
    required SoundKey soundKey,
    double volume = 1.0,
  }) async {
    await playWithMode(
      soundKey: soundKey,
      mode: AudioPlaybackMode.loopIndefinitely,
      volume: volume,
      loopDurationMinutes: 5,
      intervalPauseMinutes: 2,
    );
  }

  @override
  Future<void> playWithMode({
    required SoundKey soundKey,
    required AudioPlaybackMode mode,
    double volume = 1.0,
    int loopDurationMinutes = 5,
    int intervalPauseMinutes = 2,
  }) async {
    // soundKey is currently ignored because all timers share the same WAV asset.
    if (!_isInitialized) {
      await init();
    }

    await stop();
    await setVolume(volume);
    if (_currentVolume <= 0.0) return;

    switch (mode) {
      case AudioPlaybackMode.playOnce:
        _isPlaying = true;
        await _wavPlayer.playOnce();
        // No reliable completion callback; mark as not playing shortly after.
        Timer(const Duration(seconds: 2), () => _isPlaying = false);
        return;

      case AudioPlaybackMode.loopIndefinitely:
        _isPlaying = true;
        await _wavPlayer.playLoop();
        return;

      case AudioPlaybackMode.loopForDuration:
        assert(loopDurationMinutes > 0, 'loopDurationMinutes must be > 0');
        _isPlaying = true;
        await _wavPlayer.playLoop();
        _autoStopTimer = Timer(Duration(minutes: loopDurationMinutes), () {
          unawaited(stop());
        });
        return;

      case AudioPlaybackMode.loopWithInterval:
        _startIntervalMode(
          loopDurationMinutes: loopDurationMinutes,
          intervalPauseMinutes: intervalPauseMinutes,
          repeating: false,
        );
        return;

      case AudioPlaybackMode.loopWithIntervalRepeating:
        _startIntervalMode(
          loopDurationMinutes: loopDurationMinutes,
          intervalPauseMinutes: intervalPauseMinutes,
          repeating: true,
        );
        return;
    }
  }

  void _startIntervalMode({
    required int loopDurationMinutes,
    required int intervalPauseMinutes,
    required bool repeating,
  }) {
    assert(loopDurationMinutes > 0, 'loopDurationMinutes must be > 0');
    assert(intervalPauseMinutes > 0, 'intervalPauseMinutes must be > 0');

    _isPlaying = true;
    int cycleCount = 0;
    const maxCycles = 2; // Non-repeating: play twice with one pause in between.

    late final Future<void> Function() startPlayPhase;
    late final Future<void> Function() stopAndMaybeScheduleNext;

    stopAndMaybeScheduleNext = () async {
      await _wavPlayer.stop();
      _intervalTimer?.cancel();
      _intervalTimer = Timer(Duration(minutes: intervalPauseMinutes), () {
        cycleCount++;
        if (repeating || cycleCount < maxCycles) {
          unawaited(startPlayPhase());
        } else {
          // Final play phase for non-repeating mode, then stop after duration.
          unawaited(_wavPlayer.playLoop());
          _autoStopTimer?.cancel();
          _autoStopTimer = Timer(Duration(minutes: loopDurationMinutes), () {
            unawaited(stop());
          });
        }
      });
    };

    startPlayPhase = () async {
      if (!repeating && cycleCount >= maxCycles) {
        await stop();
        return;
      }

      await _wavPlayer.playLoop();
      _intervalTimer?.cancel();
      _intervalTimer = Timer(Duration(minutes: loopDurationMinutes), () {
        unawaited(stopAndMaybeScheduleNext());
      });
    };

    unawaited(startPlayPhase());
  }

  @override
  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _intervalTimer?.cancel();
    _autoStopTimer = null;
    _intervalTimer = null;
    _isPlaying = false;

    try {
      await _wavPlayer.stop();
    } catch (e) {
      debugPrint('WindowsAudioService: stop failed: $e');
    }
  }

  @override
  Future<bool> isPlaying() async => _isPlaying;
}
