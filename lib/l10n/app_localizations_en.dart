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
}
