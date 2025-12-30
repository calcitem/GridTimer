# 无声音问题诊断指南

## 🎯 问题描述

无论锁屏与否，计时器到时间都没有声音。

## 🔍 可能的原因

### 1. 音频文件问题
- ✅ 文件存在：`assets/sounds/sound.wav` (486KB)
- ✅ Android 资源：`android/app/src/main/res/raw/sound.wav` (486KB)
- ❓ 文件是否损坏或格式不兼容

### 2. 通知通道问题
- ❓ 旧的 v1 通道还在设备上（没有声音配置）
- ❓ v2 通道未正确创建

### 3. 系统设置问题
- ❓ 手机音量为 0
- ❓ 勿扰模式开启
- ❓ 通知通道被手动静音

### 4. 权限问题
- ❓ 通知权限未授予
- ❓ 应用通知被系统禁用

## 🛠️ 诊断步骤

### 步骤 1: 检查音频文件

```bash
# 在项目根目录运行
cd android/app/src/main/res/raw/

# 查看文件信息
file sound.wav

# 播放测试（Linux/Mac）
aplay sound.wav  # 或 afplay sound.wav (Mac)

# Windows 可以直接双击文件试听
```

**预期**：应该能听到声音

### 步骤 2: 完全卸载并重装

**非常重要**：必须完全卸载旧版本

```bash
# 卸载应用（包括数据）
adb uninstall com.gridtimer.app

# 清理 Flutter 构建缓存
flutter clean

# 重新安装
flutter run
```

### 步骤 3: 检查通知通道

```bash
# 重装后运行应用，然后检查通知通道
adb shell cmd notification list_channels com.gridtimer.app
```

**预期输出**：
```
gt.alarm.timeup.default.v2:
  sound=content://media/internal/audio/media/XXX
  importance=max
  vibration=true
```

**关键点**：
- 应该看到 `v2` 通道（不是 v1）
- `sound` 应该有值（不是 null）
- `importance` 应该是 `max`

**如果看到 v1 通道**：说明卸载不彻底，需要：
```bash
# 强制清除应用数据
adb shell pm clear com.gridtimer.app
# 然后卸载
adb uninstall com.gridtimer.app
```

### 步骤 4: 检查系统音量

在手机上：
1. 按音量键，检查**媒体音量**
2. 设置 → 声音 → 检查**通知音量**
3. 确认没有开启**勿扰模式**

### 步骤 5: 检查应用通知设置

在手机上：
```
设置 → 应用 → GridTimer → 通知 →
1. 确认"显示通知"已开启
2. 点击"Timer Alarm (default)"
3. 确认"声音"已开启
4. 确认"振动"已开启
```

### 步骤 6: 查看实时日志

```bash
# 启动应用
flutter run

# 在另一个终端查看日志
adb logcat | grep -E "Audio|notification|alarm|sound"
```

启动一个10秒计时器，观察日志输出。

**应该看到类似日志**：
```
AudioService: Playing sound: sounds/sound.wav
AudioPlayer: setSource: AssetSource(sounds/sound.wav)
NotificationService: Showing notification for timer
```

**如果看到错误**：
```
AudioPlayer: Error loading asset
PlatformException: Unable to load asset
```
说明音频文件加载失败。

## 🧪 快速测试方法

### 测试 A: 应用内音频播放

创建一个测试按钮来直接测试音频播放：

在 `lib/presentation/pages/sound_settings_page.dart` 中，找到预览按钮部分，确认它能正常工作。

### 测试 B: 通知声音

在设置页面添加测试通知按钮（临时调试用）：

```dart
ElevatedButton(
  onPressed: () async {
    final notificationService = ref.read(notificationServiceProvider);
    // 创建测试 session 和 config
    final testSession = TimerSession(
      timerId: 'test:0',
      modeId: 'default',
      slotIndex: 0,
      status: TimerStatus.ringing,
      lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    final grid = await ref.read(timerServiceProvider).getSnapshot();
    final testConfig = grid.$1.slots[0];
    
    await notificationService.showTimeUpNow(
      session: testSession,
      config: testConfig,
    );
  },
  child: Text('测试通知声音'),
)
```

点击按钮后：
- ✅ 应该看到通知
- ✅ 应该听到声音
- ✅ 应该有振动

## 🔧 常见问题解决方案

### 问题 1: AudioPlayer 错误

**症状**：日志显示 `Audio playback error`

**解决方案**：
1. 检查 `pubspec.yaml` 中的 assets 配置
2. 运行 `flutter clean && flutter pub get`
3. 确认文件路径大小写正确（Linux 区分大小写）

### 问题 2: 通知显示但无声音

**症状**：通知出现，但没有声音

**原因**：通知通道的声音配置问题

**解决方案**：
```bash
# 1. 完全卸载
adb uninstall com.gridtimer.app

# 2. 检查是否卸载干净
adb shell pm list packages | grep gridtimer
# 应该没有输出

# 3. 重新安装
flutter run
```

### 问题 3: 声音文件无法播放

**症状**：文件存在但播放失败

**可能原因**：
- WAV 文件编码格式不兼容
- 文件损坏

**解决方案**：
```bash
# 使用 FFmpeg 重新编码为标准格式
ffmpeg -i assets/sounds/sound.wav -acodec pcm_s16le -ar 44100 assets/sounds/sound_new.wav

# 替换文件
mv assets/sounds/sound_new.wav assets/sounds/sound.wav

# 同步到 Android 资源
cp assets/sounds/sound.wav android/app/src/main/res/raw/sound.wav
```

### 问题 4: 权限被拒绝

**检查**：
```bash
adb shell dumpsys notification | grep gridtimer
```

如果看到 `blocked` 或 `banned`，说明通知被系统禁用。

**解决方案**：
```
设置 → 应用 → GridTimer → 通知 → 启用
```

## 📱 设备特定问题

### 小米手机

小米系统可能额外限制通知声音。

**解决方案**：
1. 安全中心 → 权限管理 → GridTimer → 显示通知 → 允许
2. 设置 → 通知 → GridTimer → 锁屏通知 → 允许
3. 设置 → 声音和振动 → 勿扰模式 → 允许例外 → GridTimer

### 华为手机

**解决方案**：
1. 设置 → 通知 → GridTimer → 允许通知
2. 设置 → 通知 → GridTimer → 横幅 → 允许
3. 设置 → 通知 → GridTimer → 锁屏 → 显示

### OPPO/vivo

**解决方案**：
1. 设置 → 通知与状态栏 → 通知管理 → GridTimer
2. 允许通知 + 锁屏显示 + 横幅

## 🎯 必做检查清单

在报告问题之前，请确认以下所有项：

- [ ] 已完全卸载旧版本（`adb uninstall com.gridtimer.app`）
- [ ] 已清理构建缓存（`flutter clean`）
- [ ] 已重新安装应用
- [ ] 已授予通知权限
- [ ] 手机媒体音量 > 0
- [ ] 手机通知音量 > 0
- [ ] 未开启勿扰模式
- [ ] 通知通道是 v2（不是 v1）
- [ ] 通知通道的声音已启用
- [ ] 前台测试也没有声音（排除锁屏问题）

## 📊 诊断报告模板

如果上述所有步骤都尝试后仍无声音，请提供以下信息：

```
【设备信息】
- 手机型号：
- Android 版本：
- 系统 UI：（原生/MIUI/EMUI/ColorOS 等）

【操作记录】
- [ ] 已完全卸载重装
- [ ] 已授予通知权限
- [ ] 已检查音量设置
- [ ] 已检查勿扰模式

【通知通道信息】
（粘贴 `adb shell cmd notification list_channels` 的输出）

【日志信息】
（粘贴计时器到时间时的 logcat 日志）

【测试结果】
- 前台测试有声音吗？ 是/否
- 后台测试有声音吗？ 是/否
- 锁屏测试有声音吗？ 是/否
- 手动播放 sound.wav 文件有声音吗？ 是/否
```

## 💡 调试技巧

### 技巧 1: 使用系统声音测试

临时修改代码使用系统默认声音：

```dart
// 在 lib/infrastructure/notification_service.dart
final channel = AndroidNotificationChannel(
  channelId,
  'Timer Alarm ($soundKey)',
  description: 'Time up notifications for $soundKey ringtone',
  importance: Importance.max,
  playSound: true,
  // 注释掉自定义声音，使用系统默认
  // sound: RawResourceAndroidNotificationSound(soundResource),
  enableVibration: true,
  groupId: _channelGroupId,
);
```

如果系统默认声音能播放，说明是自定义音频文件的问题。

### 技巧 2: 简化测试

创建最小可复现示例：

```dart
// 在 main.dart 添加测试按钮
FloatingActionButton(
  onPressed: () async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/sound.wav'));
  },
  child: Icon(Icons.play_arrow),
)
```

点击后应该听到声音。

### 技巧 3: 检查打包文件

```bash
# 构建 APK
flutter build apk

# 解压 APK 检查资源
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep sound

# 应该看到：
# assets/flutter_assets/assets/sounds/sound.wav
```

## ✅ 成功标志

修复成功后，应该满足：

1. ✅ 前台：计时器到时间听到声音
2. ✅ 后台：计时器到时间听到声音
3. ✅ 锁屏：计时器到时间听到声音 + 看到通知
4. ✅ 振动：所有场景都有振动反馈
5. ✅ 日志：无错误信息

