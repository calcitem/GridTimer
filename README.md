# GridTimer

一个专为老年人设计的 9 宫格并行倒计时器，具有可靠的闹钟系统和极简的用户界面。

A 9-grid parallel timer app optimized for seniors with reliable alarm system and minimalist UI.

## 特性 Features

- ✅ **9 宫格并行计时**：同时运行多个计时器，互不干扰
- ✅ **多模式支持**：保存多套九宫格配置，快速切换
- ✅ **可靠提醒**：精确闹钟 + 全屏通知，锁屏也能响
- ✅ **语音播报**：支持中英文 TTS 语音提醒
- ✅ **状态持久化**：App 被杀或重启后自动恢复计时状态
- ✅ **防误触设计**：所有关键操作均有二次确认
- ✅ **大号字体**：1 米外可清晰辨识
- ✅ **双语支持**：简体中文 + English

## 系统要求 Requirements

- **Flutter SDK**：3.8.0 及以上
- **Dart SDK**：3.8.0 及以上
- **Android**：最低支持版本由 Flutter SDK 决定
- **Target SDK**：Android 15 (API 36)
- **推荐**：Android 13+ 以获得完整功能体验（通知权限、精确闹钟）

## 快速开始 Quick Start

### 环境准备

```bash
# 1. 克隆仓库
git clone <repository-url>
cd GridTimer

# 2. 安装依赖
flutter pub get

# 3. 生成代码（Hive、Freezed、国际化）
./tool/gen.sh

# 4. 运行应用
flutter run
```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release
```

## 项目结构 Project Structure

```
lib/
├── app/              # 应用配置、状态管理与提供者
├── core/             # 核心层
│   ├── config/       # 应用配置与常量
│   ├── domain/       # 领域层（实体、服务接口、枚举）
│   └── services/     # 核心服务（错误处理等）
├── data/             # 数据层（Hive 模型与仓库）
├── infrastructure/   # 基础设施层（服务实现：通知、音频、TTS）
├── presentation/     # 表现层（页面、对话框、组件）
└── l10n/             # 国际化文件（ARB）
```

## 技术栈 Tech Stack

- **框架**：Flutter 3.8+
- **状态管理**：Riverpod
- **本地存储**：Hive CE
- **通知系统**：flutter_local_notifications
- **音频播放**：audioplayers
- **语音合成**：flutter_tts
- **架构模式**：Clean Architecture

## 开发指南 Development

### 代码规范

- 所有源码注释必须使用**英文**
- UI 文案必须通过 ARB 文件国际化
- 遵循 `analysis_options.yaml` 规则

### 运行检查

```bash
# 代码分析
flutter analyze

# 运行测试
flutter test

# 代码生成
./tool/gen.sh
```

### 权限说明

应用需要以下权限以确保可靠运行：

- **通知权限**（Android 13+）：显示到点提醒
- **精确闹钟**（Android 14+）：准时触发提醒
- **全屏通知**：锁屏显示大按钮
- **开机启动**：重启后恢复计时状态

## 贡献 Contributing

欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

## 更新日志 Changelog

查看 [CHANGELOG.md](CHANGELOG.md) 了解版本历史。

## 许可证 License

本项目采用 Apache License 2.0 许可证 - 详见 [LICENSE](LICENSE) 文件。

版权所有 © 2026 Calcitem Studio

第三方组件许可声明请查看 [NOTICE](NOTICE) 文件。

## 联系方式 Contact

如有问题或建议，请提交 Issue。
