# 锁屏提醒测试指南

## ⚠️ 重要提示

由于 Android 的限制，**通知通道一旦创建，其声音配置就无法通过代码更改**。因此：

1. ✅ 已将通知通道版本从 v1 升级到 v2
2. ✅ 添加了明确的 `playSound` 和 `enableVibration` 配置
3. ❗ **必须卸载旧版本应用后重新安装**

## 📱 完整测试步骤

### 步骤 1: 卸载旧版本

```bash
# 方法 1: 使用 ADB 卸载
adb uninstall com.calcitem.gridtimer

# 方法 2: 在手机上手动卸载
# 长按应用图标 → 卸载
```

### 步骤 2: 重新构建并安装

```bash
# 清理构建缓存
flutter clean

# 重新获取依赖
flutter pub get

# 构建并运行
flutter run

# 或者构建 APK 手动安装
flutter build apk
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 步骤 3: 授予权限

1. 打开应用
2. **应该立即弹出通知权限对话框** → 点击"允许"
3. 进入"设置"页面
4. 在"权限"部分：
   - 确认"通知权限"已授予
   - 点击"精确闹钟权限"旁的"设置"，在系统设置中授予
   - （推荐）点击"电池优化设置"，将应用设为"不优化"

### 步骤 4: 测试锁屏提醒

#### 测试 A: 短时计时器 + 锁屏

1. ✅ 在应用中启动一个 **10 秒**计时器
2. ✅ 观察计时器正在倒计时
3. ✅ **立即锁定屏幕**（按电源键）
4. ✅ 等待 10 秒
5. ✅ **预期结果**：
   - 应该听到提示音（sound.wav）
   - 屏幕应该亮起（如果授予了全屏提醒权限）
   - 锁屏上应该显示通知
   - 通知标题显示计时器名称
   - 通知有"Stop"按钮

#### 测试 B: 锁屏后启动计时器

1. ✅ 启动一个 10 秒计时器
2. ✅ 立即锁定屏幕
3. ✅ 等待 10 秒
4. ✅ **预期结果**：同测试 A

#### 测试 C: 长时间后台测试

1. ✅ 启动一个 2 分钟计时器
2. ✅ 锁定屏幕
3. ✅ 切换到其他应用或放下手机
4. ✅ 等待 2 分钟
5. ✅ **预期结果**：同测试 A

#### 测试 D: 前台测试（对照组）

1. ✅ 启动一个 10 秒计时器
2. ✅ **保持应用在前台**
3. ✅ **不要锁屏**
4. ✅ 等待 10 秒
5. ✅ **预期结果**：
   - 应该听到提示音
   - 应用内计时器变为红色闪烁
   - 同时收到通知

## 🔍 问题排查

### 问题 1: 卸载后重装，还是没有声音

**检查清单**：

1. ✅ 确认已完全卸载旧版本
   ```bash
   # 检查应用是否已卸载
   adb shell pm list packages | grep gridtimer
   # 如果没有输出，说明已卸载
   ```

2. ✅ 确认通知权限已授予
   ```
   设置 → 应用 → GridTimer → 通知 → 应该显示"已允许"
   ```

3. ✅ 确认手机没有静音
   - 调高媒体音量
   - 调高通知音量
   - 关闭勿扰模式

4. ✅ 检查通知通道设置
   ```
   设置 → 应用 → GridTimer → 通知 → Timer Alarm (default) → 
   确认"声音"已开启，且选择了声音
   ```

### 问题 2: 通知通道没有声音选项

**原因**：旧的 v1 通道还存在

**解决方案**：
```bash
# 完全卸载应用（包括数据）
adb uninstall com.calcitem.gridtimer

# 或者在手机上：
# 设置 → 应用 → GridTimer → 存储 → 清除数据 → 卸载
```

### 问题 3: 只有振动，没有声音

**可能原因**：
1. 手机媒体音量为 0
2. 通知音量为 0
3. 通知通道的声音设置被关闭

**解决方案**：
1. 调高所有音量
2. 在系统设置中检查通知通道的声音设置
3. 确认 `android/app/src/main/res/raw/sound.wav` 文件存在

### 问题 4: 通知显示但不发声

**可能原因**：
1. 通知通道的声音文件加载失败
2. 音频文件格式不兼容

**解决方案**：
```bash
# 检查 raw 文件夹中的音频文件
ls -lh android/app/src/main/res/raw/

# 应该看到 sound.wav
# 确认文件不是 0 字节
```

### 问题 5: 后台应用被杀死

**症状**：
- 锁屏一段时间后，计时器停止运行
- 通知也不触发

**解决方案**：

#### 小米手机
1. 安全中心 → 应用管理 → GridTimer
2. 自启动 → 开启
3. 省电优化 → 无限制

#### 华为手机
1. 设置 → 应用 → 应用启动管理
2. 找到 GridTimer → 手动管理
3. 允许自启动、允许关联启动、允许后台活动

#### OPPO/vivo/realme
1. 设置 → 电池 → 应用耗电管理
2. 找到 GridTimer → 允许后台运行
3. 设置 → 应用管理 → GridTimer → 允许自启动

#### 原生 Android
1. 设置 → 应用 → GridTimer → 电池
2. 选择"不限制"

## 🧪 调试方法

### 方法 1: 使用 logcat 查看日志

```bash
# 实时查看应用日志
adb logcat | grep -E "GridTimer|flutter|notification"

# 查看通知相关日志
adb logcat | grep -i "notification"
```

### 方法 2: 检查通知通道

```bash
# 列出所有通知通道
adb shell cmd notification list_channels com.calcitem.gridtimer
```

应该看到类似输出：
```
gt.alarm.timeup.default.v2:
  sound=content://media/internal/audio/media/...
  importance=max
  vibration=true
```

### 方法 3: 手动触发通知测试

在应用的设置页面，可以添加一个测试按钮：
```dart
ElevatedButton(
  onPressed: () async {
    final notification = ref.read(notificationServiceProvider);
    await notification.showTimeUpNow(
      session: testSession,
      config: testConfig,
    );
  },
  child: Text('测试通知'),
)
```

## 📊 预期行为对比

| 场景 | 前台 | 后台（未锁屏） | 后台（锁屏） |
|------|------|----------------|--------------|
| 应用内音频播放 | ✅ | ✅ | ❌ (可能) |
| 系统通知声音 | ✅ | ✅ | ✅ |
| 通知显示 | ✅ | ✅ | ✅ |
| 屏幕唤醒 | N/A | N/A | ✅ (如果授予权限) |
| TTS 播报 | ✅ | ✅ | ❌ (可能) |

**关键点**：
- 锁屏时主要依赖**系统通知声音**（通知通道配置的声音）
- 应用内音频播放在锁屏时可能不工作
- 因此通知通道的声音配置至关重要

## 💡 技术原理

### 双重声音机制

1. **应用层音频**（AudioPlayer）
   - 适用于：应用在前台时
   - 优点：可以循环播放、控制音量
   - 缺点：锁屏时可能被系统暂停

2. **系统层通知声音**（Notification Channel Sound）
   - 适用于：所有场景，特别是锁屏时
   - 优点：系统保证播放，不受应用状态影响
   - 缺点：只能播放一次，音量由系统控制

### 通知触发流程

```
启动计时器
    ↓
调用 scheduleTimeUp() 
    ↓
使用 AndroidScheduleMode.exactAllowWhileIdle
    ↓
系统在指定时间触发通知
    ↓
通知使用 v2 通道
    ↓
播放 sound.wav（从通道配置）
    ↓
显示通知 + 振动
```

## ✅ 成功标准

测试成功的标志：

1. ✅ 卸载重装后，通知权限对话框正常弹出
2. ✅ 授予权限后，前台计时器到时间有声音
3. ✅ **锁屏时，计时器到时间能听到声音**
4. ✅ 锁屏上显示通知，带有"Stop"按钮
5. ✅ （可选）锁屏时屏幕会亮起

## 📝 已修复的问题

1. ✅ 添加了启动时权限请求
2. ✅ 在 `scheduleTimeUp` 中明确设置 `playSound: true`
3. ✅ 在 `scheduleTimeUp` 中明确设置 `enableVibration: true`
4. ✅ 将通知通道版本从 v1 升级到 v2
5. ✅ 配置音频上下文为 `AndroidUsageType.alarm`
6. ✅ 添加即时通知显示（`showTimeUpNow`）

## 🔄 如果还是不行

如果完全按照上述步骤操作，锁屏时还是没有声音，请提供以下信息：

1. 手机型号和 Android 版本
2. logcat 日志（特别是通知触发时的日志）
3. 通知通道列表输出
4. 前台测试是否有声音
5. 系统通知设置截图

我会根据这些信息进一步诊断问题。

