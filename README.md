# GridTimer PRD v2.0

## 0. 文档信息

* 产品名：GridTimer
* 平台：Android（主目标，上架 Google Play）；Flutter 代码结构保持可扩展到 iOS，但 **MVP 只保证 Android 完整可用与可上架**
* PRD 版本：v1.0
* 目标：**一次生成**可编译、可签名、可发布 Play Store 的 AAB（Android App Bundle），并通过基础政策/权限声明自检

---

## 1. 项目愿景与成功标准

### 1.1 愿景

做一款 **9 宫格、多路并行、极致易读、防误触** 的倒计时器，专为老年人/照护场景优化；并且在 Android 后台/进程被杀/设备重启后仍能高可靠恢复与提醒。

### 1.2 成功标准（可验收）

必须同时满足：

1. **可用性**

   * 3×3 固定九宫格，开屏即用，无多余信息。
   * 每个格子一键启动预设倒计时。
2. **易读性**

   * 倒计时数字在格子内占主视觉（≥ 70% 可用高度），1 米内可辨识（以 6.5 寸手机为参考）。
3. **防误触**

   * 所有关键动作（启动新计时器、切模式、重置、停止响铃）都有明确的二次确认或强提示，且弹窗 **不可点外部关闭**。
4. **可靠性**

   * App 被杀/后台后重新打开能根据系统时间自动恢复（不依赖 Dart 计时器连续运行）。
   * 到点提醒必须通过系统级机制触发（本 PRD 采用“**精确闹钟 + 通知/全屏提醒**”策略），并对 Android 14+ 的 **精确闹钟默认拒绝**做兼容处理。([Android Developers][2])
5. **可上架**

   * targetSdkVersion=35，符合 Play 的 Target API 要求。([Google Help][1])
   * 若使用精确闹钟、全屏意图、前台服务等，具备完整声明与降级路径，避免因权限/政策导致审核失败或运行崩溃。([Google Help][3])

---

## 2. 用户画像与核心场景

### 2.1 目标用户

* **长辈用户**：只需要“按一下开始、到点提醒、按一下停止”。
* **照护者/家属**：负责设置九宫格名称、时长、铃声、模式；希望切换模式快捷且不误操作。

### 2.2 典型场景

1. 厨房：蒸/煮/炖/焖（多个同时计时）
2. 运动：拉伸/间歇/休息（多个循环）
3. 用药/护理：不同间隔提醒（模式保存）
4. 设备锁屏/放口袋：到点要能响+能在锁屏快速停止

---

## 3. 范围定义

### 3.1 必须做（MVP）

* 3×3 九宫格计时器（9 路并行）
* 多模式（多套九宫格配置）保存/切换
* 设置页可编辑：名称、时长、铃声
* 计时状态持久化与恢复
* 到点提醒：声音 +（可选）TTS
* 锁屏可见提醒 + 大按钮停止（通过通知动作/或全屏提醒）
* 首次启动权限向导（通知、精确闹钟、忽略电池优化、全屏提醒能力提示）

### 3.2 明确不做（避免过度范围）

* 不接入账号系统、云同步
* 不接入广告、埋点 SDK（避免隐私与闭源）
* 不做复杂统计报表
* 不做联网功能（除“打开系统设置页面”）

---

## 4. 技术与合规硬约束（LLM 必须严格遵守）

### 4.1 代码规范与工程要求

* **逻辑与 UI 彻底解耦**：采用 Clean Architecture（Presentation / Domain / Data 分层）或等价解耦方案。
* **所有代码注释必须为英文**（包括 dartdoc、行内注释、README 的工程说明部分可中英混合，但源码注释强制英文）。
* **可测试性**：Domain 层必须 100% 无 Flutter 依赖，可单元测试；计时逻辑必须可注入时钟（IClock）。
* **错误处理**：所有平台调用必须捕获异常并给出可理解的 UI 提示（长辈友好）。

### 4.2 第三方依赖许可（必须 MIT 兼容）

* 允许：MIT / BSD-2/3 / Apache-2.0（均为 MIT 兼容的宽松许可）
* 禁止：闭源、强 Copyleft（如 GPL/LGPL）或许可不明
* 依赖清单（建议，均为宽松许可，且可在 pub.dev 查到许可）：

  * TTS：`flutter_tts`（MIT）([Dart packages][4])
  * 音频：`audioplayers`（MIT）([Dart packages][5])
  * 通知：`flutter_local_notifications`（BSD-3-Clause，MIT 兼容）([Dart packages][6])
  * 精确闹钟/后台触发（如需）：`android_alarm_manager_plus`（BSD-3-Clause）([Dart packages][7])
  * 权限：`permission_handler`（MIT）([Dart packages][8])
  * 打开设置：`app_settings`（MIT）([Dart packages][9])
  * 本地存储：优先用 **Hive 生态且许可明确**（如 `hive_ce`/对应 generator），避免许可不明的 generator 包（见“数据存储”章节）。([Dart packages][10])

### 4.3 Android/Play 关键政策约束（必须考虑）

* **Target API**：新上架与更新必须 target API 35（Android 15）。([Google Help][1])
* **精确闹钟**：

  * Android 14 起，`SCHEDULE_EXACT_ALARM` 对大多数新装应用默认拒绝；必须在设置精确闹钟前调用 `canScheduleExactAlarms()` 判断并引导用户授权，否则可能崩溃或无法触发。([Android Developers][2])
  * Play 对 `USE_EXACT_ALARM`（自动授予版本）有更严格的用途限制；若不符合“闹钟/日历核心功能”，应使用 `SCHEDULE_EXACT_ALARM` 并做声明与引导。([Google Help][3])
* **全屏意图（USE_FULL_SCREEN_INTENT）**：

  * Android 14+ 对全屏意图默认授予更严格，仅限“通话/闹钟”等高优先级用途；Play 也会撤销不符合用途的默认权限，并要求在 Play Console 进行声明。([Google Help][11])

> PRD 的实现策略必须具备“权限未授予时的降级方案”，但同时在 UI 上明确提示“为了更可靠提醒，建议开启”。

---

## 5. 视觉与交互规范（长辈优化）

## 5.1 全局设计原则

* **一眼读懂**：主界面仅展示“名称 + 大数字倒计时”。
* **少即是多**：不出现小图标堆叠、信息密集列表。
* **强对比**：保证前景文字与背景对比足够高。
* **可控动效**：到点红色闪烁默认开启，但必须提供设置项可关闭（避免光敏风险）。

## 5.2 主界面布局

* 屏幕结构：

  * **主体：3×3 九宫格**占据除系统状态栏/手势区域以外的全部可用区域。
  * 顶部不使用小 AppBar；如需入口（设置/模式），使用 **“悬浮大按钮”**（见 5.4）。
* 每格内容（从上到下）：

  1. 格子名称（单行，超大字，可省略号）
  2. 倒计时数字（主视觉，超大字）
  3. 可选：预设时长提示（例如“10:00”小一号）

### 5.2.1 字体与尺寸（可计算规则）

* 倒计时数字：使用 `FittedBox` 或自适应算法确保数字最大化填充；最小字体不低于 48sp（小屏设备）。
* 名称：不低于 18sp；优先显示全名，超出则省略号。
* 按钮：最小触控高度 72dp；推荐 88dp（长辈友好）。

## 5.3 颜色语言（状态颜色必须统一）

* 待机 Idle：中性（灰/白）
* 运行中 Running：鲜艳绿色
* 已暂停 Paused：醒目橙/黄
* 到点 Ringing：红色闪烁（1Hz~2Hz）；关闭闪烁后为纯红 + 粗边框

> 颜色必须在设置页提供“高对比主题”开关（默认开启），以适配不同屏幕与视觉能力。

## 5.4 导航与入口（不破坏九宫格）

为保证九宫格尽量满屏，同时可进入设置/模式：

* 右上角悬浮 **大按钮**（带文字）：

  * 主按钮：`设置 Settings`
  * 次按钮（可选）：`模式 Mode`
* 防误触：入口按钮触发需 **长按 0.6s** 才进入（短按给出“长按进入设置”的 Toast/轻提示）。

---

## 6. 防误触交互细则（必须严格实现）

### 6.1 弹窗通用规则

* 所有弹窗 `barrierDismissible = false`（点击外部无效）
* 弹窗必须提供明确按钮：

  * 主要动作（Primary）
  * 取消（Cancel）——默认焦点/默认选中应为取消，避免误触执行危险动作
* 按钮必须足够大，且间距≥ 12dp

### 6.2 点击格子行为（状态驱动）

* Idle 格子点击：请求启动该计时器

  * 若存在任意 Running/Paused/Ringing 计时器 → 必须弹出二次确认（见 7.2）
* Running 格子点击：弹出“大按钮操作面板”

  * 按钮：`暂停`、`重置`、`取消`
* Paused 格子点击：弹出“大按钮操作面板”

  * 按钮：`继续`、`重置`、`取消`
* Ringing 格子点击：弹出“大按钮操作面板”

  * 按钮：`停止提醒`、`重置`（可选）、`取消`

### 6.3 配置隔离

* 主界面不允许修改名称/时长/铃声
* 仅设置页可编辑；设置页编辑也必须有防误触（保存确认/离开确认）

---

## 7. 功能详细需求

## 7.1 计时器状态机（单格）

每个计时器必须遵循以下状态与持久化字段：

* `Idle`：未开始，剩余=预设
* `Running`：倒计时进行中（由 `endAt` 计算）
* `Paused`：暂停，剩余固定不变
* `Ringing`：到点提醒进行中（声音/TTS/通知显示），直到用户停止
* `CompletedAcknowledged`（可简化为回到 Idle）：用户已确认/停止提醒

> **推荐实现**：用一个 `TimerStatus` 枚举 + `endAtEpochMs` / `remainingMs` / `lastUpdatedEpochMs` 来描述所有状态，确保可恢复。

## 7.2 启动保护（二次确认）

当用户在已有计时器 **非 Idle** 的情况下启动新的 Idle 计时器：

* 弹窗文案（本地化）：

  * 标题：`确认启动？`
  * 内容：`当前已有计时器在运行/暂停。要继续启动 [格子名称] 吗？`
* 按钮：

  * Primary：`继续启动`
  * Secondary：`取消`
* 默认选中：`取消`

## 7.3 计时引擎算法（必须按此实现，保证恢复）

### 7.3.1 启动

* 当从 Idle 启动：

  * `startAt = nowEpochMs`
  * `endAt = nowEpochMs + presetDurationMs`
  * `status = Running`
  * 立刻持久化（Hive）
  * 安排系统级到点触发（通知/闹钟），并记录其 `scheduleId`

### 7.3.2 UI 刷新（前台）

* UI 不依赖“持续运行的 Dart Timer”作为真实时间
* 真实剩余时间按：`remaining = max(0, endAt - nowEpochMs)`
* 前台每 200ms~1000ms 刷新一次（推荐 500ms），仅用于界面流畅

### 7.3.3 暂停

* `remainingMs = max(0, endAt - nowEpochMs)`
* `status = Paused`
* 取消系统级到点触发（cancel scheduleId）
* 持久化

### 7.3.4 继续

* `endAt = nowEpochMs + remainingMs`
* `status = Running`
* 重新安排系统级到点触发
* 持久化

### 7.3.5 到点

* 当 `nowEpochMs >= endAt`：

  * `status = Ringing`
  * `remainingMs = 0`
  * 触发：通知（高优先级）+ 声音 +（可选）TTS
  * 持久化

### 7.3.6 进程被杀后恢复

* App 冷启动时，读取所有 `TimerSession`：

  * Running：计算 remaining；若 <=0 → 置 Ringing；否则保持 Running
  * Paused：保持 Paused
  * Ringing：保持 Ringing（直到用户停止）
* 并根据状态 **重建必要的系统级触发**：

  * Running：确保到点触发已安排（若因系统/权限取消，需要重建）
  * Ringing：确保有可停止的前台提醒入口（通知/全屏页）

> Android 14 起精确闹钟默认拒绝，必须先检查 `canScheduleExactAlarms()` 再安排精确触发，否则可能失败。([Android Developers][2])

---

## 8. 系统级提醒策略（Android 重点，确保“可上架 + 高可靠”）

### 8.1 目标

* App 在后台/被杀时，到点仍可提醒
* 锁屏可见，并可通过“大按钮”停止

### 8.2 优先级策略（从强到弱）

**A 级（推荐，完整可靠）**

* 用户已授予：通知权限 + 精确闹钟权限（或可用）+ 合理电池优化设置
* 方案：精确闹钟在到点触发 → 显示高优先级通知（必要时全屏意图）→ 播放声音/TTS

**B 级（可用但可能延迟）**

* 用户拒绝精确闹钟或无法授予
* 方案：仅用高优先级通知 + 前台打开时的倒计时恢复；对“到点实时性”进行明确提示（设置页常驻提示条）

### 8.3 精确闹钟权限与 Play 合规

* Android 13+ 可声明 `SCHEDULE_EXACT_ALARM` 或 `USE_EXACT_ALARM`。([Android Developers][12])
* Play 对 `USE_EXACT_ALARM`（自动授予）限制更严格：仅当核心功能为闹钟/日历才应使用；否则应选择 `SCHEDULE_EXACT_ALARM` 并在控制台声明。([Google Help][3])
* Android 14 起：`SCHEDULE_EXACT_ALARM` 对多数新装应用默认拒绝，必须检查 `canScheduleExactAlarms()` 并引导用户开启；否则精确触发会失败或引发问题。([Android Developers][2])

**PRD 强制要求：**

1. App 启动向导必须包含“精确提醒”说明与开启按钮
2. 业务代码中任何 `setExact*` 或等价行为之前必须先检查可用性
3. 不可因权限缺失崩溃；必须降级并提示

### 8.4 全屏提醒（锁屏大按钮）策略

* 允许使用 `USE_FULL_SCREEN_INTENT` 来弹出到点全屏提醒（类似闹钟来电），以满足“锁屏大按钮停止”。但注意：

  * Android 14+ 对此权限默认授予更严格；Play 也会撤销不符合“通话/闹钟”用途的默认权限，并要求 Play Console 声明。([Google Help][11])
* **实现要求（两级）**

  * **优先**：全屏提醒页（大“停止”按钮）+ 通知动作（Stop）
  * **降级**：仅通知动作（Stop）+ 进入 App 后停止

---

## 9. 语音与提醒（Audio + TTS）

### 9.1 音频反馈

* 每个格子可配置不同铃声（内置 assets）
* 到点后铃声默认循环，直到用户停止（建议最大持续 60 秒后降低频率/停 2 秒再循环，避免扰民；但必须可配置）
* 多计时器到点冲突时：

  * **新的到点事件**到来时：立即停止当前铃声，播放新的铃声（“后到覆盖先到”）

### 9.2 TTS 播报

* 文案：`[格子名称] 时间到了`
* 语言：跟随系统语言（至少：简体中文、英文）
* **中断逻辑（强制）**：若多个计时器先后到期，后到的播报必须 `stop()` 当前播报并立即播报新的（覆盖）。

  * 可用 `flutter_tts.stop()` + `speak()` 实现（需保证串行化）。([Dart packages][4])

### 9.3 锁屏交互

* 必须有“停止提醒”动作可在锁屏执行：

  * 通知 action：`停止 Stop`
  * 全屏提醒页按钮：`停止 Stop`
* “停止提醒”必须同时：

  1. 停止铃声
  2. 停止 TTS
  3. 将该格状态从 Ringing 置为 Idle（或 CompletedAcknowledged → Idle），并持久化
  4. 取消该格相关通知/闹钟

---

## 10. 模式（多套九宫格配置）

### 10.1 模式定义

* 一个 Mode = 一个 3×3 配置（9 个 TimerConfig）
* 支持：

  * 新建模式（从默认模板或复制当前）
  * 重命名
  * 删除（至少保留 1 个）
  * 切换（当前模式为“激活模式”）

### 10.2 切换保护

* 若存在任何非 Idle 的计时器：

  * 弹窗确认：`切换模式会停止当前所有计时器，是否继续？`
  * 按钮：`继续切换` / `取消`
  * 默认选中：取消
* 若继续：停止所有计时器 + 取消所有计划触发 + 保存当前状态，再切换

---

## 11. 设置页（唯一配置入口）

### 11.1 设置页结构（建议信息架构）

1. 模式管理
2. 九宫格编辑（9 项列表或 3×3 预览可点）
3. 全局提醒设置
4. 权限与系统设置
5. 关于（版本、开源许可、隐私政策）

### 11.2 单格配置编辑（TimerConfig Editor）

字段：

* 名称（String，1~10 字；超出提示）
* 时长（Duration）

  * 快捷预设：30s/1m/3m/5m/10m/15m/30m/45m/60m
  * 自定义：大号步进器（分钟/秒分开），避免小键盘
* 铃声（枚举/资源 key）

  * 支持试听（播放 1~2 秒）
* （可选）到点是否播报 TTS（布尔，默认开）

保存规则：

* 离开编辑页若有未保存更改 → 弹窗询问保存/丢弃（不可点外部关闭）

### 11.3 全局提醒设置

* 红色闪烁开关（默认开）
* 震动开关（默认开，若实现）
* TTS 总开关（默认开）
* 到点铃声时长策略（例如：持续/60秒后降低/仅响3次）
* “运行中保持屏幕常亮”（默认关）

---

## 12. 权限与首次启动向导（强制）

### 12.1 向导触发

* 仅首次启动自动进入
* 后续可在“设置 > 权限与系统设置”再次进入

### 12.2 向导页面要求（长辈友好）

* 每一项权限单独一屏或同屏大卡片，**用简单语言解释“为什么需要”**
* 每项提供：

  * 当前状态（已开启/未开启）
  * 一个大按钮：`去开启`
  * 一个次按钮：`稍后`
* 最后汇总：显示“你的提醒可靠性等级：A/B”，并解释差异

### 12.3 必须引导的权限/设置

1. **通知权限**（Android 13+）
2. **精确提醒（精确闹钟）**

   * Android 14 起默认拒绝，需要引导用户开启；实现必须先 `canScheduleExactAlarms()` 检查。([Android Developers][2])
3. **忽略电池优化**（提升后台可靠性）

   * Android 文档建议可通过系统设置页面引导用户加入豁免列表。([Android Developers][13])
4. **全屏提醒能力说明**（如使用 USE_FULL_SCREEN_INTENT）

   * Play/Android 14+ 对全屏意图更严格，必须声明且可能需要用户额外授权。([Google Help][11])

---

## 13. 国际化（ARB + Weblate 友好）

### 13.1 工程约束

* 必须使用 Flutter 官方 `gen-l10n` 方案
* 所有文案只出现在 ARB 中，代码不可硬编码中文/英文

### 13.2 ARB 规范（便于 Weblate）

* 文件路径：`lib/l10n/app_zh.arb`, `lib/l10n/app_en.arb`
* key 命名：`snake_case` 或 `lowerCamelCase`，必须一致
* 使用 `@key` 提供：

  * description（给译者）
  * placeholders（变量含义）

### 13.3 关键文案必须覆盖

* 所有弹窗标题/内容/按钮
* 权限向导解释
* 模式/设置项名称
* 到点播报模板

---

## 14. 数据模型（Domain 实体 + Hive 持久化）

### 14.1 核心实体（Domain Layer）

#### TimerConfig

* `id: String`（固定，建议 `t0`~`t8`）
* `name: String`
* `presetDurationMs: int`
* `soundKey: String`
* `ttsEnabled: bool`

#### TimerGridSet（Mode）

* `id: String`
* `name: String`
* `timers: List<TimerConfig>`（长度必须=9，顺序固定）

#### TimerSession（Runtime State）

* `timerId: String`（t0~t8）
* `modeId: String`（关联当前模式）
* `status: TimerStatus`
* `endAtEpochMs: int?`（Running 时必须存在）
* `remainingMs: int`（Paused/Ringing/Idle 时有意义）
* `lastUpdatedEpochMs: int`（用于调试与恢复）

#### AppSettings（Global）

* `activeModeId: String`
* `flashEnabled: bool`
* `ttsGlobalEnabled: bool`
* `keepScreenOnWhileRunning: bool`
* `alarmReliabilityHintDismissed: bool`（可选）

### 14.2 Hive 存储策略（Data Layer）

* 分 box 存储（避免耦合/便于迁移）：

  * `box_modes`：存 `TimerGridSet`
  * `box_sessions`：存 9 个 `TimerSession`
  * `box_settings`：存 `AppSettings`
* 迁移策略：

  * `schemaVersion` 字段 + 简单迁移器（例如新增字段提供默认值）
* 重要：每次状态变更必须立即写入（避免进程被杀丢状态）

> Hive 生态建议选用**许可明确**的实现与 generator（例如 `hive_ce` / `hive_ce_generator`），避免 generator 许可不明带来的上架合规风险。([Dart packages][10])

---

## 15. 服务层抽象（必须接口化，便于测试/替换）

### 15.1 时钟与调度

* `IClock`

  * `int nowEpochMs()`
* `ITicker`

  * `Stream<int> ticks({Duration interval})`

### 15.2 计时服务

* `ITimerService`

  * `Future<void> startTimer(timerId)`
  * `Future<void> pauseTimer(timerId)`
  * `Future<void> resumeTimer(timerId)`
  * `Future<void> resetTimer(timerId)`
  * `Stream<TimerSession> watchTimer(timerId)`
  * `Stream<List<TimerSession>> watchAll()`
  * `Future<void> restoreOnAppStart()`

### 15.3 通知/闹钟服务

* `INotificationService`

  * `Future<void> scheduleTimeUp(timerId, endAtEpochMs, payload)`
  * `Future<void> cancel(timerId)`
  * `Future<void> showOngoingRunningSummary(optional)`
  * `Stream<NotificationAction> onAction()`（Stop / Open）

### 15.4 音频与 TTS

* `IAudioService`

  * `Future<void> playLoop(soundKey)`
  * `Future<void> stopAllAudio()`
* `ITtsService`

  * `Future<void> speak(text, locale)`
  * `Future<void> stop()`（用于覆盖中断）

### 15.5 权限与系统设置

* `IPermissionService`

  * `Future<PermissionState> getNotificationPermission()`
  * `Future<void> requestNotificationPermission()`
  * `Future<ExactAlarmState> getExactAlarmState()`（Android 专用）
  * `Future<void> openExactAlarmSettings()`
  * `Future<BatteryOptState> getBatteryOptState()`
  * `Future<void> openBatteryOptSettings()`
  * `Future<FullScreenIntentState> getFsiState()`（如实现）
  * `Future<void> openFsiSettings()`（如可行）

---

## 16. 工程结构（建议目录，LLM 必须按层次落地）

```
lib/
  app/
    app.dart
    routes.dart
    di.dart
  core/
    constants/
    error/
    localization/
    utils/
  features/
    grid_timer/
      domain/
        entities/
        repositories/
        usecases/
      data/
        datasources/
        models/
        repositories_impl/
      presentation/
        pages/
        widgets/
        controllers/   // state notifier / bloc / riverpod providers
    settings/
      ...
    onboarding/
      ...
  l10n/
    app_en.arb
    app_zh.arb
tool/
  flutter-init.sh
  gen.sh
```

---

## 17. 初始化与代码生成脚本（必须可一键跑通）

### 17.1 `tool/flutter-init.sh`（示例行为要求）

* `flutter pub get`
* `flutter gen-l10n`
* `dart run build_runner build --delete-conflicting-outputs`
* （可选）`flutter test`

### 17.2 `tool/gen.sh`

* 仅做代码生成（build_runner + l10n）

> 目标：任何机器 clone 后执行脚本即可生成全部必要代码（Hive adapter、Freezed、l10n 等）。

---

## 18. 非功能性需求（上线质量）

### 18.1 性能

* 冷启动可交互 < 1.5s（中端机）
* 前台刷新不掉帧：单 ticker 驱动九格，避免 9 个 Timer 并发

### 18.2 稳定性

* 任意平台通道调用失败必须可恢复（提示并降级）
* 精确闹钟权限被系统/用户撤销后：

  * 必须提示并降级
  * 不可崩溃
  * Android 指南建议监听权限状态变化广播并做响应（可选增强）。([Android Developers][2])

### 18.3 可访问性

* 所有可点击元素有语义标签（TalkBack）
* 对比度与字号策略满足“长辈可读”
* 震动/闪烁可关闭

---

## 19. 测试与验收用例（必须覆盖）

### 19.1 关键功能用例（至少）

1. 9 格同时启动，互不影响
2. Running → Pause → Resume → 到点
3. App 切后台 10 分钟后回前台：剩余正确
4. App 被杀（任务管理器划掉）后重开：状态正确恢复
5. 模式切换时存在运行计时器：必须弹窗确认
6. 多个计时器到点：后到 TTS 覆盖先到（stop+ speak）
7. 锁屏到点：通知出现且可“停止”
8. 未授予精确闹钟：提示可靠性下降，App 仍可用不崩溃
9. Android 13+ 未授予通知：引导开启；到点至少在 App 内可见

### 19.2 回归清单（上架前）

* targetSdk=35 构建 AAB 成功
* 所有声明权限都有对应 UI 用途说明与设置入口
* “关于”页可打开开源许可列表（Flutter `showLicensePage`）
* 隐私政策页面存在且可从应用内访问（即使不联网，也可内置文本）

---

## 20. Play Store 上架准备清单（PRD 必须要求实现）

### 20.1 Android 构建配置（强制）

* compileSdkVersion = 35
* targetSdkVersion = 35（满足 Play 新上架/更新要求）([Google Help][1])
* minSdkVersion：建议 23（可根据实际市场调整）
* 输出：`flutter build appbundle --release` 成功

### 20.2 权限声明与合规说明（强制）

若使用下列能力，必须满足对应声明/引导/降级：

* 精确闹钟：遵守 Android 14 默认拒绝的检查与引导；并考虑 Play 对 `USE_EXACT_ALARM` 的限制。([Android Developers][2])
* 全屏意图：必须仅用于“闹钟式到点提醒”，并准备 Play Console 声明；同时提供非全屏降级。([Google Help][11])

### 20.3 商店物料（PRD 交付物要求）

* App 名称（中/英）
* 简短描述（80 字符）
* 完整描述（含功能点、权限用途解释）
* 截图（至少 4 张）：主界面 Idle、Running、Ringing、设置/模式
* 隐私政策（可内置页面 + Play Console 链接）
* 数据安全表单：默认声明“不收集数据/不共享数据”（以实际实现为准）

---

## 21. 附录：核心文案 Key（示例，必须做 i18n）

（以下仅示例，实际需全部放 ARB）

* `start_confirm_title`：确认启动？
* `start_confirm_body`：当前已有计时器在运行/暂停。要继续启动 {name} 吗？
* `start_confirm_primary`：继续启动
* `common_cancel`：取消
* `action_pause`：暂停
* `action_resume`：继续
* `action_reset`：重置
* `time_up_tts`：{name} 时间到了
* `permission_exact_alarm_title`：开启精确提醒
* `permission_exact_alarm_body`：为确保到点准时提醒，请开启“闹钟与提醒/精确闹钟”权限。

---

# 你可以直接把这份 PRD 交给 AI 生成工程时的“硬性指令”

为了确保一次性成形，建议你在生成时额外加 3 条“系统级约束”：

1. **必须先实现 Domain 层纯 Dart 的计时状态机 + 恢复算法**，再接 UI
2. **任何系统能力（闹钟/通知/权限）都必须可检测状态 + 有引导页面 + 有降级**
3. **Release 构建必须通过**：`flutter analyze`、`flutter test`、`flutter build appbundle --release`

---

下面内容按“可直接复制进 README.md 的工程级交付规范”撰写（Markdown 结构 + 可复制代码片段）。重点覆盖：**Gradle/Manifest 权限与组件清单、通知 Channel 设计、通知 Action 回调协议、各 Service/Interface 方法签名模板**，并补齐与 **Android 14/15 + Play Console 上架**强相关的合规要点。

---

# GridTimer (Senior) — Engineering Delivery Spec (README Copy)

> **Code rule**: All code comments MUST be in **English** (including Dart/Kotlin/Swift comments).
> **License rule**: Only use permissive open-source dependencies (MIT/BSD/Apache2). No closed-source SDKs.

## 0. Release & Compliance Baseline

### 0.1 Target SDK / Play Store requirement

* **targetSdkVersion = 35 (Android 15)** and **compileSdk = 35** for Play submission after **Aug 31, 2026**. ([Google Help][1])
* `flutter_local_notifications` also requires **compileSdk ≥ 35**.

### 0.2 Android 14+ key restrictions (must design around)

* **Exact alarms**: `SCHEDULE_EXACT_ALARM` is **not pre-granted** for fresh installs targeting Android 13+; on Android 14 a user must grant the “Alarms & reminders” special access, and if revoked **future exact alarms are canceled**. You must check/handle this gracefully.
* **Full-screen intent**: On Android 14+, apps allowed to use `USE_FULL_SCREEN_INTENT` are effectively limited to **calling/alarm** core functionality; Google Play can revoke default permission otherwise. You must support “user-grant fallback” via settings.

### 0.3 Policy-driven design decisions (to avoid rejection)

* **Do NOT request** `SYSTEM_ALERT_WINDOW` (overlay) unless you have a strict, reviewable justification. We will implement lock-screen UX via:

  * Full-screen intent notification + alarm page (FlutterActivity with `showWhenLocked` + `turnScreenOn`) and
  * High-importance notification with action buttons.
* **Battery optimization**: Prefer **opening system settings screens** for user guidance rather than requesting restricted permissions.

---

## 1. Dependencies (Permissive Licenses)

> Note: some older Hive packages show “unknown license” on pub.dev metadata even if repo contains a license. For strict compliance, prefer packages with explicit license metadata.

Recommended packages (permissive):

* `flutter_local_notifications` (BSD-3-Clause) ([Dart packages][2])
* `flutter_tts` (MIT) ([Dart packages][3])
* `audioplayers` (MIT) ([Dart packages][4])
* **Persistence (Hive)**: prefer `hive_ce` + `hive_ce_flutter` (Apache-2.0 / BSD-3-Clause). ([Dart packages][5])

Example `pubspec.yaml` excerpt:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Storage (Hive family)
  hive_ce: ^2.10.0
  hive_ce_flutter: ^2.1.0

  # Notifications
  flutter_local_notifications: ^19.5.0

  # Audio + TTS
  audioplayers: ^6.0.0
  flutter_tts: ^4.0.2

  # i18n (ARB)
  flutter_localizations:
    sdk: flutter
  intl: any

dev_dependencies:
  build_runner: ^2.4.0
  hive_ce_generator: ^1.8.0
```

---

## 2. Android Gradle Setup (Required)

### 2.1 `android/app/build.gradle` (Groovy)

`flutter_local_notifications` requires **desugaring + Java 17** configuration.
Also set **compileSdk = 35**, and for Play **targetSdk = 35**. ([Google Help][1])

```gradle
android {
    compileSdkVersion 35

    defaultConfig {
        minSdkVersion 23
        targetSdkVersion 35

        // Required by flutter_local_notifications docs (safe default)
        multiDexEnabled true
    }

    compileOptions {
        // Enable support for newer Java APIs on older Android versions
        coreLibraryDesugaringEnabled true

        // Java 17 bytecode
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

> Plugin note: the docs mention aligning with Android Gradle Plugin 8.6.0+ for safety.

### 2.2 `android/app/build.gradle.kts` (Kotlin DSL)

If your project uses `.kts`, mirror the plugin guidance.

```kotlin
android {
  compileSdk = 35

  defaultConfig {
    minSdk = 23
    targetSdk = 35
    multiDexEnabled = true
  }

  compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  kotlinOptions {
    jvmTarget = JavaVersion.VERSION_17.toString()
  }
}

dependencies {
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

## 3. AndroidManifest.xml — Permissions & Components Checklist

### 3.1 Permissions (minimal set for this app)

Add these **between `<manifest>` tags**:

```xml
<!-- Android 13+ runtime permission (still request at runtime) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Needed so scheduled notifications can be rescheduled after reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Exact alarms: user-granted special access on Android 14+ -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>

<!-- Full-screen intent: special app access on Android 14+ -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>

<!-- Optional but common for alarm UX -->
<uses-permission android:name="android.permission.VIBRATE"/>
```

Why these are required:

* `RECEIVE_BOOT_COMPLETED` + receivers are required for rescheduling on reboot.
* Exact alarms have Android 14 behavior changes and must be requested/handled.
* Full-screen intent is now special access; for alarms it can be valid but needs policy + fallback.

> **Do not use** `USE_EXACT_ALARM` unless you are prepared for store audits/approval and you truly match limited use cases.

### 3.2 Required receivers for `flutter_local_notifications`

Add these **between `<application>` tags** (exactly as plugin guidance).

```xml
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
    android:exported="false" />

<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>

<receiver
    android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"
    android:exported="false" />
```

### 3.3 Full-screen alarm page (lockscreen display + screen-on)

To ensure the alarm UI can show over lockscreen and turn the screen on, add attributes to the Activity that will open. For a typical Flutter app, this is the single `FlutterActivity`.

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:showWhenLocked="true"
    android:turnScreenOn="true"
    android:launchMode="singleTask"
    android:taskAffinity=""
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

> Full-screen intent notifications: when they truly “full-screen” (not only heads-up), the plugin behaves as if the user tapped the notification—handle them via the same callback (`onDidReceiveNotificationResponse`).

---

## 4. Notification Channel Design (Android)

### 4.1 Constraints you MUST respect

* On Android 8.0+, **sound & vibration are tied to the channel** and only configurable the **first time the channel is created**. If you reuse a channel ID with a different sound later, it will not change.
* Therefore, “each grid has a different ringtone” must be implemented as:

  * **one channel per soundKey**, or
  * play sound in-app (but that’s less reliable when app is killed).

We will use **one channel per soundKey**.

### 4.2 Channel ID conventions

All channel IDs must be stable and versioned:

* **Time-up alarm channels** (per sound):

  * `gt.alarm.timeup.<soundKey>.v1`
* **Running (optional) background status** (silent):

  * `gt.timer.running.v1`
* **General** (silent):

  * `gt.general.v1`

Channel group (optional):

* `gt.group.timers`

### 4.3 Sound assets mapping

Place custom sounds in:

* `android/app/src/main/res/raw/`

  * e.g. `bell_01.mp3`, `bell_02.mp3`, `beep_soft.mp3`

Plugin guidance: custom notification sounds should be raw resources.

Sound key mapping example:

| soundKey   | Android raw name |
| ---------- | ---------------- |
| `bell01`   | `bell_01`        |
| `bell02`   | `bell_02`        |
| `softbeep` | `beep_soft`      |

> Keep it small (e.g., 6–12 built-in sounds). Too many channels can confuse users in system settings.

### 4.4 Channel parameters (time-up)

For each `gt.alarm.timeup.<soundKey>.v1`:

* `importance`: `Importance.max`
* `playSound`: true (custom raw sound)
* `enableVibration`: true (pattern optional)
* `visibility`: `NotificationVisibility.public` (lockscreen visible)
* `category`: `AndroidNotificationCategory.alarm`
* `fullScreenIntent`: true (if allowed)

---

## 5. Notification IDs & Payload Protocol

### 5.1 Notification ID allocation (deterministic)

We keep integer IDs stable to allow cancel/update:

* Slot index `i ∈ [0..8]`
* **Time-up notification id**: `1000 + i`
* **Running status (optional)**:

  * Single summary: `2000`

### 5.2 Payload protocol (JSON string)

All notifications MUST include a JSON payload string.

Schema (v1):

```json
{
  "v": 1,
  "type": "time_up",
  "modeId": "m_kitchen",
  "slotIndex": 0,
  "timerId": "m_kitchen:0",
  "endAtEpochMs": 1735540000000,
  "soundKey": "bell01",
  "titleKey": "grid.slot.0.name", 
  "localeHint": "zh-CN"
}
```

Rules:

* `timerId` MUST be unique and stable: `"{modeId}:{slotIndex}"`.
* `type` values:

  * `time_up`
  * `open_app` (optional)
  * `stop_alarm` (action response only)
* `v` is mandatory for forward compatibility.

---

## 6. Notification Actions & Callback Protocol

### 6.1 Action IDs (string constants)

We define these action IDs (stable):

* `gt.action.stop` — stop ringing + stop TTS + mark timer idle
* `gt.action.open` — open app to the relevant slot

### 6.2 Action button UX (senior-friendly)

* Buttons MUST be **large** and clearly labeled (localized):

  * zh: `停止` / `打开`
  * en: `Stop` / `Open`

### 6.3 Callback dispatch rules (single source of truth)

We MUST support both callbacks:

* `onDidReceiveNotificationResponse` (foreground / app running)
* `onDidReceiveBackgroundNotificationResponse` (app terminated/background isolate, when action has `showsUserInterface: false`)

Plugin requirement: actions need `ActionBroadcastReceiver` declared in manifest.

Plugin guidance: if `showsUserInterface` is set to false, plugin triggers the **background callback**. ([Dart packages][6])

### 6.4 Recommended action configuration

**Time-up notification**:

* Body tap → open alarm page (route: `/alarm`)
* Action `gt.action.stop`:

  * Recommended: `showsUserInterface: true` for maximum reliability (stop in foreground UI)
  * Optional advanced: `showsUserInterface: false` + background callback updates Hive immediately

### 6.5 Full-screen intent handling

If a full-screen intent triggers, treat it the **same as a notification tap** in the callback handler.

---

## 7. Android 13/14 Permission Request Flow (MUST implement)

### 7.1 POST_NOTIFICATIONS (Android 13+)

Request via `AndroidFlutterLocalNotificationsPlugin().requestNotificationsPermission()`.

### 7.2 Exact alarms (Android 14+)

* Use `AndroidScheduleMode.exactAllowWhileIdle` (or `alarmClock`) only when permission is granted.
* If not granted, fallback to `AndroidScheduleMode.inexactAllowWhileIdle` (best-effort).
* Official docs: check `canScheduleExactAlarms()` and guide user to `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`.
* Plugin docs: add `SCHEDULE_EXACT_ALARM` and call `requestExactAlarmsPermission()`.

AndroidScheduleMode semantics reference: `alarmClock` requires `SCHEDULE_EXACT_ALARM`. ([Dart packages][7])

### 7.3 Full-screen intent special access (Android 14+)

* Use `NotificationManager.canUseFullScreenIntent()` check (platform side; plugin exposes request method).
* If not allowed: open settings via `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`.
* Play Console declaration is required starting May 31, 2024; after Jan 22, 2026 only calling/alarm apps are enabled by default.

---

## 8. Release Build Notes (R8 keep resources)

If you use custom notification icons/sounds, ensure R8 does not strip resources. Plugin docs explicitly warn to configure keep resources.

Recommended: create `android/app/src/main/res/raw/keep.xml` (or `res/xml/keep.xml` depending on project), then reference it in Gradle per Android docs.

Example keep file (adjust resource names to your project):

```xml
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat_gridtimer,@raw/bell_01,@raw/bell_02,@raw/beep_soft" />
```

---

# 9. Service / Interface Method Signature Templates (Dart)

> Place these under `lib/domain/` (interfaces, models) and implement under `lib/infrastructure/` (plugin adapters) + `lib/data/` (Hive repositories).
> **All doc comments below are in English** by design.

## 9.1 Core IDs & Enums

```dart
typedef ModeId = String;
typedef TimerId = String;

enum TimerStatus {
  idle,
  running,
  paused,
  ringing,
}

enum NotificationEventType {
  timeUp,
  open,
  stop,
}
```

## 9.2 Domain Models (minimal contracts)

```dart
class TimerConfig {
  final int slotIndex; // 0..8
  final String name;   // localized display name
  final Duration fixedDuration;
  final String soundKey; // e.g. bell01
  final bool ttsEnabled;

  const TimerConfig({
    required this.slotIndex,
    required this.name,
    required this.fixedDuration,
    required this.soundKey,
    required this.ttsEnabled,
  });
}

class TimerGridSet {
  final ModeId modeId;
  final String modeName;
  final List<TimerConfig> slots; // length == 9

  const TimerGridSet({
    required this.modeId,
    required this.modeName,
    required this.slots,
  });
}

class TimerSession {
  final TimerId timerId;     // "{modeId}:{slotIndex}"
  final ModeId modeId;
  final int slotIndex;

  final TimerStatus status;

  /// Epoch milliseconds, UTC.
  final int? startedAtEpochMs;
  final int? endAtEpochMs;

  /// Remaining milliseconds captured when paused.
  final int? remainingMsAtPause;

  const TimerSession({
    required this.timerId,
    required this.modeId,
    required this.slotIndex,
    required this.status,
    required this.startedAtEpochMs,
    required this.endAtEpochMs,
    required this.remainingMsAtPause,
  });
}
```

## 9.3 ITimerService (engine + persistence orchestration)

```dart
abstract interface class ITimerService {
  /// Initializes storage, loads last sessions, and performs recovery.
  Future<void> init();

  /// Emits the active grid set (mode) and all 9 sessions.
  Stream<(TimerGridSet grid, List<TimerSession> sessions)> watchGridState();

  /// Returns current snapshot synchronously (for cold start UI).
  (TimerGridSet grid, List<TimerSession> sessions) getSnapshot();

  /// Starts a timer for the given slot. Must enforce "start protection"
  /// (confirm when other timers are running) at UI layer, not here.
  Future<void> start({
    required ModeId modeId,
    required int slotIndex,
  });

  /// Pauses a running timer.
  Future<void> pause(TimerId timerId);

  /// Resumes a paused timer.
  Future<void> resume(TimerId timerId);

  /// Resets a timer back to idle.
  Future<void> reset(TimerId timerId);

  /// Stops ringing and transitions to idle.
  Future<void> stopRinging(TimerId timerId);

  /// Switches mode. Caller must confirm when any timer is running.
  Future<void> switchMode(ModeId modeId);

  /// Force recompute remaining time from system clock (e.g., app resume).
  Future<void> refreshFromClock();

  /// Called when a scheduled "time up" event is received via notification.
  Future<void> handleTimeUpEvent({
    required TimerId timerId,
    required int firedAtEpochMs,
  });
}
```

## 9.4 INotificationService (channels, scheduling, callbacks)

```dart
abstract interface class INotificationService {
  /// Must be called before scheduling any notifications.
  Future<void> init();

  /// Creates/updates channels where applicable. Note: channel sound cannot
  /// be changed after creation; channel-per-soundKey is required.
  Future<void> ensureAndroidChannels({
    required Set<String> soundKeys,
  });

  /// Android 13+ permission.
  Future<bool> requestPostNotificationsPermission();

  /// Android 14+ exact alarm special access request (best-effort).
  Future<bool> requestExactAlarmPermission();

  /// Android 14+ full-screen intent special access request (best-effort).
  Future<bool> requestFullScreenIntentPermission();

  /// Schedules a notification for timer end.
  /// Implementer must choose exact/inexact schedule mode based on permission.
  Future<void> scheduleTimeUp({
    required TimerSession session,
    required TimerConfig config,
  });

  /// Cancels the scheduled notification for a timer.
  Future<void> cancelTimeUp({
    required TimerId timerId,
    required int slotIndex,
  });

  /// Cancels all scheduled notifications (e.g., mode switch confirmation).
  Future<void> cancelAll();

  /// Stream of notification events (tap, action, full-screen trigger).
  Stream<NotificationEvent> events();
}

class NotificationEvent {
  final NotificationEventType type;
  final String payloadJson;
  final String? actionId; // null if body tap
  const NotificationEvent({
    required this.type,
    required this.payloadJson,
    this.actionId,
  });
}
```

## 9.5 IAudioService (ringtone loop + interruption)

```dart
abstract interface class IAudioService {
  /// Preloads audio assets if needed.
  Future<void> init();

  /// Plays the ringtone in a loop. Must interrupt any currently playing sound.
  Future<void> playLoop({
    required String soundKey,
  });

  /// Stops any playing sound immediately.
  Future<void> stop();

  /// Whether audio is currently playing.
  Future<bool> isPlaying();
}
```

## 9.6 ITtsService (interruptible speech)

```dart
abstract interface class ITtsService {
  /// Initializes TTS engine and applies platform defaults.
  Future<void> init();

  /// Speaks text. Must interrupt any current utterance by default.
  Future<void> speak({
    required String text,
    required String localeTag, // e.g. "zh-CN", "en-US"
    bool interrupt = true,
  });

  /// Stops speaking immediately.
  Future<void> stop();
}
```

## 9.7 IPermissionGuideService (onboarding navigation)

```dart
abstract interface class IPermissionGuideService {
  /// Returns whether the app is allowed to show notifications (Android 13+).
  Future<bool> canPostNotifications();

  /// Returns whether exact alarms are permitted (Android 14+ special access).
  Future<bool> canScheduleExactAlarms();

  /// Returns whether full-screen intents are permitted (Android 14+ special access).
  Future<bool> canUseFullScreenIntent();

  /// Opens system settings pages (best-effort, platform-specific).
  Future<void> openNotificationSettings();
  Future<void> openExactAlarmSettings();
  Future<void> openFullScreenIntentSettings();
  Future<void> openBatteryOptimizationSettings();
}
```

## 9.8 IModeService (multi preset management)

```dart
abstract interface class IModeService {
  Future<void> init();

  Stream<List<TimerGridSet>> watchAllModes();
  Stream<TimerGridSet> watchActiveMode();

  Future<List<TimerGridSet>> listModes();
  Future<TimerGridSet> getActiveMode();

  Future<void> createMode(TimerGridSet gridSet);
  Future<void> updateMode(TimerGridSet gridSet);
  Future<void> deleteMode(ModeId modeId);

  /// Caller must confirm if timers are running.
  Future<void> setActiveMode(ModeId modeId);
}
```

---

## 10. Notification Callback Wiring (Template)

> This is the minimum wiring needed to satisfy the “action callback protocol”.

```dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // NOTE: Keep this function top-level.
  // NOTE: Do not access UI code here.
  // Parse payload + persist minimal state if needed.
}

Future<void> initNotifications({
  required void Function(NotificationResponse r) onForegroundResponse,
}) async {
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');

  const initSettings = InitializationSettings(android: androidInit);

  await fln.initialize(
    initSettings,
    onDidReceiveNotificationResponse: onForegroundResponse,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
}

Map<String, dynamic> parsePayload(NotificationResponse r) {
  final raw = r.payload ?? '';
  if (raw.isEmpty) return const <String, dynamic>{};
  return jsonDecode(raw) as Map<String, dynamic>;
}
```

---

## 11. “Time Up” Notification Construction Rules (Android)

When building the time-up notification details, MUST set:

* `importance = Importance.max`
* `priority = Priority.max`
* `category = AndroidNotificationCategory.alarm`
* `visibility = NotificationVisibility.public`
* `fullScreenIntent = true` (best-effort)
* Channel ID = `gt.alarm.timeup.<soundKey>.v1`

Also remember:

* If full-screen is triggered, handle it like a tap callback.
* If exact alarm permission not granted, schedule inexact mode. `AndroidScheduleMode` semantics are defined in the API docs. ([Dart packages][7])

