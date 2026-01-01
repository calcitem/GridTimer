import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../core/domain/services/i_audio_service.dart';
import '../core/domain/types.dart';
import '../core/domain/enums.dart';

/// Audio playback service implementation with multiple playback modes.
class AudioService implements IAudioService {
  AudioPlayer? _player;
  double _currentVolume = 1.0;

  /// Timer for auto-stopping after duration
  Timer? _autoStopTimer;

  /// Timer for interval mode
  Timer? _intervalTimer;

  /// Track if service is disposed to prevent accessing disposed player
  bool _isDisposed = false;

  /// Check if running on desktop platform where audioplayers has threading issues
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Get or create player instance safely
  AudioPlayer get _safePlayer {
    if (_isDisposed) {
      throw StateError('AudioService has been disposed');
    }
    _player ??= AudioPlayer();
    return _player!;
  }

  AudioContext _buildAudioContext() {
    return AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.alarm,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const <AVAudioSessionOptions>{AVAudioSessionOptions.mixWithOthers},
      ),
    );
  }

  bool get _supportsAudioContext {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _setAudioContextIfSupported() async {
    if (!_supportsAudioContext) return;
    try {
      await _safePlayer.setAudioContext(_buildAudioContext());
    } catch (e) {
      debugPrint('AudioService: Failed to set audio context: $e');
    }
  }

  @override
  Future<void> init() async {
    if (_isDisposed) return;

    try {
      // Set release mode to loop (will be adjusted based on playback mode)
      await _safePlayer.setReleaseMode(ReleaseMode.loop);
      await _safePlayer.setVolume(_currentVolume);

      // Set audio context to alarm/notification to ensure playback even when locked
      await _setAudioContextIfSupported();
    } catch (e) {
      debugPrint('AudioService: init error: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      'Volume must be between 0.0 and 1.0',
    );
    _currentVolume = volume;
    if (_isDisposed) return;
    try {
      await _safePlayer.setVolume(_currentVolume);
    } catch (e) {
      debugPrint('AudioService: setVolume error: $e');
    }
  }

  @override
  Future<void> playLoop({
    required SoundKey soundKey,
    double volume = 1.0,
  }) async {
    // Use default mode for backward compatibility
    await playWithMode(
      soundKey: soundKey,
      volume: volume,
      mode: AudioPlaybackMode.loopIndefinitely,
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
    if (_isDisposed) return;

    try {
      // On Windows, audioplayers has threading issues that can cause crashes.
      // Wrap everything in a try-catch and add delays between operations
      // to reduce the chance of race conditions.
      if (_isDesktop) {
        await _playWithModeDesktop(
          soundKey: soundKey,
          mode: mode,
          volume: volume,
          loopDurationMinutes: loopDurationMinutes,
          intervalPauseMinutes: intervalPauseMinutes,
        );
        return;
      }

      // Always stop first to ensure clean state
      await _safePlayer.stop();

      // Re-apply audio context to ensure we have focus
      await _setAudioContextIfSupported();

      // Set volume before playing
      await setVolume(volume);

      // Configure release mode based on playback mode
      switch (mode) {
        case AudioPlaybackMode.playOnce:
          await _safePlayer.setReleaseMode(ReleaseMode.stop);
          break;
        default:
          await _safePlayer.setReleaseMode(ReleaseMode.loop);
      }

      // Start playing (use default sound)
      final assetPath = _soundKeyToAssetPath(soundKey);
      await _safePlayer.play(AssetSource(assetPath));

      // Set up timers based on mode (no assetPath needed for timers)
      _setupPlaybackTimers(
        mode: mode,
        loopDurationMinutes: loopDurationMinutes,
        intervalPauseMinutes: intervalPauseMinutes,
      );
    } catch (e) {
      // Catch audio playback errors to avoid affecting app operation
      debugPrint('Audio playback error: $e');
    }
  }

  /// Desktop-specific playback with extra precautions for threading issues.
  Future<void> _playWithModeDesktop({
    required SoundKey soundKey,
    required AudioPlaybackMode mode,
    double volume = 1.0,
    int loopDurationMinutes = 5,
    int intervalPauseMinutes = 2,
  }) async {
    if (_isDisposed) return;

    try {
      // Recreate player to avoid stale state issues on Windows
      await _recreatePlayerIfNeeded();

      // Small delay to let any pending operations complete
      await Future<void>.delayed(const Duration(milliseconds: 50));

      if (_isDisposed) return;

      // Set volume before playing
      _currentVolume = volume;
      await _safePlayer.setVolume(_currentVolume);

      // Small delay
      await Future<void>.delayed(const Duration(milliseconds: 50));

      if (_isDisposed) return;

      // Configure release mode based on playback mode
      switch (mode) {
        case AudioPlaybackMode.playOnce:
          await _safePlayer.setReleaseMode(ReleaseMode.stop);
          break;
        default:
          await _safePlayer.setReleaseMode(ReleaseMode.loop);
      }

      // Small delay
      await Future<void>.delayed(const Duration(milliseconds: 50));

      if (_isDisposed) return;

      // Start playing
      final assetPath = _soundKeyToAssetPath(soundKey);
      await _safePlayer.play(AssetSource(assetPath));

      // Set up timers based on mode
      _setupPlaybackTimers(
        mode: mode,
        loopDurationMinutes: loopDurationMinutes,
        intervalPauseMinutes: intervalPauseMinutes,
      );

      debugPrint('AudioService: Desktop playback started successfully');
    } catch (e, stackTrace) {
      debugPrint('AudioService: Desktop playback error: $e');
      debugPrint('AudioService: Stack trace: $stackTrace');
      // On desktop, audio failures are non-fatal - TTS is the primary feedback
    }
  }

  /// Recreate the audio player to ensure clean state on desktop.
  Future<void> _recreatePlayerIfNeeded() async {
    if (!_isDesktop || _isDisposed) return;

    try {
      // Dispose existing player if any
      final oldPlayer = _player;
      _player = null;

      if (oldPlayer != null) {
        try {
          await oldPlayer.stop();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await oldPlayer.dispose();
        } catch (e) {
          debugPrint('AudioService: Error disposing old player: $e');
        }
      }

      // Create new player
      _player = AudioPlayer();
      debugPrint('AudioService: Recreated audio player for desktop');
    } catch (e) {
      debugPrint('AudioService: Error recreating player: $e');
    }
  }

  void _setupPlaybackTimers({
    required AudioPlaybackMode mode,
    required int loopDurationMinutes,
    required int intervalPauseMinutes,
  }) {
    // Cancel existing timers
    _autoStopTimer?.cancel();
    _intervalTimer?.cancel();

    switch (mode) {
      case AudioPlaybackMode.loopIndefinitely:
        // No timer needed, loop indefinitely
        break;

      case AudioPlaybackMode.loopForDuration:
        // Stop after N minutes
        _autoStopTimer = Timer(
          Duration(minutes: loopDurationMinutes),
          () async {
            await stop();
          },
        );
        break;

      case AudioPlaybackMode.loopWithInterval:
        // Loop for N minutes, pause for M minutes, loop for N minutes once more
        _setupIntervalMode(
          loopDurationMinutes: loopDurationMinutes,
          intervalPauseMinutes: intervalPauseMinutes,
          repeating: false,
        );
        break;

      case AudioPlaybackMode.loopWithIntervalRepeating:
        // Loop for N minutes, pause for M minutes, repeat until stopped
        _setupIntervalMode(
          loopDurationMinutes: loopDurationMinutes,
          intervalPauseMinutes: intervalPauseMinutes,
          repeating: true,
        );
        break;

      case AudioPlaybackMode.playOnce:
        // Audio will stop automatically (ReleaseMode.stop)
        break;
    }
  }

  void _setupIntervalMode({
    required int loopDurationMinutes,
    required int intervalPauseMinutes,
    required bool repeating,
  }) {
    int cycleCount = 0;
    const maxCycles = 2; // For non-repeating: play twice with one pause in between

    void scheduleCycle() {
      if (_isDisposed) return;
      if (!repeating && cycleCount >= maxCycles) {
        return; // Stop after 2 cycles for non-repeating mode
      }

      // Phase 1: Play for N minutes
      _intervalTimer = Timer(
        Duration(minutes: loopDurationMinutes),
        () async {
          if (_isDisposed) return;
          // Pause audio
          try {
            await _safePlayer.pause();
          } catch (e) {
            debugPrint('AudioService: pause error: $e');
            return;
          }

          // Phase 2: Pause for M minutes
          _intervalTimer = Timer(
            Duration(minutes: intervalPauseMinutes),
            () async {
              if (_isDisposed) return;
              cycleCount++;

              if (repeating || cycleCount < maxCycles) {
                // Resume audio
                try {
                  await _safePlayer.resume();
                } catch (e) {
                  debugPrint('AudioService: resume error: $e');
                  return;
                }

                // Schedule next cycle
                scheduleCycle();
              } else {
                // Non-repeating mode: final cycle, just resume and let it play
                try {
                  await _safePlayer.resume();
                } catch (e) {
                  debugPrint('AudioService: resume error: $e');
                  return;
                }

                // Stop after the final loop duration
                _autoStopTimer = Timer(
                  Duration(minutes: loopDurationMinutes),
                  () async {
                    await stop();
                  },
                );
              }
            },
          );
        },
      );
    }

    scheduleCycle();
  }

  @override
  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _intervalTimer?.cancel();
    _autoStopTimer = null;
    _intervalTimer = null;

    if (_isDisposed) return;

    try {
      await _safePlayer.stop();
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  @override
  Future<bool> isPlaying() async {
    if (_isDisposed || _player == null) return false;
    try {
      return _player!.state == PlayerState.playing;
    } catch (e) {
      return false;
    }
  }

  String _soundKeyToAssetPath(SoundKey soundKey) {
    // All timers use the same sound file
    return 'sounds/sound.wav';
  }

  void dispose() {
    _isDisposed = true;
    _autoStopTimer?.cancel();
    _intervalTimer?.cancel();
    _autoStopTimer = null;
    _intervalTimer = null;

    final player = _player;
    _player = null;
    if (player != null) {
      try {
        player.dispose();
      } catch (e) {
        debugPrint('AudioService: dispose error: $e');
      }
    }
  }
}
