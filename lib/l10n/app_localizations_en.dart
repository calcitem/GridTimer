// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GridTimer';

  @override
  String get timerIdle => 'Idle';

  @override
  String get timerRunning => 'Running';

  @override
  String get timerPaused => 'Paused';

  @override
  String get timerRinging => 'RINGING';

  @override
  String get confirmStartTitle => 'Confirm Start?';

  @override
  String confirmStartBody(String name) {
    return 'Other timers are running. Continue to start $name?';
  }

  @override
  String get actionStart => 'Start';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get timerActions => 'Timer Actions';

  @override
  String get stopAlarm => 'Stop Alarm';

  @override
  String timeUpTts(String name) {
    return '$name time is up';
  }

  @override
  String get permissionNotificationTitle => 'Enable Notifications';

  @override
  String get permissionNotificationBody =>
      'To receive timer alerts, please enable notifications.';

  @override
  String get permissionExactAlarmTitle => 'Enable Exact Alarms';

  @override
  String get permissionExactAlarmBody =>
      'For precise timer alerts, please enable \'Alarms & reminders\' permission.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get later => 'Later';

  @override
  String get minutes => 'minutes';

  @override
  String get remainingSeconds => 'seconds left';

  @override
  String get pausing => 'Paused';

  @override
  String get timeUp => 'Time\'s Up';

  @override
  String get clickToStop => 'Click to stop';

  @override
  String get settings => 'Settings';

  @override
  String get appInformation => 'App Information';

  @override
  String get version => 'Version';

  @override
  String get timerSettings => 'Timer Settings';

  @override
  String get soundSettings => 'Sound Settings';

  @override
  String get soundSettingsDesc => 'Configure alarm sound';

  @override
  String get ttsSettings => 'TTS Settings';

  @override
  String get ttsSettingsDesc => 'Configure voice announcements';

  @override
  String get languageSettings => 'Language';

  @override
  String get languageSettingsDesc => 'Choose app language';

  @override
  String get permissions => 'Permissions';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get notificationPermissionDesc => 'Allow timer notifications';

  @override
  String get about => 'About';

  @override
  String get license => 'License';

  @override
  String get licenseDesc => 'View open source licenses';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChineseSimplified => '简体中文';

  @override
  String errorText(String error) {
    return 'Error: $error';
  }

  @override
  String get confirmStart =>
      'Other timers are running. Continue to start this timer?';

  @override
  String get flashAnimation => 'Flash Animation';

  @override
  String get flashAnimationDesc => 'Red flash when timer rings';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationDesc => 'Vibrate when timer rings';

  @override
  String get keepScreenOn => 'Keep Screen On';

  @override
  String get keepScreenOnDesc =>
      'Prevent screen from sleeping while timer runs';

  @override
  String get ttsEnabled => 'Voice Announcements';

  @override
  String get ttsEnabledDesc => 'Announce timer completion with voice';

  @override
  String get alarmSound => 'Alarm Sound';

  @override
  String get alarmSoundDesc => 'Choose sound for timer alerts';

  @override
  String get volume => 'Volume';

  @override
  String get volumeDesc => 'Adjust alarm volume';

  @override
  String get ttsLanguage => 'TTS Language';

  @override
  String get ttsLanguageDesc => 'Choose voice announcement language';

  @override
  String get testSound => 'Test Sound';

  @override
  String get testTts => 'Test Voice';

  @override
  String get gridDurationsSettings => 'Grid Durations Settings';

  @override
  String get gridDurationsSettingsDesc =>
      'Customize duration for each grid cell';

  @override
  String gridSlot(int index) {
    return 'Grid $index';
  }

  @override
  String get seconds => 'seconds';

  @override
  String get hours => 'hours';

  @override
  String get save => 'Save';

  @override
  String get reset => 'Reset';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get gridDurationsResetConfirm =>
      'Are you sure you want to reset grid durations to default values?';

  @override
  String get audioPlaybackSettings => 'Audio Playback Settings';

  @override
  String get audioPlaybackSettingsDesc => 'Configure alarm audio playback mode';

  @override
  String get audioPlaybackMode => 'Playback Mode';

  @override
  String get audioPlaybackModeLoopIndefinitely =>
      'Loop indefinitely until manually stopped';

  @override
  String get audioPlaybackModeLoopForDuration =>
      'Loop for N minutes then auto-stop';

  @override
  String get audioPlaybackModeLoopWithInterval =>
      'Loop N min, pause M min, loop N min (once)';

  @override
  String get audioPlaybackModeLoopWithIntervalRepeating =>
      'Loop N min, pause M min, repeat until stopped';

  @override
  String get audioPlaybackModePlayOnce => 'Play once only';

  @override
  String get loopDuration => 'Loop Duration';

  @override
  String get intervalPause => 'Interval Pause Duration';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get customAudio => 'Custom Alarm Sound';

  @override
  String get customAudioDesc =>
      'Upload your own audio file as alarm sound (supports MP3, WAV, etc.)';

  @override
  String get uploadCustomAudio => 'Upload Audio File';

  @override
  String get changeCustomAudio => 'Change Audio File';

  @override
  String get clearCustomAudio => 'Clear';

  @override
  String get customAudioActive => 'Currently using custom audio';

  @override
  String get customAudioSelected => 'Custom audio has been set';

  @override
  String get customAudioCleared => 'Restored to default sound';

  @override
  String get gestureSettings => 'Gesture Control Settings';

  @override
  String get gestureSettingsDesc =>
      'Configure gesture actions when alarm rings';

  @override
  String get gestureActions => 'Gesture Actions';

  @override
  String get gestureTypeScreenTap => 'Tap Screen';

  @override
  String get gestureTypeVolumeUp => 'Volume+ Button';

  @override
  String get gestureTypeVolumeDown => 'Volume- Button';

  @override
  String get gestureTypeShake => 'Shake Phone';

  @override
  String get gestureTypeFlip => 'Flip Phone (Face Down)';

  @override
  String get gestureActionStopAndReset => 'Stop & Reset';

  @override
  String get gestureActionPause => 'Pause';

  @override
  String get gestureActionNone => 'No Action';

  @override
  String get shakeSensitivity => 'Shake Sensitivity';

  @override
  String get shakeSensitivityLow => 'Low (Shake hard)';

  @override
  String get shakeSensitivityHigh => 'High (Shake gently)';

  @override
  String get shakeSensitivityDesc => 'Adjust shake detection sensitivity';

  @override
  String get gestureHint =>
      'Senior-friendly: Enable screen tap, volume buttons, and flip phone';

  @override
  String get onboardingCheckSoundTitle => 'Important: Check Sound';

  @override
  String get onboardingCheckSoundDesc =>
      'Please check if \'Timer Alarm (default)\' sound is NOT \'None\' or \'Silent\'.\n\nIf silent, you will only receive a notification without sound when time is up.';

  @override
  String get onboardingCheckSoundBtn => 'Check Sound Settings';
}
