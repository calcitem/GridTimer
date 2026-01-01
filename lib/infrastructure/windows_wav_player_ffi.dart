import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'windows_wav_player_interface.dart';

WindowsWavPlayer createWindowsWavPlayerImpl() => _WinmmWavPlayer();

typedef _PlaySoundNative =
    Int32 Function(Pointer<Void> pszSound, Pointer<Void> hmod, Uint32 fdwSound);
typedef _PlaySoundDart =
    int Function(Pointer<Void> pszSound, Pointer<Void> hmod, int fdwSound);

class _WinmmWavPlayer implements WindowsWavPlayer {
  static const int _sndAsync = 0x0001;
  static const int _sndNodefault = 0x0002;
  static const int _sndMemory = 0x0004;
  static const int _sndLoop = 0x0008;
  static const int _sndPurge = 0x0040;

  static void _free(Pointer<Uint8> ptr) => malloc.free(ptr);

  static final Finalizer<Pointer<Uint8>> _finalizer =
      Finalizer<Pointer<Uint8>>(_free);

  late final DynamicLibrary _winmm = DynamicLibrary.open('winmm.dll');
  late final _PlaySoundDart _playSound = _winmm.lookupFunction<
    _PlaySoundNative,
    _PlaySoundDart
  >('PlaySoundW');

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
    _playSound(nullptr, nullptr, _sndPurge);
  }

  Uint8List _byteDataToBytes(ByteData data) {
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
