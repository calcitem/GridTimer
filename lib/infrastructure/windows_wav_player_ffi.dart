import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'windows_wav_player_interface.dart';

/// Creates the platform-specific WAV player implementation.
///
/// This factory function is conditionally imported based on FFI availability.
/// However, the FFI implementation (using winmm.dll) only works on Windows.
/// For defensive programming, we check the platform at runtime and return
/// a stub implementation on non-Windows platforms.
///
/// Note: In normal usage, WindowsAudioService is only instantiated on Windows
/// (see audioServiceProvider in lib/app/providers.dart), so the stub should
/// never be used. This check is an additional safety measure.
WindowsWavPlayer createWindowsWavPlayerImpl() {
  if (!Platform.isWindows) {
    assert(
      false,
      'WindowsWavPlayer FFI implementation should only be used on Windows. '
      'Check audioServiceProvider platform logic.',
    );
    // Return stub as fallback to prevent crashes
    return _FallbackStubWavPlayer();
  }
  return _WinmmWavPlayer();
}

/// Fallback stub implementation for non-Windows platforms.
///
/// This should never be instantiated in production due to platform checks
/// in audioServiceProvider, but provides a safety net.
class _FallbackStubWavPlayer implements WindowsWavPlayer {
  @override
  Future<void> init({required String assetKey}) async {}

  @override
  Future<void> playLoop() async {}

  @override
  Future<void> playOnce() async {}

  @override
  Future<void> stop() async {}
}

typedef _PlaySoundNative =
    Int32 Function(Pointer<Void> pszSound, Pointer<Void> hmod, Uint32 fdwSound);
typedef _PlaySoundDart =
    int Function(Pointer<Void> pszSound, Pointer<Void> hmod, int fdwSound);

class _WinmmWavPlayer implements WindowsWavPlayer {
  static const int _sndAsync = 0x0001;
  static const int _sndNodefault = 0x0002;
  static const int _sndMemory = 0x0004;
  static const int _sndLoop = 0x0008;
  // static const int _sndPurge = 0x0040; // Unused

  static void _free(Pointer<Uint8> ptr) => malloc.free(ptr);

  static final Finalizer<Pointer<Uint8>> _finalizer = Finalizer<Pointer<Uint8>>(
    _free,
  );

  late final DynamicLibrary _winmm = DynamicLibrary.open('winmm.dll');
  late final _PlaySoundDart _playSound = _winmm
      .lookupFunction<_PlaySoundNative, _PlaySoundDart>('PlaySoundW');

  bool _initialized = false;
  Pointer<Uint8>? _wavPtr;
  int _wavLen = 0;

  @override
  Future<void> init({required String assetKey}) async {
    if (_initialized) return;

    try {
      final data = await rootBundle.load(assetKey);
      final bytes = _byteDataToBytes(data);

      _wavLen = bytes.length;
      final ptr = malloc.allocate<Uint8>(_wavLen);
      ptr.asTypedList(_wavLen).setAll(0, bytes);
      _wavPtr = ptr;
      _finalizer.attach(this, ptr, detach: this);

      _initialized = true;
      debugPrint('WinmmWavPlayer: loaded asset $assetKey, bytes=$_wavLen');
    } catch (e, st) {
      debugPrint('WinmmWavPlayer: init failed: $e');
      debugPrint('WinmmWavPlayer: stack trace: $st');
      rethrow;
    }
  }

  @override
  Future<void> playOnce() async {
    assert(_initialized, 'WinmmWavPlayer.playOnce called before init');
    final ptr = _wavPtr;
    if (ptr == null || _wavLen <= 0) return;

    final ok = _playSound(
      ptr.cast<Void>(),
      nullptr,
      _sndAsync | _sndMemory | _sndNodefault,
    );
    if (ok == 0) {
      debugPrint('WinmmWavPlayer: PlaySoundW(playOnce) failed');
    }
  }

  @override
  Future<void> playLoop() async {
    assert(_initialized, 'WinmmWavPlayer.playLoop called before init');
    final ptr = _wavPtr;
    if (ptr == null || _wavLen <= 0) return;

    final ok = _playSound(
      ptr.cast<Void>(),
      nullptr,
      _sndAsync | _sndMemory | _sndNodefault | _sndLoop,
    );
    if (ok == 0) {
      debugPrint('WinmmWavPlayer: PlaySoundW(playLoop) failed');
    }
  }

  @override
  Future<void> stop() async {
    // Stop any currently playing sound started by PlaySound.
    // Use NULL for both pointers to stop all sounds.
    // SND_PURGE (0x0040) is not strictly necessary if pszSound is NULL,
    // but using 0 is the standard way to stop.
    _playSound(nullptr, nullptr, 0);
  }

  Uint8List _byteDataToBytes(ByteData data) {
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
