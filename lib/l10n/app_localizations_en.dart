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
}
