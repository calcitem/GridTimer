export 'windows_wav_player_interface.dart';

import 'windows_wav_player_interface.dart';

// Conditional import strategy:
// - On Web (no FFI support): use stub implementation
// - On platforms with FFI (Android/iOS/macOS/Linux/Windows): import FFI file
//
// Note: The FFI implementation internally checks Platform.isWindows and falls
// back to stub on non-Windows platforms. This defensive approach ensures the
// code compiles on all platforms while only using Windows-specific APIs
// (winmm.dll) on Windows.
//
// In production, WindowsAudioService is only instantiated on Windows
// (see audioServiceProvider in lib/app/providers.dart), so the FFI
// implementation will only be used on Windows despite being compiled on
// other FFI-capable platforms.
import 'windows_wav_player_stub.dart'
    if (dart.library.ffi) 'windows_wav_player_ffi.dart';

WindowsWavPlayer createWindowsWavPlayer() => createWindowsWavPlayerImpl();
