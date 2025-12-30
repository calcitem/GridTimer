# 锁屏提醒问题修复总结

## 🎯 问题描述

已经授予通知和闹钟权限，但锁屏状态下计时器到时间还是不会提醒。

## 🔍 根本原因

1. **通知配置不完整**：预先安排的通知（`scheduleTimeUp`）没有明确设置 `playSound` 和 `enableVibration`
2. **通知通道无法更新**：Android 限制，通知通道一旦创建，声音配置无法通过代码更改
3. **需要重新创建通道**：必须使用新的通道 ID 或卸载重装应用

## ✅ 已完成的修复

### 1. 更新通知通道版本

**文件**：`lib/infrastructure/notification_service.dart`

```dart
// 从 v1 升级到 v2
final channelId = 'gt.alarm.timeup.$soundKey.v2';
```

**原因**：强制创建新的通知通道，应用新的声音配置

### 2. 明确设置通知属性

**文件**：`lib/infrastructure/notification_service.dart`

在 `scheduleTimeUp` 方法中：

```dart
final androidDetails = AndroidNotificationDetails(
  channelId,
  'Timer Alarm',
  channelDescription: 'Time up notification',
  importance: Importance.max,
  priority: Priority.max,
  category: AndroidNotificationCategory.alarm,
  visibility: NotificationVisibility.public,
  fullScreenIntent: true,
  // 🆕 明确设置播放声音和振动
  playSound: true,
  enableVibration: true,
  // 🆕 设置通知行为
  ongoing: false,
  autoCancel: false,
  actions: [
    const AndroidNotificationAction(
      _actionIdStop,
      'Stop',
      showsUserInterface: true,
    ),
  ],
);
```

### 3. 同步更新即时通知

在 `showTimeUpNow` 方法中也使用 v2 通道，确保前台和后台的通知使用相同配置。

## 📋 修改的文件

1. ✅ `lib/infrastructure/notification_service.dart`
   - 更新通道版本：v1 → v2
   - 添加 `playSound: true`
   - 添加 `enableVibration: true`
   - 添加 `ongoing: false, autoCancel: false`

## ⚠️ 关键步骤：必须卸载重装

由于 Android 的限制，**旧的 v1 通知通道仍然存在于设备上，会阻止 v2 通道生效**。

### 必须执行以下操作：

```bash
# 步骤 1: 卸载旧版本（包括数据）
adb uninstall com.gridtimer.app

# 步骤 2: 清理构建缓存
flutter clean

# 步骤 3: 重新构建并安装
flutter run
```

### 或者手动操作：

1. 在手机上长按应用图标
2. 选择"卸载"
3. 确认卸载（会删除所有数据）
4. 重新从 Android Studio/VSCode 运行应用

## 🧪 测试步骤（简化版）

### 1. 卸载并重装应用

```bash
adb uninstall com.gridtimer.app
flutter run
```

### 2. 授予权限

- 允许通知权限（自动弹出）
- （可选）在设置中授予精确闹钟权限

### 3. 测试锁屏提醒

1. 启动一个 **10 秒**计时器
2. **立即锁定屏幕**（按电源键）
3. 等待 10 秒
4. **应该听到提示音！**

## 🔊 工作原理

### 锁屏时的声音来源

当设备锁屏时，计时器到时间后：

```
系统触发预先安排的通知
    ↓
使用 v2 通知通道配置
    ↓
通道配置了声音：sound.wav
    ↓
系统播放通知声音（不依赖应用是否在前台）
    ↓
同时显示锁屏通知 + 振动
```

**关键**：声音由**系统通知系统**播放，不是应用内的 `AudioPlayer`。这样即使应用在后台被暂停，声音也能正常播放。

### 双重保障

1. **应用在前台时**：
   - `AudioPlayer` 播放应用内音频（可循环）
   - `showTimeUpNow()` 显示即时通知（带声音）

2. **应用在后台/锁屏时**：
   - 预先安排的通知触发（`scheduleTimeUp`）
   - 系统播放通知通道配置的声音
   - 显示锁屏通知

## 📊 通知通道配置验证

### 卸载重装后，检查新通道：

```bash
adb shell cmd notification list_channels com.gridtimer.app
```

**应该看到**：
```
gt.alarm.timeup.default.v2:    ← 注意是 v2
  sound=content://...sound.wav  ← 有声音配置
  importance=max                ← 最高优先级
  vibration=true                ← 振动已开启
```

**不应该看到 v1 通道**（如果卸载干净了）

### 如果还看到 v1 通道：

说明卸载不彻底，需要：

```bash
# 完全卸载包括数据
adb uninstall com.gridtimer.app

# 或者清除设备上的所有应用数据
adb shell pm clear com.gridtimer.app
```

## 💡 如果测试失败

### 检查清单

1. ✅ 确认已卸载旧版本重新安装
2. ✅ 确认通知权限已授予
3. ✅ 确认手机音量未静音
4. ✅ 确认没有开启勿扰模式
5. ✅ 前台测试是否有声音（对照组）
6. ✅ 检查通知通道是否为 v2

### 查看实时日志

```bash
# 启动应用并查看日志
adb logcat | grep -E "notification|audio|alarm"
```

当计时器到时间时，应该看到类似日志：
```
NotificationManager: Posting notification ...
AudioFlinger: Playing sound for notification
```

## 🎉 预期结果

完成上述步骤后：

1. ✅ 前台时计时器到时间：应用内音频 + 通知声音（双重声音）
2. ✅ 后台时计时器到时间：通知声音 + 通知显示
3. ✅ **锁屏时计时器到时间：通知声音 + 锁屏通知显示 + 振动**
4. ✅ 所有场景下都能听到提示音

## 📞 如果还是不行

请提供以下信息以便进一步诊断：

1. 手机型号和 Android 版本
2. 是否已经完全卸载重装
3. 前台测试是否有声音
4. `adb shell cmd notification list_channels` 的输出
5. logcat 日志（特别是计时器到时间时）

我会根据这些信息提供更具体的解决方案。

## 📝 相关文档

- `LOCKSCREEN_TEST_GUIDE.md` - 详细测试指南
- `LOCKSCREEN_AUDIO_FIX.md` - 技术实现说明
- `PERMISSION_REQUEST_IMPLEMENTATION.md` - 权限请求功能说明

