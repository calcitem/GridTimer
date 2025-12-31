import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../core/domain/services/i_audio_service.dart';
import '../core/domain/types.dart';
import '../core/domain/enums.dart';

/// Audio playback service implementation with multiple playback modes.
class AudioService implements IAudioService {
  final AudioPlayer _player = AudioPlayer();
  double _currentVolume = 1.0;
  
  /// Timer for auto-stopping after duration
  Timer? _autoStopTimer;
  
  /// Timer for interval mode
  Timer? _intervalTimer;

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

  @override
  Future<void> init() async {
    // Set release mode to loop (will be adjusted based on playback mode)
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_currentVolume);

    // 设置音频上下文为闹钟/通知，确保锁屏时也能播放
    await _player.setAudioContext(_buildAudioContext());
  }

  @override
  Future<void> setVolume(double volume) async {
    assert(
      volume >= 0.0 && volume <= 1.0,
      'Volume must be between 0.0 and 1.0',
    );
    _currentVolume = volume;
    await _player.setVolume(_currentVolume);
  }

  @override
  Future<void> playLoop({
    required SoundKey soundKey,
    double volume = 1.0,
    String? customAudioPath,
  }) async {
    // Use default mode for backward compatibility
    await playWithMode(
      soundKey: soundKey,
      volume: volume,
      mode: AudioPlaybackMode.loopIndefinitely,
      loopDurationMinutes: 5,
      intervalPauseMinutes: 2,
      customAudioPath: customAudioPath,
    );
  }

  @override
  Future<void> playWithMode({
    required SoundKey soundKey,
    required AudioPlaybackMode mode,
    double volume = 1.0,
    int loopDurationMinutes = 5,
    int intervalPauseMinutes = 2,
    String? customAudioPath,
  }) async {
    try {
      // Always stop first to ensure clean state
      await _player.stop();
      
      // Re-apply audio context to ensure we have focus
      await _player.setAudioContext(_buildAudioContext());

      // Set volume before playing
      await setVolume(volume);

      // Configure release mode based on playback mode
      switch (mode) {
        case AudioPlaybackMode.playOnce:
          await _player.setReleaseMode(ReleaseMode.stop);
          break;
        default:
          await _player.setReleaseMode(ReleaseMode.loop);
      }

      // Start playing (use custom audio if provided, otherwise use default)
      if (customAudioPath != null && customAudioPath.isNotEmpty) {
        await _player.play(DeviceFileSource(customAudioPath));
      } else {
        final assetPath = _soundKeyToAssetPath(soundKey);
        await _player.play(AssetSource(assetPath));
      }

      // Set up timers based on mode (no assetPath needed for timers)
      _setupPlaybackTimers(
        mode: mode,
        loopDurationMinutes: loopDurationMinutes,
        intervalPauseMinutes: intervalPauseMinutes,
      );
    } catch (e) {
      // 捕获音频播放错误，避免影响应用运行
      debugPrint('Audio playback error: $e');
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
      if (!repeating && cycleCount >= maxCycles) {
        return; // Stop after 2 cycles for non-repeating mode
      }

        // Phase 1: Play for N minutes
        _intervalTimer = Timer(
          Duration(minutes: loopDurationMinutes),
          () async {
            // Pause audio
            await _player.pause();

          // Phase 2: Pause for M minutes
          _intervalTimer = Timer(
            Duration(minutes: intervalPauseMinutes),
            () async {
              cycleCount++;
              
              if (repeating || cycleCount < maxCycles) {
                // Resume audio
                await _player.resume();
                
                // Schedule next cycle
                scheduleCycle();
              } else {
                // Non-repeating mode: final cycle, just resume and let it play
                await _player.resume();
                
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
    try {
      await _player.stop();
      _autoStopTimer?.cancel();
      _intervalTimer?.cancel();
      _autoStopTimer = null;
      _intervalTimer = null;
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  @override
  Future<bool> isPlaying() async {
    return _player.state == PlayerState.playing;
  }

  String _soundKeyToAssetPath(SoundKey soundKey) {
    // All timers use the same sound file
    return 'sounds/sound.wav';
  }

  void dispose() {
    _autoStopTimer?.cancel();
    _intervalTimer?.cancel();
    _player.dispose();
  }
}
