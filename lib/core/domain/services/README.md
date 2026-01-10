# Service Interfaces - Platform Compatibility Guide

This directory contains service interfaces that abstract platform-specific functionality following Clean Architecture principles.

## Audio Services - Cross-Platform Strategy

The audio service implementation varies by platform for optimal reliability and performance:

### Platform Implementations

| Platform | Implementation | Plugin/API | Notes |
|----------|----------------|------------|-------|
| **Windows** | `WindowsAudioService` | FFI (winmm.dll) | Direct native calls avoid platform channel thread safety issues |
| **Linux** | `AudioService` | audioplayers | Works reliably; no AudioContext needed |
| **macOS** | `AudioService` | audioplayers | Works reliably; no AudioContext needed |
| **Android** | `AudioService` | audioplayers | With USAGE_ALARM AudioContext for reliable alarm playback |
| **iOS** | `AudioService` | audioplayers | With AVAudioSession playback category configuration |
| **Web** | `AudioService` | audioplayers | HTML5 audio backend |

### Key Design Decisions

#### Why Windows uses FFI instead of audioplayers?

The `audioplayers` plugin can crash on Windows when platform channel messages are sent from non-platform threads (common in alarm scenarios). The native `PlaySound` API via FFI is:
- More stable and thread-safe
- Sufficient for alarm-style WAV playback
- Lower overhead (no platform channel)

#### Why Linux/macOS use audioplayers?

Unlike Windows, the audioplayers plugin works reliably on Linux and macOS:
- No platform channel thread safety issues observed
- Supports multiple audio formats
- Well-maintained cross-platform support
- AudioContext is mobile-only and correctly skipped on desktop

### Service Interface

All implementations conform to `IAudioService`:

```dart
abstract interface class IAudioService {
  Future<void> init();
  Future<void> setVolume(double volume);
  Future<void> playLoop({required SoundKey soundKey, double volume = 1.0});
  Future<void> playWithMode({
    required SoundKey soundKey,
    required AudioPlaybackMode mode,
    double volume = 1.0,
    int loopDurationMinutes = 5,
    int intervalPauseMinutes = 2,
  });
  Future<void> stop();
  Future<bool> isPlaying();
}
```

## Other Platform-Specific Services

### Notification Service (`INotificationService`)
- **Supported**: Android, iOS
- **Not supported**: Windows, Linux, macOS desktop, Web
- Uses `flutter_local_notifications` plugin

### Vibration Service (`IVibrationService`)
- **Supported**: Android, iOS
- **Not supported**: Desktop platforms, Web
- Uses `vibration` plugin

### Alarm Volume Service (`IAlarmVolumeService`)
- **Android-only**: Uses native AlarmManager to boost alarm stream volume
- **Other platforms**: No-op (alarm volume boost not applicable)

### TTS Service (`ITtsService`)
- **Supported**: All platforms (Android, iOS, Windows, Linux, macOS, Web)
- **Platform-specific handling**: 
  - Windows: Completion callback may not fire reliably; uses fallback timeout
  - Desktop: `awaitSpeakCompletion` disabled on Windows for stability
- Uses `flutter_tts` plugin

## Testing Requirements

When making changes to platform-specific code:

1. **Windows**: Test on Windows 10+ with alarm scenarios
2. **Linux**: Test basic playback (volume, loop, stop)
3. **macOS**: Test basic playback (volume, loop, stop)
4. **Android**: Test on multiple OEM devices (especially MIUI, EMUI)
5. **iOS**: Test on physical device when possible
6. **Web**: Verify in modern browsers (Chrome, Firefox, Safari)

## See Also

- `lib/app/providers.dart` - Service provider configuration
- `lib/infrastructure/` - Platform-specific implementations
- Project README - Overall architecture and tech stack
