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

  @override
  String get minutes => '分钟';

  @override
  String get remainingSeconds => '剩余秒';

  @override
  String get pausing => '暂停中';

  @override
  String get timeUp => '时间到';

  @override
  String get clickToStop => '点击停止';

  @override
  String get settings => '设置';

  @override
  String get appInformation => '应用信息';

  @override
  String get version => '版本';

  @override
  String get timerSettings => '计时器设置';

  @override
  String get soundSettings => '声音设置';

  @override
  String get soundSettingsDesc => '配置提醒声音';

  @override
  String get ttsSettings => '语音播报设置';

  @override
  String get ttsSettingsDesc => '配置语音播报';

  @override
  String get languageSettings => '语言';

  @override
  String get languageSettingsDesc => '选择应用语言';

  @override
  String get permissions => '权限';

  @override
  String get notificationPermission => '通知权限';

  @override
  String get notificationPermissionDesc => '允许计时器通知';

  @override
  String get about => '关于';

  @override
  String get license => '开源许可';

  @override
  String get licenseDesc => '查看开源许可证';

  @override
  String get comingSoon => '即将推出';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChineseSimplified => '简体中文';

  @override
  String errorText(String error) {
    return '错误：$error';
  }

  @override
  String get confirmStart => '当前已有计时器在运行。要继续启动此计时器吗？';

  @override
  String get flashAnimation => '闪烁动画';

  @override
  String get flashAnimationDesc => '响铃时红色闪烁';

  @override
  String get vibration => '振动';

  @override
  String get vibrationDesc => '响铃时振动';

  @override
  String get keepScreenOn => '保持屏幕常亮';

  @override
  String get keepScreenOnDesc => '计时器运行时防止屏幕休眠';

  @override
  String get ttsEnabled => '语音播报';

  @override
  String get ttsEnabledDesc => '计时结束时语音播报';

  @override
  String get alarmSound => '提醒声音';

  @override
  String get alarmSoundDesc => '选择计时器提醒声音';

  @override
  String get volume => '音量';

  @override
  String get volumeDesc => '调整提醒音量';

  @override
  String get ttsLanguage => '语音播报语言';

  @override
  String get ttsLanguageDesc => '选择语音播报语言';

  @override
  String get testSound => '测试声音';

  @override
  String get testTts => '测试语音';

  @override
  String get gridDurationsSettings => '九宫格时长配置';

  @override
  String get gridDurationsSettingsDesc => '自定义每个宫格的倒计时长';

  @override
  String gridSlot(int index) {
    return '宫格 $index';
  }

  @override
  String get seconds => '秒';

  @override
  String get hours => '小时';

  @override
  String get save => '保存';

  @override
  String get reset => '重置';

  @override
  String get resetToDefault => '恢复默认';

  @override
  String get gridDurationsResetConfirm => '确定要将九宫格时长恢复为默认值吗？';

  @override
  String get audioPlaybackSettings => '音频播放设置';

  @override
  String get audioPlaybackSettingsDesc => '配置闹铃音频播放模式';

  @override
  String get audioPlaybackMode => '播放模式';

  @override
  String get audioPlaybackModeLoopIndefinitely => '一直循环直到手动停止';

  @override
  String get audioPlaybackModeLoopForDuration => '循环播放 N 分钟后自动停止';

  @override
  String get audioPlaybackModeLoopWithInterval =>
      '循环 N 分钟，间隔 M 分钟，再循环 N 分钟（共一次）';

  @override
  String get audioPlaybackModeLoopWithIntervalRepeating =>
      '循环 N 分钟，间隔 M 分钟，重复直到停止';

  @override
  String get audioPlaybackModePlayOnce => '只播放一次';

  @override
  String get loopDuration => '循环时长';

  @override
  String get intervalPause => '间隔暂停时长';

  @override
  String get minutesUnit => '分钟';
}
