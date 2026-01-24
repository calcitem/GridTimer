import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/domain/enums.dart';
import '../core/domain/services/i_audio_service.dart';
import '../core/domain/types.dart';
import '../core/services/agent_debug_logger.dart';

/// Audio playback service implementation using the audioplayers plugin.
///
/// This service is used on:
/// - **Android & iOS**: Full support with platform-specific AudioContext
/// - **Linux & macOS**: Basic playback support (AudioContext not applicable)
/// - **Web**: Basic playback support via HTML5 audio
///
/// For Windows, a separate `WindowsAudioService` using FFI is used instead
/// to avoid platform channel thread safety issues.
///
/// ## Platform-specific behavior:
///
/// ### Android
/// - Uses USAGE_ALARM audio stream for reliable alarm playback
/// - Audio focus set to 'none' to mix with other app sounds
/// - Stays awake during playback to prevent sleep interruption
///
/// ### iOS
/// - Uses AVAudioSession playback category
/// - Mixes with other apps' audio (mixWithOthers option)
///
/// ### Linux & macOS
/// - Standard audio playback without mobile-specific AudioContext
/// - Volume control, looping, and playback modes all supported
/// - Relies on system audio routing (no custom audio session management)
///
/// ### Web
/// - HTML5 audio backend
/// - Basic playback features supported
/// - Platform limitations may apply (e.g., autoplay policies)
class AudioService implements IAudioService {
  static const MethodChannel _systemSettingsChannel = MethodChannel(
    'com.calcitem.gridtimer/system_settings',
  );

  final AudioPlayer _player = AudioPlayer();
  double _currentVolume = 1.0;

  /// Timer for auto-stopping after duration.
  Timer? _autoStopTimer;

  /// Timer for interval mode.
  Timer? _intervalTimer;

  bool _usingRingtoneUri = false;
  String? _activeRingtoneUri;
  bool _usingSystemTone = false;

  /// Builds AudioContext for mobile platforms.
  ///
  /// This configures platform-specific audio behavior for Android and iOS.
  /// Desktop and Web platforms do not use AudioContext.
  AudioContext _buildAudioContext() {
    return AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.alarm,
        // Use 'none' to ignore audio focus.
        // This ensures the alarm sound is mixed with other sounds (e.g. IM notifications)
        // and is NOT interrupted/paused when other apps request focus.
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const <AVAudioSessionOptions>{
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
  }

  /// Checks if the current platform supports AudioContext configuration.
  ///
  /// Returns true only for Android and iOS where audio session management
  /// is available and necessary. Desktop platforms (Linux, macOS) and Web
  /// do not require AudioContext configuration.
  bool get _supportsAudioContext {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Sets AudioContext if the platform supports it.
  ///
  /// On Android/iOS, this configures the audio session for alarm playback.
  /// On Linux/macOS/Web, this is a no-op as AudioContext is not applicable.
  Future<void> _setAudioContextIfSupported() async {
    if (!_supportsAudioContext) return;
    await _player.setAudioContext(_buildAudioContext());
  }

  @override
  Future<void> init() async {
    // Set release mode to loop (will be adjusted based on playback mode).
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_currentVolume);

    // Set audio context to alarm/notification to ensure playback even when locked.
    // This is only effective on Android/iOS; desktop platforms work without it.
    await _setAudioContextIfSupported();
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
  }) async {
    // Use default mode for backward compatibility.
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
    String? soundUri,
  }) async {
    // #region agent log
    assert(() {
      AgentDebugLogger.log(
        hypothesisId: 'A',
        location: 'audio_service.dart:playWithMode',
        message: 'Attempting in-app audio playback',
        data: <String, Object?>{
          'soundKey': soundKey,
          'mode': mode.name,
          'volume': volume,
          'loopDurationMinutes': loopDurationMinutes,
          'intervalPauseMinutes': intervalPauseMinutes,
        },
      );
      return true;
    }());
    // #endregion

    try {
      // Always stop first to ensure clean state.
      await stop();

      // Re-apply audio context to ensure we have focus (Android/iOS only).
      // On desktop platforms, this is a no-op.
      await _setAudioContextIfSupported();

      // Set volume before playing.
      await setVolume(volume);

      // Configure release mode based on playback mode.
      switch (mode) {
        case AudioPlaybackMode.playOnce:
          await _player.setReleaseMode(ReleaseMode.stop);
          break;
        default:
          await _player.setReleaseMode(ReleaseMode.loop);
      }

      // Start playing.
      final assetPath = _soundKeyToAssetPath(soundKey);

      final uri = soundUri;
      final isAndroid =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      final useSoundUri = isAndroid && uri != null && uri.isNotEmpty;

      // #region agent log
      assert(() {
        AgentDebugLogger.log(
          hypothesisId: 'A',
          location: 'audio_service.dart:playWithMode',
          message: 'Selected audio source for in-app playback',
          data: <String, Object?>{
            'soundKey': soundKey,
            'useSoundUri': useSoundUri,
            'soundUri': soundUri,
            'assetPath': assetPath,
          },
        );
        return true;
      }());
      // #endregion

      if (useSoundUri) {
        // For Android content:// URIs (common on MIUI), use native ringtone playback.
        // audioplayers UrlSource may not support content URIs and can hang before failing.
        if (uri.startsWith('content://')) {
          final loop = mode != AudioPlaybackMode.playOnce;
          final res = await _playRingtoneUriDetailed(
            uri: uri,
            loop: loop,
            usage: 'alarm',
          );
          if (res.ok) {
            _usingRingtoneUri = true;
            _activeRingtoneUri = uri;
            _setupPlaybackTimers(
              mode: mode,
              loopDurationMinutes: loopDurationMinutes,
              intervalPauseMinutes: intervalPauseMinutes,
            );
            return;
          }

          // If MIUI blocks the URI with Permission Denial, fall back to system alarm tone.
          final err = res.error ?? '';
          final isPermissionDenied = err.contains('Permission Denial');
          if (isPermissionDenied) {
            final sysOk = await _playSystemTone(type: 'alarm', loop: loop);
            // #region agent log
            assert(() {
              AgentDebugLogger.log(
                hypothesisId: 'A',
                location: 'audio_service.dart:playWithMode',
                message: 'Falling back to system alarm tone',
                data: <String, Object?>{
                  'blockedUri': uri,
                  'originalError': err,
                  'systemToneOk': sysOk,
                },
              );
              return true;
            }());
            // #endregion
            if (sysOk) {
              _usingSystemTone = true;
              _setupPlaybackTimers(
                mode: mode,
                loopDurationMinutes: loopDurationMinutes,
                intervalPauseMinutes: intervalPauseMinutes,
              );
              return;
            }
          }

          // Fall back to asset if native playback fails.
          await _player.play(AssetSource(assetPath));
        } else {
          try {
            await _player.play(UrlSource(uri));
          } catch (e) {
            // #region agent log
            assert(() {
              AgentDebugLogger.log(
                hypothesisId: 'A',
                location: 'audio_service.dart:playWithMode',
                message: 'URI playback failed, falling back to asset',
                data: <String, Object?>{
                  'soundUri': uri,
                  'assetPath': assetPath,
                  'error': e.toString(),
                },
              );
              return true;
            }());
            // #endregion
            await _player.play(AssetSource(assetPath));
          }
        }
      } else {
        await _player.play(AssetSource(assetPath));
      }

      // Set up timers based on mode.
      _setupPlaybackTimers(
        mode: mode,
        loopDurationMinutes: loopDurationMinutes,
        intervalPauseMinutes: intervalPauseMinutes,
      );
    } catch (e) {
      // Catch audio playback errors to avoid affecting app operation.
      debugPrint('Audio playback error: $e');

      // #region agent log
      assert(() {
        AgentDebugLogger.log(
          hypothesisId: 'A',
          location: 'audio_service.dart:playWithMode',
          message: 'In-app audio playback failed',
          data: <String, Object?>{
            'soundKey': soundKey,
            'mode': mode.name,
            'volume': volume,
            'error': e.toString(),
          },
        );
        return true;
      }());
      // #endregion
    }
  }

  ({bool ok, String? error, String? player}) _normalizeRingtoneResult(
    Map<dynamic, dynamic>? result,
  ) {
    final ok = result?['success'] == true;
    final error = result?['error'] as String?;
    final player = result?['player'] as String?;
    return (ok: ok, error: error, player: player);
  }

  Future<({bool ok, String? error, String? player})> _playRingtoneUriDetailed({
    required String uri,
    required bool loop,
    required String usage,
  }) async {
    try {
      final result = await _systemSettingsChannel
          .invokeMethod<Map<dynamic, dynamic>>(
            'playRingtoneUri',
            <String, Object?>{'uri': uri, 'loop': loop, 'usage': usage},
          );
      final normalized = _normalizeRingtoneResult(result);
      final ok = normalized.ok;

      // #region agent log
      assert(() {
        AgentDebugLogger.log(
          hypothesisId: 'A',
          location: 'audio_service.dart:_playRingtoneUri',
          message: 'Native ringtone URI playback result',
          data: <String, Object?>{
            'uri': uri,
            'loop': loop,
            'usage': usage,
            'ok': ok,
            'result': result?.map((k, v) => MapEntry(k.toString(), v)),
          },
        );
        return true;
      }());
      // #endregion

      return normalized;
    } catch (e) {
      // #region agent log
      assert(() {
        AgentDebugLogger.log(
          hypothesisId: 'A',
          location: 'audio_service.dart:_playRingtoneUri',
          message: 'Native ringtone URI playback threw',
          data: <String, Object?>{
            'uri': uri,
            'loop': loop,
            'usage': usage,
            'error': e.toString(),
          },
        );
        return true;
      }());
      // #endregion
      return (ok: false, error: e.toString(), player: null);
    }
  }

  Future<void> _stopRingtoneUri() async {
    try {
      await _systemSettingsChannel.invokeMethod<void>('stopRingtoneUri');
    } catch (_) {
      // Ignore.
    }
  }

  Future<bool> _playSystemTone({
    required String type,
    required bool loop,
  }) async {
    try {
      final result = await _systemSettingsChannel
          .invokeMethod<Map<dynamic, dynamic>>(
            'playSystemTone',
            <String, Object?>{'type': type, 'loop': loop},
          );
      final ok = result?['isPlaying'] == true;
      // #region agent log
      assert(() {
        AgentDebugLogger.log(
          hypothesisId: 'A',
          location: 'audio_service.dart:_playSystemTone',
          message: 'System tone playback result',
          data: <String, Object?>{
            'type': type,
            'loop': loop,
            'ok': ok,
            'result': result?.map((k, v) => MapEntry(k.toString(), v)),
          },
        );
        return true;
      }());
      // #endregion
      return ok;
    } catch (e) {
      // #region agent log
      assert(() {
        AgentDebugLogger.log(
          hypothesisId: 'A',
          location: 'audio_service.dart:_playSystemTone',
          message: 'System tone playback threw',
          data: <String, Object?>{
            'type': type,
            'loop': loop,
            'error': e.toString(),
          },
        );
        return true;
      }());
      // #endregion
      return false;
    }
  }

  Future<void> _stopSystemTone() async {
    try {
      await _systemSettingsChannel.invokeMethod<void>('stopSystemTone');
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> _pausePlayback() async {
    if (_usingRingtoneUri) {
      await _stopRingtoneUri();
      return;
    }
    if (_usingSystemTone) {
      await _stopSystemTone();
      return;
    }
    await _player.pause();
  }

  Future<void> _resumePlayback() async {
    if (_usingRingtoneUri) {
      final uri = _activeRingtoneUri;
      if (uri == null || uri.isEmpty) return;
      await _playRingtoneUriDetailed(uri: uri, loop: true, usage: 'alarm');
      return;
    }
    if (_usingSystemTone) {
      await _playSystemTone(type: 'alarm', loop: true);
      return;
    }
    await _player.resume();
  }

  void _setupPlaybackTimers({
    required AudioPlaybackMode mode,
    required int loopDurationMinutes,
    required int intervalPauseMinutes,
  }) {
    // Cancel existing timers.
    _autoStopTimer?.cancel();
    _intervalTimer?.cancel();

    switch (mode) {
      case AudioPlaybackMode.loopIndefinitely:
        // No timer needed, loop indefinitely.
        break;

      case AudioPlaybackMode.loopForDuration:
        // Stop after N minutes.
        _autoStopTimer = Timer(
          Duration(minutes: loopDurationMinutes),
          () async {
            await stop();
          },
        );
        break;

      case AudioPlaybackMode.loopWithInterval:
        // Loop for N minutes, pause for M minutes, loop for N minutes once more.
        _setupIntervalMode(
          loopDurationMinutes: loopDurationMinutes,
          intervalPauseMinutes: intervalPauseMinutes,
          repeating: false,
        );
        break;

      case AudioPlaybackMode.loopWithIntervalRepeating:
        // Loop for N minutes, pause for M minutes, repeat until stopped.
        _setupIntervalMode(
          loopDurationMinutes: loopDurationMinutes,
          intervalPauseMinutes: intervalPauseMinutes,
          repeating: true,
        );
        break;

      case AudioPlaybackMode.playOnce:
        // Audio will stop automatically (ReleaseMode.stop).
        break;
    }
  }

  void _setupIntervalMode({
    required int loopDurationMinutes,
    required int intervalPauseMinutes,
    required bool repeating,
  }) {
    int cycleCount = 0;
    const maxCycles =
        2; // For non-repeating: play twice with one pause in between.

    void scheduleCycle() {
      if (!repeating && cycleCount >= maxCycles) {
        return; // Stop after 2 cycles for non-repeating mode.
      }

      // Phase 1: Play for N minutes.
      _intervalTimer = Timer(Duration(minutes: loopDurationMinutes), () async {
        // Pause audio.
        await _pausePlayback();

        // Phase 2: Pause for M minutes.
        _intervalTimer = Timer(
          Duration(minutes: intervalPauseMinutes),
          () async {
            cycleCount++;

            if (repeating || cycleCount < maxCycles) {
              // Resume audio.
              await _resumePlayback();

              // Schedule next cycle.
              scheduleCycle();
            } else {
              // Non-repeating mode: final cycle, just resume and let it play.
              await _resumePlayback();

              // Stop after the final loop duration.
              _autoStopTimer = Timer(
                Duration(minutes: loopDurationMinutes),
                () async {
                  await stop();
                },
              );
            }
          },
        );
      });
    }

    scheduleCycle();
  }

  @override
  Future<void> stop() async {
    try {
      if (_usingRingtoneUri) {
        await _stopRingtoneUri();
        _usingRingtoneUri = false;
        _activeRingtoneUri = null;
      }
      if (_usingSystemTone) {
        await _stopSystemTone();
        _usingSystemTone = false;
      }
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
    if (_usingRingtoneUri) {
      try {
        final playing = await _systemSettingsChannel.invokeMethod<bool>(
          'isRingtoneUriPlaying',
        );
        return playing ?? false;
      } catch (_) {
        return false;
      }
    }
    return _player.state == PlayerState.playing;
  }

  String _soundKeyToAssetPath(SoundKey soundKey) {
    // All timers use the same sound file.
    return 'sounds/sound.wav';
  }

  void dispose() {
    _autoStopTimer?.cancel();
    _intervalTimer?.cancel();
    _player.dispose();
  }
}
