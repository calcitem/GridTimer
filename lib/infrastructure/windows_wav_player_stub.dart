import 'windows_wav_player_interface.dart';

WindowsWavPlayer createWindowsWavPlayerImpl() => _StubWindowsWavPlayer();

class _StubWindowsWavPlayer implements WindowsWavPlayer {
  @override
  Future<void> init({required String assetKey}) async {}

  @override
  Future<void> playLoop() async {}

  @override
  Future<void> playOnce() async {}

  @override
  Future<void> stop() async {}
}
