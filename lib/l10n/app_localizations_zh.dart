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

  @override
  String get customAudio => '自定义闹铃声音';

  @override
  String get customAudioDesc => '上传自己的音频文件作为闹铃声音（支持 MP3、WAV 等格式）';

  @override
  String get uploadCustomAudio => '上传音频文件';

  @override
  String get changeCustomAudio => '更换音频文件';

  @override
  String get clearCustomAudio => '清除';

  @override
  String get customAudioActive => '当前使用自定义音频';

  @override
  String get customAudioSelected => '自定义音频已设置';

  @override
  String get customAudioCleared => '已恢复使用默认声音';

  @override
  String get gestureSettings => '手势控制设置';

  @override
  String get gestureSettingsDesc => '配置闹铃响起时的手势操作';

  @override
  String get gestureActions => '手势动作';

  @override
  String get gestureTypeScreenTap => '触摸屏幕';

  @override
  String get gestureTypeVolumeUp => '音量+ 键';

  @override
  String get gestureTypeVolumeDown => '音量- 键';

  @override
  String get gestureTypeShake => '摇晃手机';

  @override
  String get gestureTypeFlip => '翻转手机（屏幕朝下）';

  @override
  String get gestureActionStopAndReset => '停止并重置';

  @override
  String get gestureActionPause => '暂停';

  @override
  String get gestureActionNone => '无动作';

  @override
  String get shakeSensitivity => '摇晃灵敏度';

  @override
  String get shakeSensitivityLow => '低（需要用力摇）';

  @override
  String get shakeSensitivityHigh => '高（轻轻摇即可）';

  @override
  String get shakeSensitivityDesc => '调整摇晃手机的灵敏度';

  @override
  String get gestureHint => '长辈友好：建议开启触摸屏幕、音量键和翻转手机';

  @override
  String get onboardingCheckSoundTitle => '重要：检查声音';

  @override
  String get onboardingCheckSoundDesc =>
      '请点击下方按钮，确保 \"Timer Alarm (default)\" 的声音**不是**\'无\'或\'静音\'。\n\n如果设为静音，倒计时结束时您将只收到通知而听不到铃声。';

  @override
  String get onboardingCheckSoundBtn => '去检查声音设置';

  @override
  String get grantPermission => '授予权限';

  @override
  String get notificationPermissionGranted => '通知权限已授予';

  @override
  String get notificationPermissionDenied => '通知权限被拒绝，请在系统设置中手动授予';

  @override
  String get exactAlarmPermission => '精确闹钟权限';

  @override
  String get exactAlarmPermissionDesc => '确保计时器准时通知（Android 14+ 必需）';

  @override
  String get batteryOptimizationSettings => '电池优化设置';

  @override
  String get batteryOptimizationDesc => '禁用电池优化以确保后台闹钟可靠运行';

  @override
  String get alarmSoundSettings => '闹铃声音设置';

  @override
  String get alarmSoundSettingsDesc =>
      '如果 \"Timer Alarm (default)\" 声音设为\'无\'，计时器将只显示通知而无声音';

  @override
  String get goToSettings => '前往设置';

  @override
  String get settingsButton => '设置';

  @override
  String failedToOpenChannelSettings(String error) {
    return '打开通知渠道设置失败：$error';
  }

  @override
  String get developerModeEnabled => '开发者模式已启用';

  @override
  String get developerModeDisabled => '开发者模式已禁用';
}
