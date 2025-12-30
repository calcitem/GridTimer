# 数据迁移修复说明

## 问题描述

在添加新的声音和 TTS 设置字段后，运行应用时出现以下错误：

```
type 'Null' is not a subtype of type 'num' in type cast
at package:grid_timer/data/models/app_settings_hive.g.dart:27
```

## 问题原因

应用的旧版本数据库中保存的 `AppSettings` 数据只包含以下字段：
- activeModeId
- flashEnabled
- ttsGlobalEnabled
- keepScreenOnWhileRunning
- alarmReliabilityHintDismissed
- vibrationEnabled
- onboardingCompleted

新版本添加了 5 个新字段：
- soundVolume (double)
- selectedSoundKey (String)
- ttsVolume (double)
- ttsSpeechRate (double)
- ttsPitch (double)

当应用尝试从旧数据库读取数据时，这些新字段的值为 `null`，但字段类型定义为非空类型，导致类型转换失败。

## 解决方案

在 `AppSettingsHive` 的字段定义中添加 `defaultValue` 参数：

```dart
@HiveField(7, defaultValue: 1.0)
final double soundVolume;

@HiveField(8, defaultValue: 'default')
final String selectedSoundKey;

@HiveField(9, defaultValue: 1.0)
final double ttsVolume;

@HiveField(10, defaultValue: 0.5)
final double ttsSpeechRate;

@HiveField(11, defaultValue: 1.0)
final double ttsPitch;
```

## 生成的代码

重新运行 `build_runner` 后，生成的 Hive 适配器代码会自动处理 null 值：

```dart
AppSettingsHive read(BinaryReader reader) {
  // ...
  return AppSettingsHive(
    // ... 旧字段 ...
    soundVolume: fields[7] == null ? 1.0 : (fields[7] as num).toDouble(),
    selectedSoundKey: fields[8] == null ? 'default' : fields[8] as String,
    ttsVolume: fields[9] == null ? 1.0 : (fields[9] as num).toDouble(),
    ttsSpeechRate: fields[10] == null ? 0.5 : (fields[10] as num).toDouble(),
    ttsPitch: fields[11] == null ? 1.0 : (fields[11] as num).toDouble(),
  );
}
```

## 默认值说明

| 字段 | 默认值 | 说明 |
|------|--------|------|
| soundVolume | 1.0 | 100% 音量 |
| selectedSoundKey | 'default' | 默认声音 |
| ttsVolume | 1.0 | 100% TTS 音量 |
| ttsSpeechRate | 0.5 | 正常语速 |
| ttsPitch | 1.0 | 正常音调 |

## 执行步骤

1. 修改 `lib/data/models/app_settings_hive.dart` 添加 defaultValue
2. 运行代码生成：
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. 验证编译：
   ```bash
   flutter analyze
   ```

## 测试验证

### 旧数据兼容性测试
1. ✅ 启动应用（已有旧版本数据）
2. ✅ 应用正常加载，不再崩溃
3. ✅ 新字段自动使用默认值
4. ✅ 用户可以正常修改设置
5. ✅ 修改后的设置正确保存

### 新安装测试
1. ✅ 全新安装应用
2. ✅ 首次启动正常
3. ✅ 设置页面显示默认值
4. ✅ 所有功能正常工作

## 注意事项

### Hive 数据迁移最佳实践

1. **始终为新字段添加 defaultValue**
   ```dart
   @HiveField(index, defaultValue: yourDefaultValue)
   final Type fieldName;
   ```

2. **避免删除或重命名字段**
   - 如果需要删除，保留字段索引为 reserved
   - 如果需要重命名，使用新索引添加新字段

3. **字段索引不可重复使用**
   - 一旦使用过的索引不应该再次使用
   - 保持索引的连续性和唯一性

4. **typeId 保持不变**
   - AppSettingsHive 的 typeId = 4 不应改变
   - 每个 Hive 类型应该有唯一的 typeId

### 未来添加字段的步骤

1. 在 `AppSettings` 实体中添加新字段（带默认值）
2. 在 `AppSettingsHive` 中添加对应字段（带 @HiveField 和 defaultValue）
3. 更新 fromDomain 和 toDomain 方法
4. 运行 build_runner 生成代码
5. 测试旧数据兼容性

## 相关文件

- `lib/core/domain/entities/app_settings.dart` - 领域实体
- `lib/data/models/app_settings_hive.dart` - Hive 适配器源文件
- `lib/data/models/app_settings_hive.g.dart` - Hive 适配器生成文件

## 问题状态

✅ **已解决** - 应用现在可以正确处理旧版本数据，同时支持新字段。

