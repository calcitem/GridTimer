# 锁屏音频播放修复

## 问题描述

在设备锁屏时，计时器到时间后无法发声提醒。

## 问题原因

1. **应用音频播放受限**：当设备锁屏时，应用处于后台状态，`AudioPlayer` 播放可能被系统限制或暂停
2. **缺少即时通知**：虽然应用已配置通知系统，但在计时器响铃时只调用了应用内音频播放，没有显示即时通知
3. **音频上下文未配置**：`AudioPlayer` 没有设置正确的音频上下文，系统不知道这是闹钟类型的音频

## 解决方案

### 1. 添加即时通知显示

**修改文件**：
- `lib/core/domain/services/i_notification_service.dart`
- `lib/infrastructure/notification_service.dart`
- `lib/infrastructure/timer_service.dart`

**关键改动**：
- 在 `INotificationService` 接口中添加 `showTimeUpNow()` 方法
- 在 `NotificationService` 中实现该方法，创建高优先级即时通知
- 在计时器响铃时（`_triggerRingingAsync` 和 `handleTimeUpEvent`）调用该方法

**工作原理**：
当计时器到时间时，除了应用内音频播放外，还会立即显示一个高优先级的 Android 通知。通知系统会播放配置的通知声音，即使设备锁屏也能正常发声。

### 2. 配置音频上下文

**修改文件**：
- `lib/infrastructure/audio_service.dart`

**关键改动**：
```dart
await _player.setAudioContext(
  AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  ),
);
```

**参数说明**：
- `stayAwake: true` - 保持设备唤醒
- `contentType: AndroidContentType.sonification` - 音频内容类型为通知/提示音
- `usageType: AndroidUsageType.alarm` - 音频用途为闹钟，确保高优先级
- `audioFocus: AndroidAudioFocus.gain` - 获取音频焦点，可以中断其他音频

## 技术细节

### 双重保障机制

1. **应用层音频播放**（AudioPlayer）
   - 当应用在前台时，提供流畅的音频播放体验
   - 支持循环播放和音量控制
   - 通过音频上下文配置确保优先级

2. **系统层通知声音**（Notification Sound）
   - 当设备锁屏或应用在后台时，确保声音能够播放
   - 利用系统的闹钟通知通道，优先级最高
   - 配合 `fullScreenIntent: true` 可以在锁屏时唤醒屏幕

### 通知配置

```dart
AndroidNotificationDetails(
  channelId,
  'Timer Alarm',
  channelDescription: 'Time up notification',
  importance: Importance.max,        // 最高重要性
  priority: Priority.max,            // 最高优先级
  category: AndroidNotificationCategory.alarm,  // 闹钟类别
  visibility: NotificationVisibility.public,    // 锁屏可见
  fullScreenIntent: true,            // 全屏提醒
  playSound: true,                   // 播放声音
  enableVibration: true,             // 启用振动
)
```

## 测试建议

1. **锁屏测试**：
   - 启动一个短时计时器（如 10 秒）
   - 锁定设备屏幕
   - 等待计时器到时间
   - 验证：应该听到提示音并看到通知

2. **后台测试**：
   - 启动计时器
   - 切换到其他应用
   - 等待计时器到时间
   - 验证：应该听到提示音并收到通知

3. **前台测试**：
   - 启动计时器
   - 保持应用在前台
   - 等待计时器到时间
   - 验证：应该听到提示音并看到应用内响铃状态

## Android 权限要求

应用已在 `AndroidManifest.xml` 中配置了必要权限：

```xml
<!-- 通知权限（Android 13+） -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- 精确闹钟权限 -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<!-- 全屏提醒权限 -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>

<!-- 振动权限 -->
<uses-permission android:name="android.permission.VIBRATE"/>
```

MainActivity 配置：
```xml
android:showWhenLocked="true"
android:turnScreenOn="true"
```

## 权限请求功能

### 应用启动时自动请求

在 `lib/main.dart` 的初始化流程中，应用会自动请求必要权限：

1. **通知权限**（Android 13+）：会弹出系统权限对话框
2. **精确闹钟权限**（Android 14+）：会尝试打开系统设置页面

### 设置页面手动请求

在"设置 > 权限"部分，用户可以：

1. **通知权限**：点击"授予权限"按钮直接请求
2. **精确闹钟权限**：点击"设置"按钮打开系统设置
3. **电池优化设置**：点击"设置"按钮关闭电池优化

## 相关文件

- `lib/main.dart` - 应用入口，初始化时请求权限
- `lib/presentation/pages/settings_page.dart` - 设置页面，权限管理
- `lib/core/domain/services/i_notification_service.dart` - 通知服务接口
- `lib/infrastructure/notification_service.dart` - 通知服务实现
- `lib/infrastructure/audio_service.dart` - 音频服务实现
- `lib/infrastructure/timer_service.dart` - 计时器服务实现
- `lib/infrastructure/permission_service.dart` - 权限服务实现
- `android/app/src/main/AndroidManifest.xml` - Android 权限配置

## 注意事项

1. **电池优化**：部分手机厂商的系统可能会限制后台应用，建议用户在设置中关闭应用的电池优化
2. **勿扰模式**：如果用户开启了勿扰模式，闹钟通知可能受到影响，需要将应用设置为勿扰模式例外
3. **通知权限**：Android 13+ 需要用户授予通知权限，应用已在启动时请求该权限
4. **精确闹钟权限**：Android 14+ 默认拒绝精确闹钟权限，应用会降级使用非精确模式，建议引导用户授权

## 修复版本

- **修复日期**：2025-12-31
- **影响版本**：1.0.0+
- **修复类型**：功能增强 + Bug 修复

