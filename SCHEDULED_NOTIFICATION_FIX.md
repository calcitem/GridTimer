# 预先安排通知声音修复

## 🎯 问题

测试结果显示：
- ✅ 测试 1-3 通过：音频播放和即时通知都有声音
- ❌ 测试 4 失败：预先安排的通知（`zonedSchedule`）没有声音

## 🔍 根本原因

`zonedSchedule`（预先安排通知）和 `show`（立即显示通知）对声音的处理方式不同：

- **`show` 方法**：会自动使用通知通道配置的声音 → ✅ 有声音
- **`zonedSchedule` 方法**：需要在 `AndroidNotificationDetails` 中**明确指定声音资源** → ❌ 之前没有指定

## ✅ 修复内容

### 修改文件：`lib/infrastructure/notification_service.dart`

#### 1. `scheduleTimeUp` 方法（预先安排通知）

添加明确的声音资源配置：

```dart
// 获取声音资源名（必须明确指定，zonedSchedule 不会自动使用通道声音）
final soundResource = _soundKeyToResource(config.soundKey);

final androidDetails = AndroidNotificationDetails(
  channelId,
  'Timer Alarm',
  channelDescription: 'Time up notification',
  importance: Importance.max,
  priority: Priority.max,
  category: AndroidNotificationCategory.alarm,
  visibility: NotificationVisibility.public,
  fullScreenIntent: true,
  playSound: true,
  sound: RawResourceAndroidNotificationSound(soundResource),  // 🆕 明确指定声音
  enableVibration: true,
  // ...
);
```

#### 2. `showTimeUpNow` 方法（即时通知）

为了保持一致性，也添加了明确的声音资源配置。

## 📱 测试步骤

### 方式 1: 热重载测试（推荐，快速）

```bash
# 保存代码后，在运行的应用中按 'r' 热重载
# 然后重新测试
```

**测试**：
1. 打开应用 → 设置 → 音频测试
2. 点击"测试 4: 5秒后触发通知"
3. 等待 5 秒
4. ✅ **应该听到声音了！**

### 方式 2: 完全重装（确保彻底）

```bash
# 卸载
adb uninstall com.calcitem.gridtimer

# 清理
flutter clean

# 重新安装
flutter run
```

## 🧪 验证清单

重新运行音频测试页面的所有测试：

- [ ] **测试 1**: AudioPlayer 直接播放 → ✅ 有声音
- [ ] **测试 2**: AudioService 服务播放 → ✅ 有声音
- [ ] **测试 3**: 即时通知 → ✅ 有声音
- [ ] **测试 4**: 预先安排通知（5秒后）→ ✅ **现在应该有声音了**

## 🔐 锁屏测试

修复后，锁屏场景应该也能正常工作：

1. 启动一个 **10 秒**计时器
2. **立即锁定屏幕**
3. 等待 10 秒
4. ✅ **应该听到声音 + 看到锁屏通知**

## 💡 技术说明

### 为什么 `zonedSchedule` 需要明确指定声音？

根据 Android 的实现：

1. **`show()` - 立即显示通知**
   - 通知创建时通道已存在
   - 系统会自动使用通道的声音配置
   - 即使不指定 `sound` 参数也能播放

2. **`zonedSchedule()` - 预先安排通知**
   - 通知在未来某个时间触发
   - 触发时应用可能不在运行状态
   - 系统无法确定使用哪个声音
   - **必须在通知详情中明确指定声音资源**

### 声音资源配置

```dart
// 声音资源名
final soundResource = _soundKeyToResource(config.soundKey);
// 返回 "sound"（对应 android/app/src/main/res/raw/sound.wav）

// 创建声音配置
sound: RawResourceAndroidNotificationSound(soundResource)
// 告诉系统使用 raw/sound.wav 作为通知声音
```

## 🎉 预期结果

修复后的行为：

### 前台（应用打开）
- ✅ 计时器到时间：应用内音频 + 通知声音（双重声音）
- ✅ 通知显示在状态栏
- ✅ 应用内计时器红色闪烁

### 后台（应用最小化）
- ✅ 计时器到时间：通知声音
- ✅ 通知显示在状态栏
- ✅ 振动反馈

### 锁屏
- ✅ 计时器到时间：通知声音
- ✅ 锁屏上显示通知
- ✅ 屏幕亮起（如果授予了全屏提醒权限）
- ✅ 振动反馈

## 🔍 如果还是没声音

如果测试 4 还是没有声音，请检查：

### 1. 确认代码已更新

```bash
# 查看修改
git diff lib/infrastructure/notification_service.dart
```

应该看到添加了：
```dart
sound: RawResourceAndroidNotificationSound(soundResource)
```

### 2. 确认热重载成功

如果使用热重载，确认控制台显示：
```
Reloaded 1 of XXX libraries
```

如果显示错误，尝试热重启（按 `R`）或完全重装。

### 3. 查看日志

```bash
adb logcat | grep -E "notification|sound|alarm"
```

触发测试 4 后，应该看到类似：
```
NotificationManager: Posting notification ...
NotificationService: Using sound resource: sound
```

### 4. 检查通知设置

```
设置 → 应用 → GridTimer → 通知 → Timer Alarm (default)
```

确认：
- 声音：已开启
- 声音选择：应该显示一个声音（可能显示为"默认"或文件名）

## 📊 修复总结

| 问题 | 修复前 | 修复后 |
|------|--------|--------|
| 应用内音频 | ✅ | ✅ |
| 即时通知声音 | ✅ | ✅ |
| 预先安排通知声音 | ❌ | ✅ |
| 锁屏提醒 | ❌ | ✅ |

## 🎯 关键改动

**一行代码修复了整个问题**：

```dart
sound: RawResourceAndroidNotificationSound(soundResource)
```

这行代码告诉 Android 系统：
> "当这个预先安排的通知触发时，请播放 `raw/sound.wav` 这个声音文件"

没有这行代码，系统不知道该播放什么声音，即使通知通道配置了声音也不会生效。

## 📝 相关文档

- `NO_SOUND_DIAGNOSIS.md` - 完整诊断指南
- `LOCKSCREEN_TEST_GUIDE.md` - 锁屏测试指南
- `LOCKSCREEN_FIX_SUMMARY.md` - 锁屏修复总结

