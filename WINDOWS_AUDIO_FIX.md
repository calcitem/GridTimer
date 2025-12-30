# Windows 音频修复指南

## 问题说明

Windows 平台的 `audioplayers` 插件不支持 `.ogg` 格式的音频文件，会导致以下错误：

```
PlatformException(WindowsAudioError, Failed to set source...)
```

## 解决方案

### 方案 1：转换音频文件为 MP3 格式（推荐）

使用 FFmpeg 或其他音频转换工具将 `.ogg` 文件转换为 `.mp3` 格式。

#### 使用 FFmpeg（命令行）：

1. 下载安装 FFmpeg：https://ffmpeg.org/download.html

2. 转换单个文件：
```bash
ffmpeg -i assets/sounds/kenney_interface-sounds/Audio/confirmation_001.ogg assets/sounds/kenney_interface-sounds/Audio/confirmation_001.mp3
```

3. 批量转换所有文件（在项目根目录运行）：
```bash
cd assets/sounds/kenney_interface-sounds/Audio
for f in *.ogg; do ffmpeg -i "$f" "${f%.ogg}.mp3"; done
```

4. 更新 `lib/infrastructure/audio_service.dart` 中的文件路径：
```dart
String _soundKeyToAssetPath(SoundKey soundKey) {
  return 'sounds/kenney_interface-sounds/Audio/confirmation_001.mp3';
}
```

5. 更新 `pubspec.yaml` 中的 assets（如果需要）

### 方案 2：使用在线转换工具

1. 访问 https://cloudconvert.com/ogg-to-mp3
2. 上传 `confirmation_001.ogg` 文件
3. 转换为 MP3 格式
4. 下载并替换原文件
5. 按照方案 1 的步骤 4 更新代码

### 方案 3：临时禁用音频（仅用于开发测试）

代码已经添加了错误处理，音频播放失败不会影响应用的其他功能。应用会：
- 在控制台打印警告信息
- 继续正常运行（只是没有声音）
- TTS 语音播放仍然可用

## 当前状态

✅ 已添加错误处理，应用可以正常运行（无声音）
⚠️ 需要转换音频文件才能在 Windows 上播放声音

## 推荐的音频格式支持

| 平台 | 推荐格式 | 支持 OGG |
|------|----------|----------|
| Android | OGG, MP3 | ✅ |
| iOS | MP3, WAV | ❌ |
| Windows | MP3, WAV | ❌ |
| macOS | MP3, WAV | ⚠️ 有限 |
| Web | MP3, WAV | ⚠️ 浏览器依赖 |

**结论**：使用 `.mp3` 格式可以获得最佳的跨平台兼容性。

## 相关文件

- `lib/infrastructure/audio_service.dart` - 音频服务实现
- `assets/sounds/kenney_interface-sounds/Audio/` - 音频文件目录
- `assets/sounds/README.md` - 音频资源说明

