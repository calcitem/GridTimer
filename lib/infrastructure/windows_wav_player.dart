export 'windows_wav_player_interface.dart';

import 'windows_wav_player_interface.dart';
import 'windows_wav_player_stub.dart'
    if (dart.library.ffi) 'windows_wav_player_ffi.dart';

WindowsWavPlayer createWindowsWavPlayer() => createWindowsWavPlayerImpl();
