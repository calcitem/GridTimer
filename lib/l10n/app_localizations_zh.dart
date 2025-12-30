// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '九宫格计时器';

  @override
  String get timerIdle => '待机';

  @override
  String get timerRunning => '运行中';

  @override
  String get timerPaused => '已暂停';

  @override
  String get timerRinging => '响铃中';

  @override
  String get confirmStartTitle => '确认启动？';

  @override
  String confirmStartBody(String name) {
    return '当前已有计时器在运行。要继续启动 $name 吗？';
  }

  @override
  String get actionStart => '启动';

  @override
  String get actionPause => '暂停';

  @override
  String get actionResume => '继续';

  @override
  String get actionReset => '重置';

  @override
  String get actionStop => '停止';

  @override
  String get actionCancel => '取消';

  @override
  String get timerActions => '计时器操作';

  @override
  String get stopAlarm => '停止提醒';

  @override
  String timeUpTts(String name) {
    return '$name 时间到了';
  }

  @override
  String get permissionNotificationTitle => '开启通知';

  @override
  String get permissionNotificationBody => '为了接收计时器提醒，请开启通知权限。';

  @override
  String get permissionExactAlarmTitle => '开启精确提醒';

  @override
  String get permissionExactAlarmBody => '为确保准时提醒，请开启“闹钟和提醒”权限。';

  @override
  String get openSettings => '打开设置';

  @override
  String get later => '稍后';
}
