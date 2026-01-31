# 《大湾区徒步》Godot游戏开发技术架构文档

**文档类型**：技术架构文档  
**适用对象**：初级开发工程师  
**Godot版本**：4.5.1+  
**发布平台**：Steam（PC端）  
**文档版本**：v2.0  
**编制日期**：2026年01月30日  
**责任团队**：Godot架构及技术专家团队  

---

## 文档导读

### 文档定位

本文档为《大湾区徒步》Godot 4.5.1 PC端开发的标准技术架构文档，面向流动性强的初级开发工程师。文档采用分层架构设计，通过模块化、标准化、规范化的方式，降低学习曲线，确保开发团队能够快速上手并保持代码质量一致性。

本文档基于《游戏设计文档 v7.0最终版》编写，完整整合了累积爬升、补给系统、疲劳系统、上坡下坡机制等最新设计内容。

### 核心阅读路径

```
阅读路径建议：

【必读模块】（3-4天）
├─ 第一章：整体架构设计
│   ├─ 1.1 架构原则
│   ├─ 1.2 技术栈选型
│   └─ 1.3 项目结构规范
└─ 第二章：核心系统设计
    ├─ 2.1 卡牌系统架构
    ├─ 2.2 属性系统架构
    └─ 2.3 经济系统架构

【进阶模块】（5-7天）
├─ 第三章：地形与环境系统架构
│   ├─ 3.1 地形系统架构
│   ├─ 3.2 上坡下坡机制架构
│   └─ 3.3 天气系统架构
├─ 第四章：补给与疲劳系统架构
│   ├─ 4.1 补给系统架构
│   └─ 4.2 疲劳系统架构
├─ 第五章：UI/UX架构设计
│   ├─ 5.1 UI场景架构
│   └─ 5.2 交互系统设计
├─ 第六章：数据持久化架构
│   ├─ 6.1 存档系统设计
│   └─ 6.2 配置系统设计
└─ 第七章：性能优化架构
    ├─ 7.1 性能监控设计
    └─ 7.2 优化策略设计

【高级模块】（8-10天）
├─ 第八章：Steam平台集成
│   ├─ 8.1 成就系统设计
│   └─ 8.2 排行榜系统设计
├─ 第九章：工具链架构
│   ├─ 9.1 godot_parser集成
│   └─ 9.2 自动化构建流程
└─ 第十章：开发规范
    ├─ 10.1 代码规范
    └─ 10.2 工作流程规范
```

### 术语表

| 术语 | 说明 |
|------|------|
| **AutoLoad** | Godot的单例自动加载机制，用于全局管理器 |
| **SceneTree** | Godot的场景树，管理所有节点的层级关系 |
| **Signal** | Godot的信号机制，用于节点间通信 |
| **Tween** | Godot的补间动画系统，用于平滑过渡效果 |
| **Extension** | Godot的扩展机制，用于集成C++模块 |
| **PC端** | 个人电脑平台（Windows），指本项目的目标平台 |
| **Steam平台** | Valve公司的数字发行平台 |
| **Steamworks SDK** | Steam平台的官方开发工具包 |
| **累积爬升** | 所有上坡路段的垂直上升高度总和，局外稀有货币 |
| **补给系统** | 管理水、运动饮料、巧克力等补给的消耗与恢复 |
| **疲劳系统** | 管理疲劳积累、休息次数、疲劳突破机制 |
| **上坡下坡** | 区分上坡（计入累积爬升）和下坡（不计入累积爬升）的地形机制 |

---

## 第一章：整体架构设计

### 1.1 架构原则

#### 1.1.1 核心设计原则

**分层原则**：系统按职责分为表现层、逻辑层、数据层三层，每层只关注自身职责，通过明确接口进行通信。

**模块化原则**：每个功能模块独立封装，低耦合高内聚，支持并行开发和独立测试。

**数据驱动原则**：游戏数据（卡牌属性、关卡配置、数值平衡）通过配置文件管理，支持热更新和版本控制。

**性能优先原则**：针对PC端特性实施性能优化策略，确保在高分辨率和高刷新率下稳定运行。

**标准化原则**：统一命名规范、代码风格、接口定义，降低人员变动对项目的影响。

**真实化原则**：基于真实路线（麦理浩径、澳门路线）设计关卡和数值体系，确保游戏体验贴近真实徒步。

#### 1.1.2 架构分层定义

```
架构分层模型：

┌─────────────────────────────────────────────────────────────────┐
│  表现层（Presentation Layer）                                  │
│  职责：UI渲染、动画播放、音效播放、用户输入处理                  │
│  技术实现：Godot Control节点、Tween动画、AudioStreamPlayer2D    │
├─────────────────────────────────────────────────────────────────┤
│  逻辑层（Logic Layer）                                         │
│  职责：游戏逻辑、规则判定、状态管理、事件处理                    │
│  技术实现：GDScript脚本、状态机、事件总线、信号机制              │
├─────────────────────────────────────────────────────────────────┤
│  数据层（Data Layer）                                           │
│  职责：数据存储、配置加载、存档管理、网络同步                    │
│  技术实现：Resource资源、JSON配置、文件系统、Steam云同步        │
└─────────────────────────────────────────────────────────────────┘
```

**跨层通信规范**：

- **表现层 → 逻辑层**：通过用户输入事件（InputEvent）和信号（Signal）传递用户操作
- **逻辑层 → 表现层**：通过信号（Signal）通知状态变化，通过Tween触发动画
- **逻辑层 → 数据层**：通过数据管理器（DataManager）读写配置和存档
- **数据层 → 逻辑层**：通过事件通知（EventBus）通知数据变化

#### 1.1.3 模块划分规范

**核心模块定义**：

| 模块名称 | 职责范围 | 依赖模块 | 被依赖模块 |
|---------|---------|---------|-----------|
| **GameManager** | 全局状态管理、生命周期控制 | StateManager、SaveManager | 所有模块 |
| **CardSystem** | 卡牌生成、穿越判定、连击计算 | AttributeSystem、ComboSystem、TerrainSystem | BattleUI、ComboUI |
| **AttributeSystem** | 五维属性管理、恢复计算、体能消耗计算 | SaveManager、EconomySystem | CardSystem、TerrainSystem、SupplySystem |
| **ComboSystem** | 连击检测、奖励计算 | PhotoCardSystem | CardSystem、ComboUI |
| **EconomySystem** | 经济系统管理、商店交易 | SaveManager | ShopUI、PlayerData |
| **TerrainSystem** | 地形障碍管理、上坡下坡机制 | AttributeSystem | CardSystem、BattleUI |
| **SupplySystem** | 补给系统管理、补给点管理 | EconomySystem | CardSystem、ShopUI |
| **FatigueSystem** | 疲劳系统管理、休息机制 | AttributeSystem | CardSystem、BattleUI |
| **WeatherSystem** | 天气系统管理、环境影响 | CardSystem、AttributeSystem | BattleUI |
| **PhotoCardSystem** | 照片卡系统、流派加成 | ComboSystem | CardSystem、ShopUI |
| **SteamManager** | Steam平台集成、成就解锁 | SaveManager | AchievementSystem、LeaderboardSystem |
| **UIManager** | UI场景管理、交互控制 | GameManager | 所有UI模块 |
| **AudioManager** | 音频管理、音效播放 | GameManager | 所有模块 |
| **PerformanceMonitor** | 性能监控、自动优化 | - | 所有模块 |

**模块通信规范**：

- **依赖方向**：只能单向依赖，禁止循环依赖
- **接口定义**：模块间通过信号（Signal）和接口（Interface）通信
- **数据隔离**：模块间不直接访问内部数据，通过公开方法访问
- **错误处理**：模块内部处理错误，通过信号通知上层

### 1.2 技术栈选型

#### 1.2.1 核心技术栈

| 技术领域 | 选型方案 | 版本要求 | 选型理由 |
|---------|---------|---------|---------|
| **游戏引擎** | Godot Engine | 4.5.1+ | 开源免费、轻量级、适合2D游戏、PC端优化良好 |
| **主要语言** | GDScript | 4.x兼容版 | Godot原生语言、学习曲线平缓、开发效率高 |
| **辅助语言** | C# | 10.0+ | 性能关键模块、Steam SDK集成 |
| **扩展语言** | C++（GDExtension） | 最新版 | Steam SDK底层调用、性能极致优化 |
| **卡牌UI框架** | Card Framework | v1.3.1+ | 快速搭建拖拽和容器系统、减少UI开发工作量 |
| **场景解析工具** | godot_parser | 最新版 | 自动化场景文件管理、提升开发效率 |
| **数据格式** | JSON/TSCN | - | 轻量级、易解析、Godot原生支持 |
| **版本控制** | Git + Git LFS | - | 工业界标准、大文件跟踪支持 |

#### 1.2.2 PC端专用技术栈

| 技术领域 | 选型方案 | 版本要求 | 选型理由 |
|---------|---------|---------|---------|
| **分辨率支持** | 1920x1080 / 2560x1440 / 3840x2160 | - | 覆盖主流PC显示器 |
| **刷新率支持** | 60Hz / 120Hz / 144Hz | - | 支持电竞显示器 |
| **音频系统** | 5.1声道环绕声 | - | 沉浸式体验 |
| **Steam集成** | Steamworks SDK | 最新版 | PC平台发布必需 |
| **截图功能** | Steam原生截图 | - | 无需自行实现 |

#### 1.2.3 第三方库集成规范

**Card Framework集成规范**：

- **用途**：用于UI交互层，提供拖拽、容器等基础功能
- **集成方式**：作为Godot插件（Addon）集成到项目
- **版本锁定**：使用v1.3.1版本，避免自动更新导致兼容性问题
- **扩展方式**：通过继承Card、CardContainer等基类进行自定义扩展
- **限制范围**：仅用于UI交互，不涉及核心游戏逻辑
- **降级方案**：保留完全原生开发的降级方案，以应对框架不满足需求的情况

**godot_parser集成规范**：

- **用途**：用于工具链层，自动化生成场景文件（.tscn）
- **集成方式**：作为Python工具脚本，通过CI/CD流程调用
- **使用场景**：程序化生成战斗场景、UI场景、配置文件
- **开发语言**：Python 3.9+
- **输出格式**：Godot标准.tscn和.tres格式
- **验证流程**：生成后需在Godot编辑器中验证正确性

### 1.3 项目结构规范

#### 1.3.1 标准目录结构

```
项目标准目录结构：

res/
├── addons/                          # 插件目录
│   ├── card_framework/              # Card Framework插件
│   ├── steam_integration/            # Steam集成插件
│   └── performance_monitor/          # PC端性能监控插件
├── assets/                           # 资源目录
│   ├── images/                       # 图片资源
│   │   ├── cards/                    # 卡牌图片（512x720）
│   │   ├── ui/                       # UI素材
│   │   ├── backgrounds/              # 背景图
│   │   └── icons/                    # 图标
│   ├── audio/                        # 音频资源
│   │   ├── music/                    # 背景音乐
│   │   ├── sfx/                      # 音效
│   │   └── voice/                    # 语音
│   ├── fonts/                        # 字体资源
│   ├── shaders/                      # 着色器资源
│   └── data/                         # 数据文件
│       ├── cards/                    # 卡牌配置JSON
│       ├── config/                   # 配置文件
│       ├── levels/                   # 关卡配置JSON（真实路线数据）
│       ├── routes/                   # 路线配置JSON（麦理浩径、澳门路线）
│       ├── localization/             # 本地化文件
│       └── culture/                  # 文化元素数据
├── scenes/                           # 场景文件目录
│   ├── main/                         # 主场景
│   ├── battle/                       # 战斗场景
│   ├── journey/                      # 路线场景
│   └── result/                       # 结算场景
├── scripts/                          # 核心脚本目录
│   ├── autoloads/                    # AutoLoad单例管理器
│   │   ├── game_manager.gd
│   │   ├── attribute_system.gd
│   │   ├── economy_system.gd
│   │   ├── card_system.gd
│   │   ├── combo_system.gd
│   │   ├── terrain_system.gd
│   │   ├── supply_system.gd
│   │   ├── fatigue_system.gd
│   │   ├── weather_system.gd
│   │   ├── photo_card_system.gd
│   │   ├── ui_manager.gd
│   │   ├── audio_manager.gd
│   │   ├── save_manager.gd
│   │   ├── steam_manager.gd
│   │   ├── event_bus.gd
│   │   └── performance_monitor.gd
│   ├── core/                         # 核心系统
│   ├── gameplay/                     # 玩法逻辑
│   ├── ui/                           # UI逻辑
│   ├── data/                         # 数据管理
│   └── utils/                        # 工具类
├── tools/                            # 工具脚本目录
│   ├── scene_builder.py              # 场景构建工具
│   ├── card_generator.py             # 卡牌生成工具
│   ├── level_generator.py            # 关卡生成工具（基于真实路线）
│   └── steam_config_generator.py     # Steam配置生成工具
├── tests/                            # 测试目录
│   ├── unit/                         # 单元测试
│   ├── integration/                  # 集成测试
│   └── performance/                  # 性能测试
├── .gitignore                        # Git忽略文件
├── .editorconfig                     # 编辑器配置
├── export_presets.cfg                # Steam导出预设
└── project.godot                     # Godot项目配置文件
```

#### 1.3.2 命名规范

**文件命名规范**：

- **场景文件（.tscn）**：使用下划线命名法，如 `main_menu.tscn`、`battle_scene.tscn`
- **脚本文件（.gd）**：使用下划线命名法，如 `game_manager.gd`、`card_system.gd`
- **资源文件**：使用下划线命名法，分类前缀，如 `card_scenery_001.png`、`bg_battle_001.png`
- **配置文件（.json/.tres）**：使用下划线命名法，如 `card_config.json`、`game_settings.tres`

**类命名规范**：

- **GDScript类**：使用帕斯卡命名法（PascalCase），如 `GameManager`、`CardSystem`
- **C#类**：使用帕斯卡命名法（PascalCase），与GDScript保持一致
- **接口**：使用前缀 `I`，如 `ISaveable`、`IPerformanceMonitored`
- **枚举**：使用帕斯卡命名法（PascalCase），如 `CardType`、`TerrainType`

**变量命名规范**：

- **局部变量**：使用蛇形命名法（snake_case），如 `card_count`、`player_level`
- **成员变量**：使用蛇形命名法（snake_case），如 `current_layer`、`max_combo`
- **常量**：使用大写下划线命名法（SCREAMING_SNAKE_CASE），如 `MAX_COMBO`、`FPS_TARGET`
- **私有变量**：使用前缀 `_`，如 `_private_var`、`_internal_data`

**方法命名规范**：

- **公开方法**：使用蛇形命名法（snake_case），如 `generate_level()`、`save_game()`
- **私有方法**：使用前缀 `_`，如 `_generate_card()`、`_save_data()`
- **回调方法**：使用前缀 `on_`，如 `_on_card_crossed()`、`on_game_paused()`
- **布尔方法**：使用前缀 `is_`、`has_`、`can_`，如 `is_crossed()`、`has_achievement()`、`can_save()`

**信号命名规范**：

- **信号名称**：使用蛇形命名法（snake_case），动词+名词形式
- **状态变化信号**：`attribute_changed`、`game_started`、`level_completed`
- **事件信号**：`card_crossed`、`combo_triggered`、`achievement_unlocked`

#### 1.3.3 代码注释规范

**文件头注释**：

```gdscript
# 文件头注释模板
## 文件名称：game_manager.gd
## 所属模块：核心系统
## 职责描述：管理游戏全局状态，协调各子系统工作
## 作者：开发团队
## 创建日期：2026-01-30
## 最后修改：2026-01-30

extends Node
class_name GameManager
```

**类注释**：

```gdscript
## 类名称：CardSystem
## 职责描述：管理卡牌生成、穿越判定、连击计算等卡牌相关逻辑
## 依赖模块：AttributeSystem、ComboSystem、TerrainSystem
class_name CardSystem extends Node
```

**方法注释**：

```gdscript
## 方法：generate_level
## 职责：根据关卡配置生成卡牌层
## 参数：
##   - level: 关卡等级
##   - play_count: 游玩次数
## 返回值：无
## 示例：
##   card_system.generate_level(1, 1)
func generate_level(level: int, play_count: int) -> void:
    # 实现代码
    pass
```

**复杂逻辑注释**：

```gdscript
# 计算体能消耗
# 逻辑说明：
# 1. 体能消耗 = (徒步距离 / 20) + (累积爬升 / 20)
# 2. 徒步距离单位：公里
# 3. 累积爬升单位：米
# 4. 体能消耗结果：点
# 5. 基准：初始体能100 = 20公里徒步 或 2000米累积爬升
var stamina_cost = (hiking_distance / 20.0) + (cumulative_elevation / 20.0)
```

### 1.4 全局架构图

```
系统全局架构图：

┌─────────────────────────────────────────────────────────────────┐
│  AutoLoad全局管理器层                                          │
│  ├─ GameManager：游戏全局状态管理、生命周期控制                   │
│  ├─ StateManager：状态机管理、场景转换                          │
│  ├─ SaveManager：存档管理、Steam云同步                          │
│  ├─ AudioManager：音频管理、5.1声道支持                         │
│  ├─ UIManager：UI场景管理、交互控制                            │
│  ├─ EventBus：事件总线、模块通信                              │
│  ├─ PerformanceMonitor：性能监控、自动优化                      │
│  ├─ SteamManager：Steam平台集成、成就系统                      │
│  ├─ AttributeSystem：五维属性管理、体能消耗计算                  │
│  ├─ EconomySystem：经济系统管理（徒步数、累积爬升、环保值）        │
│  └─ ConfigManager：配置管理、关卡配置、真实路线数据                │
├─────────────────────────────────────────────────────────────────┤
│  核心系统层                                                     │
│  ├─ CardSystem：卡牌系统、穿越判定、连击计算                     │
│  ├─ AttributeSystem：五维属性管理、恢复计算、体能消耗计算         │
│  ├─ ComboSystem：连击检测、奖励计算                            │
│  ├─ EconomySystem：经济系统管理、商店交易                       │
│  ├─ TerrainSystem：地形障碍系统、上坡下坡机制                    │
│  ├─ SupplySystem：补给系统管理、补给点、补给计算                 │
│  ├─ FatigueSystem：疲劳系统管理、休息机制、疲劳突破               │
│  ├─ WeatherSystem：天气系统、环境影响                          │
│  └─ PhotoCardSystem：照片卡系统、流派加成                      │
├─────────────────────────────────────────────────────────────────┤
│  数据管理层                                                     │
│  ├─ PlayerData：玩家数据、配置管理                             │
│  ├─ ConfigData：配置数据、难度设置                             │
│  ├─ RouteData：路线数据（麦理浩径、澳门路线）                    │
│  ├─ AchievementData：成就数据、解锁状态                         │
│  └─ LocalizationData：本地化数据、多语言支持                   │
├─────────────────────────────────────────────────────────────────┤
│  UI场景层（PC端布局）                                           │
│  ├─ MainMenu：主菜单场景、键盘快捷键                            │
│  ├─ CharacterSelection：角色选择场景、键盘导航                │
│  ├─ UpgradeMenu：升级菜单场景、工具提示                        │
│  ├─ BattleScene：战斗场景、鼠标悬停、键盘快捷键                 │
│  ├─ JourneyScene：路线场景、高分辨率显示                        │
│  ├─ VictoryScene：胜利结算场景、Steam成就弹窗                  │
│  └─ SettingsMenu：设置场景、图形设置、音频设置                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 第二章：核心系统设计

### 2.1 卡牌系统架构

#### 2.1.1 系统职责定义

**核心职责**：

- **卡牌生成**：根据关卡配置、难度系数、真实路线数据，程序化生成卡牌序列
- **穿越判定**：处理用户点击、长按等交互，判断是否满足穿越条件
- **连击计算**：检测连击状态，计算连击奖励，触发连击效果
- **层完成检测**：检测当前层是否全部穿越，触发层完成事件
- **卡牌状态管理**：管理卡牌的穿越状态、悬停状态等

**职责边界**：

- **不负责**：属性消耗计算（由AttributeSystem负责）
- **不负责**：地形特殊效果处理（由TerrainSystem负责）
- **不负责**：连击奖励发放（由ComboSystem负责）
- **不负责**：存档管理（由SaveManager负责）
- **不负责**：UI渲染（由UIManager负责）

#### 2.1.2 系统架构设计

```
卡牌系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  CardSystem（卡牌系统管理器）                                  │
│  职责：协调卡牌生成、穿越判定、层管理                           │
├─────────────────────────────────────────────────────────────────┤
│  ├─ CardGenerator（卡牌生成器）                                 │
│  │   职责：根据配置生成卡牌序列                                   │
│  │   输入：关卡等级、游玩次数、难度系数、真实路线数据               │
│  │   输出：卡牌数据数组                                          │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ LayerContainer（分层容器，继承CardContainer）              │
│  │   职责：管理单层卡牌、计算卡牌位置、检测层完成                   │
│  │   扩展：正三角布局、海拔显示、层高亮/变暗、累积爬升显示           │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ HikingCard（徒步卡牌，继承Card）                             │
│  │   职责：处理卡牌交互、管理穿越状态、播放穿越效果                 │
│  │   扩展：鼠标悬停效果、长按检测、地形确认框、下坡膝盖损伤效果      │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ CardPool（卡牌对象池）                                       │
│      职责：管理卡牌对象复用、优化内存分配                          │
│      实现：预分配卡牌对象、动态扩展对象池                          │
└─────────────────────────────────────────────────────────────────┘
```

#### 2.1.3 数据结构设计

**卡牌类型枚举**：

```gdscript
## 卡牌类型枚举
enum CardType {
    SCENERY,      # 风景卡
    TERRAIN,      # 地形障碍卡
    RESOURCE,     # 资源卡
    ENVIRONMENT   # 环境卡
}
```

**地形类型枚举**：

```gdscript
## 地形类型枚举（v2.0更新：增加下坡地形）
enum TerrainType {
    FLAT_ROAD,       # 平坦道路
    UPHILL_GENTLE,   # 缓坡上坡
    UPHILL_STEEP,    # 陡坡上坡
    ROCKY_PATH,      # 乱石路
    STREAM,          # 溪流
    CLIFF_PATH,      # 悬崖栈道
    DOWNHILL_GENTLE, # 缓坡下坡（新增）
    DOWNHILL_STEEP   # 陡坡下坡（新增）
}
```

**卡牌数据结构**：

```gdscript
## 卡牌数据结构
class CardData:
    var id: String              # 卡牌唯一标识
    var name: String            # 卡牌名称
    var description: String     # 卡牌描述
    var card_type: CardType     # 卡牌类型
    var texture: Texture2D      # 卡牌纹理
    var stamina_cost: float     # 体能消耗
    var cumulative_elevation: float  # 累积爬升（米，仅上坡）
    var is_downhill: bool       # 是否为下坡地形（不计入累积爬升）
    var eco_value_reward: int   # 环保值奖励
    var hiking_number_reward: int  # 徒步数奖励
    var is_crossed: bool        # 是否已穿越
    var extra_data: Dictionary  # 扩展数据（如地形类型、特殊效果等）
    
    func _init(id: String, name: String, card_type: CardType):
        self.id = id
        self.name = name
        self.card_type = card_type
        self.extra_data = {}
```

**层级数据结构**：

```gdscript
## 层级数据结构（v2.0更新：增加累积爬升）
class LayerData:
    var layer_index: int        # 层级索引
    var altitude: float         # 海拔值（米）
    var cumulative_elevation: float  # 累积爬升（米）
    var max_cards: int          # 最大卡牌数
    var hiking_distance: float  # 徒步距离（公里，每层约2公里）
    var cards: Array[CardData]  # 卡牌数组
    
    func _init(index: int):
        self.layer_index = index
        self.altitude = 0.0
        self.cumulative_elevation = 0.0
        self.hiking_distance = 2.0
        self.cards = []
```

#### 2.1.4 接口定义

**卡牌系统公开接口**：

```gdscript
## 卡牌系统公开接口定义

# 卡牌生成接口（v2.0更新：支持真实路线数据）
## 参数：
##   - route_id: 路线标识（如"mac_lehose_stage_1"、"luhuang_northeast"）
##   - level: 关卡等级
##   - play_count: 游玩次数
func generate_level_from_route(route_id: String, level: int, play_count: int) -> void

# 卡牌穿越接口
## 参数：
##   - card: 要穿越的卡牌
## 返回值：是否穿越成功
func attempt_cross(card: HikingCard) -> bool

# 层完成检测接口
## 参数：
##   - layer_index: 层级索引
## 返回值：是否全部穿越
func is_layer_completed(layer_index: int) -> bool

# 当前层索引获取接口
## 返回值：当前层索引
func get_current_layer_index() -> int

# 卡牌数量获取接口
## 参数：
##   - layer_index: 层级索引
## 返回值：卡牌数量
func get_card_count(layer_index: int) -> int

# 获取关卡数据接口（v2.0新增）
## 参数：
##   - route_id: 路线标识
## 返回值：关卡数据字典
func get_route_data(route_id: String) -> Dictionary

# 获取当前累积爬升接口（v2.0新增）
## 返回值：当前累积爬升（米）
func get_current_cumulative_elevation() -> float
```

**信号定义**：

```gdscript
## 卡牌系统信号定义

# 卡牌穿越信号
## 参数：card: 穿越的卡牌
signal card_crossed(card: HikingCard)

# 层完成信号
## 参数：layer_index: 完成的层级索引
signal layer_completed(layer_index: int)

# 所有层完成信号
signal all_layers_completed()

# 累积爬升更新信号（v2.0新增）
## 参数：cumulative_elevation: 当前累积爬升
signal cumulative_elevation_updated(cumulative_elevation: float)

# PC端：卡牌悬停信号
## 参数：card: 悬停的卡牌
signal card_hovered(card: HikingCard)

# PC端：卡牌悬停取消信号
## 参数：card: 取消悬停的卡牌
signal card_unhovered(card: HikingCard)

# 膝盖损伤信号（v2.0新增）
## 参数：damage_amount: 损伤程度
signal knee_damage_triggered(damage_amount: float)
```

#### 2.1.5 核心算法描述

**卡牌生成算法（v2.0更新：支持真实路线数据）**：

**算法目标**：根据关卡配置、游玩次数、真实路线数据，生成符合规则要求的卡牌序列

**输入参数**：
- `route_id`：路线标识（如"mac_lehose_stage_1"、"luhuang_northeast"）
- `level`：关卡等级（1-10）
- `play_count`：游玩次数（1+）
- `difficulty_coefficient`：难度系数（0.8-1.25）

**输出结果**：卡牌数据数组

**算法步骤**：

1. **加载真实路线数据**：
   - 从ConfigManager加载路线配置
   - 获取路线的：总距离、总爬升、每层数量、地形分布
   - 示例：路环东北步行径（4.3km，60m爬升，3层）

2. **确定关卡配置**：
   - 根据路线数据确定关卡层数
   - 根据游玩次数和关卡等级确定难度系数
   - 根据难度系数计算地形障碍率、资源卡率、环境卡率

3. **计算卡牌权重**：
   - 初始权重：风景卡0.4、地形卡0.3、资源卡0.2、环境卡0.1
   - 根据难度系数调整权重（地形卡权重随难度增加）
   - 归一化权重（确保总和为1.0）

4. **生成每层卡牌**：
   - 根据层级和路线数据确定卡牌数量
   - 循环生成每张卡牌：
     - 应用保底机制：每层至少1张风景卡（最后一张）
     - 应用防连卡机制：禁止连续3张同类型卡牌
     - 根据权重随机选择卡牌类型
     - 根据类型随机选择具体卡牌
     - 根据路线数据设置地形类型（上坡/下坡）

5. **验证卡牌序列**：
   - 验证每层至少1张风景卡
   - 验证无连续3张同类型卡牌
   - 验证累积爬升符合路线数据（误差±10%）
   - 验证地形卡数量符合配置要求
   - 如果验证失败，重新生成该层

**伪代码**：

```
算法：generate_card_sequence(route_id, level, play_count, difficulty_coefficient)
输入：route_id（路线标识），level（关卡等级），play_count（游玩次数），difficulty_coefficient（难度系数）
输出：card_sequence（卡牌序列）

1. 加载真实路线数据
   route_data ← ConfigManager.get_route_data(route_id)
   total_distance ← route_data.total_distance
   total_elevation ← route_data.total_elevation
   layer_configs ← route_data.layer_configs
   terrain_distribution ← route_data.terrain_distribution

2. 初始化卡牌序列
   card_sequence ← 空数组
   current_cumulative_elevation ← 0

3. 对于每一层（从第1层到total_layers层）
   3.1 获取当前层配置
       layer_config ← layer_configs[layer_index]
       card_count ← layer_config.card_count
       layer_distance ← layer_config.distance
       layer_elevation ← layer_config.elevation
       
   3.2 初始化生成状态
       sequence ← 空数组
       last_two_types ← 空数组（记录最后两张卡牌类型）
       layer_elevation_sum ← 0
       
   3.3 循环生成每张卡牌（从第1张到第card_count张）
       3.3.1 检查是否为最后一张卡牌
           如果是最后一张且sequence中无风景卡：
               生成风景卡（保底机制）
           否则：
               选择卡牌类型（考虑防连卡机制）
       
       3.3.2 生成卡牌数据
           根据卡牌类型和difficulty_coefficient生成具体卡牌
           如果是地形卡：
               根据terrain_distribution选择地形类型
               计算累积爬升：
                   如果是上坡：累积爬升 = terrain_type.elevation_gain
                   如果是下坡：累积爬升 = 0
                   如果是平路：累积爬升 = 0
                   layer_elevation_sum += 累积爬升
       
       3.3.3 添加到sequence
           sequence.append(card_data)
       
       3.3.4 更新类型记录
           last_two_types.append(card_data.card_type)
           如果last_two_types.size() > 2：
               last_two_types.pop_front()
   
   3.4 验证sequence
       如果sequence中无风景卡：
           重新生成该层（回到3.3）
       
       如果存在连续3张同类型卡牌：
           重新生成该层（回到3.3）
       
       如果abs(layer_elevation_sum - layer_elevation) / layer_elevation > 0.1：
           重新生成该层（回到3.3）
   
   3.5 添加到card_sequence
       card_sequence.append(sequence)
       current_cumulative_elevation += layer_elevation_sum

4. 返回card_sequence
```

**穿越判定算法（v2.0更新：增加下坡处理）**：

**算法目标**：判断卡牌是否可以穿越，处理不同类型的穿越条件，包括下坡膝盖损伤

**输入参数**：
- `card`：要穿越的卡牌
- `player_stamina`：玩家当前体能值

**输出结果**：穿越是否成功

**算法步骤**：

1. **获取卡牌信息**：
   - 获取卡牌类型（风景卡/地形卡/资源卡/环境卡）
   - 获取地形类型（如果是地形卡）
   - 获取体能消耗
   - 获取累积爬升（仅上坡）
   - 获取特殊效果

2. **检查穿越条件**：
   - **风景卡/资源卡/环境卡**：
     - 无条件穿越
     - 返回成功
   
   - **地形卡**：
     - **平坦道路**：
       - 无条件穿越
       - 返回成功
     - **缓坡上坡/陡坡上坡/乱石路/溪流**：
       - 需要长按1.5秒
       - 检查长按是否完成
       - 如果完成，进入步骤3
       - 如果未完成，返回失败
     - **悬崖栈道**：
       - 需要长按1.5秒
       - 检查长按是否完成
       - 如果完成，显示确认框
       - 等待用户确认
       - 如果确认，进入步骤3
       - 如果取消，返回失败
     - **缓坡下坡/陡坡下坡**（新增）：
       - 点击即穿越
       - 进入步骤3

3. **检查体能消耗**：
   - 比较玩家当前体能与卡牌消耗
   - 如果体能不足，返回失败
   - 如果体能充足，进入步骤4

4. **执行穿越**：
   - 消耗体能
   - 标记卡牌为已穿越
   - 更新累积爬升（仅上坡）
   - 检查下坡膝盖损伤（仅陡坡下坡）
   - 应用特殊效果
   - 播放穿越效果
   - 返回成功

**伪代码**：

```
算法：attempt_cross(card, player_stamina)
输入：card（卡牌），player_stamina（玩家当前体能）
输出：is_crossed（是否穿越成功）

1. 获取卡牌信息
   card_type ← card.card_type
   terrain_type ← card.terrain_type（如果是地形卡）
   stamina_cost ← card.stamina_cost
   cumulative_elevation ← card.cumulative_elevation（仅上坡）
   is_downhill ← card.is_downhill
   special_effects ← card.special_effects

2. 检查穿越条件
   如果card_type是SCENERY或RESOURCE或ENVIRONMENT：
       进入步骤3
   否则如果card_type是TERRAIN：
       如果terrain_type是FLAT_ROAD：
           进入步骤3
       否则如果terrain_type是UPHILL_GENTLE或UPHILL_STEEP或ROCKY_PATH或STREAM：
           如果长按时间 >= 1.5秒：
               进入步骤3
           否则：
               返回false（长按时间不足）
       否则如果terrain_type是CLIFF_PATH：
           如果长按时间 >= 1.5秒：
               显示确认框
               等待用户确认
               如果用户确认：
                   进入步骤3
               否则：
                   返回false（用户取消）
           否则：
               返回false（长按时间不足）
       否则如果terrain_type是DOWNHILL_GENTLE或DOWNHILL_STEEP：
           进入步骤3（下坡点击即穿越）
   否则：
       返回false（未知卡牌类型）

3. 检查体能消耗
   如果player_stamina < stamina_cost：
       返回false（体能不足）
   否则：
       进入步骤4

4. 执行穿越
   player_stamina ← player_stamina - stamina_cost
   card.is_crossed ← true
   
   更新累积爬升：
   如果不是下坡地形：
       current_cumulative_elevation ← current_cumulative_elevation + cumulative_elevation
       发射信号cumulative_elevation_updated(current_cumulative_elevation)
   
   检查下坡膝盖损伤（v2.0新增）：
   如果terrain_type是DOWNHILL_STEEP：
       downhill_count ← downhill_count + 1
       如果downhill_count % 3 == 0：
           触发膝盖损伤（概率10%）
           如果膝盖损伤触发：
               发射信号knee_damage_triggered(damage_amount)
               疲劳 += 10
               体能消耗增加20%（持续5秒）
   
   应用特殊效果（special_effects）
   播放穿越效果（音效、动画、粒子）
   返回true（穿越成功）
```

### 2.2 属性系统架构（v2.0更新）

#### 2.2.1 系统职责定义

**核心职责**：

- **属性管理**：管理五维属性（体能、饥饿、口渴、疲劳、心率）的当前值
- **恢复计算**：根据五维属性的当前值，计算体能的恢复速率
- **消耗计算**：根据徒步距离和累积爬升计算体能消耗（v2.0新增）
- **边界检查**：检查属性是否达到警告或危险阈值，触发相应事件
- **恢复系统**：管理定时恢复机制，持续恢复体能

**职责边界**：

- **不负责**：属性消耗的原因判断（由CardSystem、TerrainSystem负责）
- **不负责**：恢复速率的显示（由UIManager负责）
- **不负责**：存档管理（由SaveManager负责）
- **不负责**：属性数值的平衡调整（由策划负责）

#### 2.2.2 系统架构设计

```
属性系统架构（v2.0更新）：

┌─────────────────────────────────────────────────────────────────┐
│  AttributeSystem（属性系统管理器）                              │
│  职责：协调属性管理、恢复计算、消耗计算、边界检测                  │
├─────────────────────────────────────────────────────────────────┤
│  五维属性模块                                                  │
│  ├─ Stamina（体能）                                           │
│  │   职责：管理玩家当前体能值、处理体能消耗、执行体能恢复           │
│  │   v2.0更新：支持基于距离和爬升的消耗计算                     │
│  │   特点：主属性，为0时游戏结束                               │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ Hunger（饥饿）                                             │
│  │   职责：管理玩家当前饥饿值、影响体能恢复速率                   │
│  │   特点：饥饿值越低，恢复速率越慢                              │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ Thirst（口渴）                                             │
│  │   职责：管理玩家当前口渴值、影响体能恢复速率                   │
│  │   特点：口渴值越低，恢复速率越慢（比饥饿影响更大）               │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ Fatigue（疲劳）                                           │
│  │   职责：管理玩家当前疲劳值、影响行动效率                       │
│  │   特点：缓冲属性，疲劳值越高，行动效率越低                      │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ HeartRate（心率）                                         │
│      职责：管理玩家当前心率值、影响疲劳积累                     │
│      特点：心率越高，疲劳积累越快                               │
├─────────────────────────────────────────────────────────────────┤
│  恢复系统模块                                                  │
│  ├─ RecoveryTimer（恢复计时器）                                 │
│  │   职责：定时触发恢复计算、执行属性恢复                         │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ RecoveryCalculator（恢复计算器）                           │
│      职责：根据五维属性当前值，计算体能恢复速率                     │
├─────────────────────────────────────────────────────────────────┤
│  消耗计算模块（v2.0新增）                                       │
│  └─ StaminaCostCalculator（体能消耗计算器）                     │
│      职责：根据徒步距离和累积爬升计算体能消耗                       │
```

#### 2.2.3 数据结构设计

**属性数据结构**：

```gdscript
## 属性数据结构
class AttributeData:
    var attribute_name: String  # 属性名称
    var current_value: float   # 当前值
    var min_value: float       # 最小值
    var max_value: float       # 最大值
    var warning_value: float   # 警告阈值
    var critical_value: float  # 危险阈值
    
    func _init(name: String, min_v: float, max_v: float):
        self.attribute_name = name
        self.current_value = max_v
        self.min_value = min_v
        self.max_value = max_v
        self.warning_value = min_v + (max_v - min_v) * 0.3
        self.critical_value = min_v + (max_v - min_v) * 0.1
```

**属性定义**：

```gdscript
## 五维属性定义

## 体能（Stamina）
## 取值范围：0-100
## 起始值：100
## 特点：主属性，为0时游戏结束
## 影响因素：地形卡消耗、天气影响、恢复速率
## v2.0更新：消耗公式 = (徒步距离 / 20) + (累积爬升 / 20)
@export var stamina: float = 100.0

## 饥饿（Hunger）
## 取值范围：0-100
## 起始值：100
## 特点：影响体能恢复速率
## 影响因素：地形卡消耗、资源卡恢复
@export var hunger: float = 100.0

## 口渴（Thirst）
## 取值范围：0-100
## 起始值：100
## 特点：影响体能恢复速率（比饥饿影响更大）
## 影响因素：地形卡消耗、资源卡恢复
@export var thirst: float = 100.0

## 疲劳（Fatigue）
## 取值范围：0-20
## 起始值：0
## 特点：缓冲属性，影响行动效率
## 影响因素：心率、负重、操作次数
## v2.0更新：疲劳积累 = (徒步距离 / 5) + (累积爬升 / 250)
@export var fatigue: float = 0.0

## 心率（HeartRate）
## 取值范围：80-180
## 起始值：110
## 特点：影响疲劳积累
## 影响因素：地形卡消耗、天气影响
@export var heart_rate: float = 110.0
```

#### 2.2.4 接口定义

**属性系统公开接口**：

```gdscript
## 属性系统公开接口定义

# 体能消耗接口
## 参数：
##   - amount: 消耗数量
## 返回值：是否消耗成功
func consume_stamina(amount: float) -> bool

# 体能恢复接口
## 参数：
##   - amount: 恢复数量
func recover_stamina(amount: float) -> void

# 基于距离和爬升的体能消耗计算（v2.0新增）
## 参数：
##   - hiking_distance: 徒步距离（公里）
##   - cumulative_elevation: 累积爬升（米）
## 返回值：体能消耗（点）
func calculate_stamina_cost(hiking_distance: float, cumulative_elevation: float) -> float

# 疲劳积累计算（v2.0新增）
## 参数：
##   - hiking_distance: 徒步距离（公里）
##   - cumulative_elevation: 累积爬升（米）
## 返回值：疲劳积累（次）
func calculate_fatigue_accumulation(hiking_distance: float, cumulative_elevation: float) -> float

# 属性修改接口
## 参数：
##   - attribute: 属性名称（"stamina"/"hunger"/"thirst"/"fatigue"/"heart_rate"）
##   - amount: 修改数量（正数为增加，负数为减少）
func modify_attribute(attribute: String, amount: float) -> void

# 属性获取接口
## 参数：
##   - attribute: 属性名称
## 返回值：当前值
func get_attribute(attribute: String) -> float

# 临时恢复速率设置接口
## 参数：
##   - rate: 临时恢复速率（0.0-1.0）
func set_temporary_recovery_rate(rate: float) -> void
```

**信号定义**：

```gdscript
## 属性系统信号定义

# 属性变化信号
## 参数：
##   - attribute: 属性名称
##   - value: 当前值
signal attribute_changed(attribute: String, value: float)

# 属性警告信号
## 参数：
##   - attribute: 属性名称
##   - level: 警告级别（"warning"/"critical"）
##   - message: 警告信息
signal attribute_warning(attribute: String, level: String, message: String)

# 体能耗尽信号
signal stamina_depleted()
```

#### 2.2.5 核心算法描述

**体能消耗计算算法（v2.0新增）**：

**算法目标**：根据徒步距离和累积爬升计算体能消耗

**输入参数**：
- `hiking_distance`：徒步距离（公里）
- `cumulative_elevation`：累积爬升（米）

**输出结果**：体能消耗（点）

**算法步骤**：

1. **验证输入参数**：
   - 检查徒步距离是否为非负数
   - 检查累积爬升是否为非负数
   - 如果参数无效，返回0

2. **应用体能消耗公式**：
   - 体能消耗 = (徒步距离 / 20) + (累积爬升 / 20)
   - 徒步距离单位：公里
   - 累积爬升单位：米
   - 体能消耗结果：点

3. **应用装备加成**（可选）：
   - 如果玩家装备了登山靴：体能消耗 × 0.8
   - 如果玩家装备了登山杖：体能消耗 × 0.9
   - 加成可叠加：体能消耗 × 0.8 × 0.9

4. **应用照片卡加成**（可选）：
   - 如果玩家激活了相关照片卡：体能消耗 × 0.95

5. **返回最终体能消耗**

**伪代码**：

```
算法：calculate_stamina_cost(hiking_distance, cumulative_elevation)
输入：hiking_distance（徒步距离，公里），cumulative_elevation（累积爬升，米）
输出：stamina_cost（体能消耗，点）

1. 验证输入参数
   如果hiking_distance < 0 或 cumulative_elevation < 0：
       返回0（参数无效）

2. 应用体能消耗公式
   stamina_cost ← (hiking_distance / 20.0) + (cumulative_elevation / 20.0)

3. 应用装备加成（可选）
   如果玩家装备了登山靴：
       stamina_cost ← stamina_cost × 0.8
   
   如果玩家装备了登山杖：
       stamina_cost ← stamina_cost × 0.9

4. 应用照片卡加成（可选）
   如果玩家激活了相关照片卡：
       stamina_cost ← stamina_cost × 0.95

5. 返回stamina_cost
```

**疲劳积累计算算法（v2.0新增）**：

**算法目标**：根据徒步距离和累积爬升计算疲劳积累

**输入参数**：
- `hiking_distance`：徒步距离（公里）
- `cumulative_elevation`：累积爬升（米）

**输出结果**：疲劳积累（次，需要休息的次数）

**算法步骤**：

1. **验证输入参数**：
   - 检查徒步距离是否为非负数
   - 检查累积爬升是否为非负数
   - 如果参数无效，返回0

2. **应用疲劳积累公式**：
   - 疲劳积累 = (徒步距离 / 5) + (累积爬升 / 250)
   - 徒步距离单位：公里
   - 累积爬升单位：米
   - 疲劳积累结果：次

3. **应用装备加成**（可选）：
   - 如果玩家装备了登山靴：疲劳积累 × 0.8
   - 如果玩家装备了专业背包：疲劳积累 × 0.7
   - 加成可叠加：疲劳积累 × 0.8 × 0.7

4. **应用照片卡加成**（可选）：
   - 如果玩家激活了相关照片卡：疲劳积累 × 0.75

5. **返回最终疲劳积累**

**伪代码**：

```
算法：calculate_fatigue_accumulation(hiking_distance, cumulative_elevation)
输入：hiking_distance（徒步距离，公里），cumulative_elevation（累积爬升，米）
输出：fatigue_accumulation（疲劳积累，次）

1. 验证输入参数
   如果hiking_distance < 0 或 cumulative_elevation < 0：
       返回0（参数无效）

2. 应用疲劳积累公式
   fatigue_accumulation ← (hiking_distance / 5.0) + (cumulative_elevation / 250.0)

3. 应用装备加成（可选）
   如果玩家装备了登山靴：
       fatigue_accumulation ← fatigue_accumulation × 0.8
   
   如果玩家装备了专业背包：
       fatigue_accumulation ← fatigue_accumulation × 0.7

4. 应用照片卡加成（可选）
   如果玩家激活了相关照片卡：
       fatigue_accumulation ← fatigue_accumulation × 0.75

5. 返回fatigue_accumulation
```

**恢复速率计算算法**：

**算法目标**：根据五维属性的当前值，计算体能的恢复速率

**输入参数**：
- `stamina`：当前体能值（0-100）
- `hunger`：当前饥饿值（0-100）
- `thirst`：当前口渴值（0-100）
- `fatigue`：当前疲劳值（0-20）
- `heart_rate`：当前心率值（80-180）
- `temporary_recovery_rate`：临时恢复速率（0.0-1.0）

**输出结果**：恢复速率（点/秒）

**算法步骤**：

1. **计算基础恢复速率**：
   - 基础恢复速率为5.0点/秒

2. **计算各属性影响系数**：
   - **饥饿影响系数**：
     - 81-100：1.0（正常恢复）
     - 50-80：0.5（恢复减半）
     - 0-49：0.1（恢复极慢）
   
   - **口渴影响系数**：
     - 81-100：1.0（正常恢复）
     - 50-80：0.5（恢复减半）
     - 0-49：0.05（恢复几乎停滞）
   
   - **疲劳影响系数**：
     - 0-9：1.0（无影响）
     - 10-14：0.8（轻微影响）
     - 15-20：0.5（严重影响）
   
   - **心率影响系数**：
     - 80-100：1.0（无影响）
     - 100-130：0.8（轻微影响）
     - 130-160：0.6（中等影响）
     - 160-180：0.4（严重影响）

3. **计算综合恢复系数**：
   - 综合恢复系数 = 饥饿影响系数 × 口渴影响系数 × 疲劳影响系数 × 心率影响系数 × (1.0 + 临时恢复速率)

4. **计算最终恢复速率**：
   - 最终恢复速率 = 基础恢复速率 × 综合恢复系数

**伪代码**：

```
算法：calculate_recovery_rate(stamina, hunger, thirst, fatigue, heart_rate, temporary_recovery_rate)
输入：stamina（体能），hunger（饥饿），thirst（口渴），fatigue（疲劳），heart_rate（心率），temporary_recovery_rate（临时恢复速率）
输出：recovery_rate（恢复速率）

1. 计算基础恢复速率
   base_recovery_rate ← 5.0

2. 计算饥饿影响系数
   如果hunger > 80：
       hunger_factor ← 1.0
   否则如果hunger >= 50：
       hunger_factor ← 0.5
   否则：
       hunger_factor ← 0.1

3. 计算口渴影响系数
   如果thirst > 80：
       thirst_factor ← 1.0
   否则如果thirst >= 50：
       thirst_factor ← 0.5
   否则：
       thirst_factor ← 0.05

4. 计算疲劳影响系数
   如果fatigue < 10：
       fatigue_factor ← 1.0
   否则如果fatigue < 15：
       fatigue_factor ← 0.8
   否则：
       fatigue_factor ← 0.5

5. 计算心率影响系数
   如果heart_rate < 100：
       heart_rate_factor ← 1.0
   否则如果heart_rate < 130：
       heart_rate_factor ← 0.8
   否则如果heart_rate < 160：
       heart_rate_factor ← 0.6
   否则：
       heart_rate_factor ← 0.4

6. 计算综合恢复系数
   combined_factor ← hunger_factor × thirst_factor × fatigue_factor × heart_rate_factor × (1.0 + temporary_recovery_rate)

7. 计算最终恢复速率
   recovery_rate ← base_recovery_rate × combined_factor

8. 返回recovery_rate
```

### 2.3 经济系统架构（v2.0更新）

#### 2.3.1 系统职责定义

**核心职责**：

- **货币管理**：管理三种货币（徒步数、累积爬升、环保值）的当前值
  - v2.0更新：将"海拔数"改为"累积爬升"
- **资源获取**：处理各种原因导致的货币获取（消除卡牌、连击奖励、通关奖励）
- **资源消耗**：处理各种原因导致的货币消耗（商店购买、道具使用）
- **商店交易**：管理商店系统，处理购买逻辑
- **货币同步**：同步货币到Steam云存档

**职责边界**：

- **不负责**：货币获取的原因判断（由CardSystem、ComboSystem负责）
- **不负责**：货币用途的业务逻辑（由ShopSystem负责）
- **不负责**：存档管理（由SaveManager负责）
- **不负责**：货币数值的平衡调整（由策划负责）

#### 2.3.2 系统架构设计

```
经济系统架构（v2.0更新）：

┌─────────────────────────────────────────────────────────────────┐
│  EconomySystem（经济系统管理器）                                │
│  职责：协调货币管理、商店交易、资源同步                           │
├─────────────────────────────────────────────────────────────────┤
│  货币管理模块                                                  │
│  ├─ HikingNumber（徒步数）                                     │
│  │   职责：管理玩家当前徒步数（局外经验值）                      │
│  │   特点：用于解锁内容、升级属性                               │
│  │   计算公式：徒步数 = 徒步距离（公里）× 2,000                  │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ CumulativeElevation（累积爬升，v2.0更新）                  │
│  │   职责：管理玩家当前累积爬升（局外稀有货币）                   │
│  │   特点：用于购买高级装备、解锁槽位                           │
│  │   计算公式：累积爬升 = Σ(所有上坡路段的垂直上升高度)           │
│  │   定义：上坡路段计入，下坡路段不计入，平路不计入               │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ EcoValue（环保值）                                         │
│      职责：管理玩家当前环保值（局内货币）                         │
│      特点：用于局内商店购买、照片卡包                            │
├─────────────────────────────────────────────────────────────────┤
│  商店系统模块                                                  │
│  ├─ ShopManager（商店管理器）                                   │
│  │   职责：管理商店系统、处理购买逻辑、商店UI                     │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ InventoryManager（库存管理器）                              │
│      职责：管理玩家库存、处理道具使用                             │
└─────────────────────────────────────────────────────────────────┘
```

#### 2.3.3 数据结构设计

**货币类型枚举（v2.0更新）**：

```gdscript
## 货币类型枚举
enum CurrencyType {
    HIKING_NUMBER,           # 徒步数（局外经验值）
    CUMULATIVE_ELEVATION,    # 累积爬升（局外稀有货币，v2.0新增）
    ECO_VALUE               # 环保值（局内货币）
}
```

**货币数据结构（v2.0更新）**：

```gdscript
## 货币数据结构
class CurrencyData:
    var type: CurrencyType   # 货币类型
    var current_amount: int  # 当前数量
    var name: String        # 货币名称
    var description: String # 货币描述
    
    func _init(t: CurrencyType, amount: int):
        self.type = t
        self.current_amount = amount
        self.name = _get_currency_name(t)
        self.description = _get_currency_description(t)
    
    func _get_currency_name(t: CurrencyType) -> String:
        match t:
            CurrencyType.HIKING_NUMBER:
                return "徒步数"
            CurrencyType.CUMULATIVE_ELEVATION:
                return "累积爬升"
            CurrencyType.ECO_VALUE:
                return "环保值"
            _:
                return "未知货币"
    
    func _get_currency_description(t: CurrencyType) -> String:
        match t:
            CurrencyType.HIKING_NUMBER:
                return "通过卡牌穿越获得的基础货币，用于局外角色属性升级"
            CurrencyType.CUMULATIVE_ELEVATION:
                return "通过挑战路线获得的特殊货币，用于局外兑换高级装备、解锁装备槽位"
            CurrencyType.ECO_VALUE:
                return "通过连击和通关获得的升级货币，用于局内商店购买物品+照片卡包"
            _:
                return "未知货币描述"
```

**商品数据结构**：

```gdscript
## 商品数据结构
class ItemData:
    var id: String                    # 商品唯一标识
    var name: String                  # 商品名称
    var description: String           # 商品描述
    var currency_type: CurrencyType    # 货币类型
    var price: int                    # 商品价格
    var category: String              # 商品分类（"food"/"water"/"equipment"/"photo_card"）
    var effect: Dictionary            # 商品效果
    var icon: Texture2D               # 商品图标
    
    func _init():
        self.effect = {}
```

#### 2.3.4 接口定义

**经济系统公开接口**：

```gdscript
## 经济系统公开接口定义

# 货币获取接口
## 参数：
##   - currency_type: 货币类型
##   - amount: 获取数量
func add_currency(currency_type: CurrencyType, amount: int) -> void

# 货币消耗接口
## 参数：
##   - currency_type: 货币类型
##   - amount: 消耗数量
## 返回值：是否消耗成功
func consume_currency(currency_type: CurrencyType, amount: int) -> bool

# 货币数量获取接口
## 参数：
##   - currency_type: 货币类型
## 返回值：当前数量
func get_currency(currency_type: CurrencyType) -> int

# 购买能力检查接口
## 参数：
##   - currency_type: 货币类型
##   - amount: 所需数量
## 返回值：是否足够
func can_afford(currency_type: CurrencyType, amount: int) -> bool

# 徒步数计算接口（v2.0新增）
## 参数：
##   - hiking_distance: 徒步距离（公里）
## 返回值：徒步数
func calculate_hiking_number(hiking_distance: float) -> int:
    return int(hiking_distance * 2000)

# 商品购买接口
## 参数：
##   - item_id: 商品标识
## 返回值：是否购买成功
func purchase_item(item_id: String) -> bool
```

**信号定义**：

```gdscript
## 经济系统信号定义

# 货币变化信号
## 参数：
##   - currency_type: 货币类型
##   - amount: 当前数量
signal currency_changed(currency_type: CurrencyType, amount: int)

# 购买结果信号
## 参数：
##   - success: 是否成功
##   - message: 结果消息
signal purchase_result(success: bool, message: String)

# 库存变化信号
## 参数：
##   - item_id: 商品标识
##   - count: 当前数量
signal inventory_changed(item_id: String, count: int)
```

---

## 第三章：地形与环境系统架构（v2.0新增）

### 3.1 地形系统架构

#### 3.1.1 系统职责定义

**核心职责**：

- **地形障碍管理**：管理8种地形障碍的类型、消耗、特殊效果
- **地形效果处理**：处理地形穿越后的特殊效果（心率上升、恐惧状态等）
- **上坡下坡机制**：区分上坡（计入累积爬升）和下坡（不计入累积爬升）
- **膝盖损伤检测**：检测下坡时的膝盖损伤（陡坡下坡）
- **地形确认框**：管理陡坡和悬崖栈道的翻越确认框

**职责边界**：

- **不负责**：地形卡的具体生成（由CardSystem负责）
- **不负责**：体能消耗的计算（由AttributeSystem负责）
- **不负责**：累积爬升的计算（由CardSystem负责）
- **不负责**：UI渲染（由UIManager负责）

#### 3.1.2 系统架构设计

```
地形系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  TerrainSystem（地形系统管理器）                                │
│  职责：协调地形管理、上坡下坡机制、地形效果处理                   │
├─────────────────────────────────────────────────────────────────┤
│  地形数据模块                                                  │
│  ├─ TerrainConfig（地形配置）                                   │
│  │   职责：管理8种地形类型的配置数据                             │
│  │   数据：体能消耗、累积爬升、特殊效果、徒步数奖励              │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ TerrainEffect（地形效果）                                   │
│  │   职责：管理地形穿越后的特殊效果                             │
│  │   效果：心率上升、恐惧状态、膝盖损伤等                       │
│  └────────────────────────────────────────────────────────────────┤
│  └─ TerrainDifficulty（地形难度）                               │
│      职责：管理地形难度分级（一级/二级/三级）                    │
│      分级：平坦道路（一级）、上坡路乱石路溪流（二级）、陡坡悬崖栈道（三级）
├─────────────────────────────────────────────────────────────────┤
│  上坡下坡模块（v2.0新增）                                       │
│  ├─ UphillManager（上坡管理器）                                 │
│  │   职责：管理上坡地形、累积爬升计算                            │
│  │   特点：上坡路段计入累积爬升                                  │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ DownhillManager（下坡管理器）                               │
│  │   职责：管理下坡地形、膝盖损伤检测                            │
│  │   特点：下坡路段不计入累积爬升，有膝盖磨损风险                  │
│  └────────────────────────────────────────────────────────────────┤
│  └─ KneeDamageCalculator（膝盖损伤计算器）                      │
│      职责：计算下坡时的膝盖损伤概率和程度                        │
│      规则：每穿越3张陡坡下坡卡，检查一次膝盖磨损，概率10%         │
└─────────────────────────────────────────────────────────────────┘
```

#### 3.1.3 地形数据结构

**地形配置数据结构（v2.0更新：增加下坡地形）**：

```gdscript
## 地形配置数据结构
class TerrainConfig:
    var terrain_type: TerrainType           # 地形类型
    var stamina_cost_min: float             # 最小体能消耗
    var stamina_cost_max: float             # 最大体能消耗
    var cumulative_elevation: float         # 累积爬升（米，仅上坡）
    var is_downhill: bool                   # 是否为下坡地形
    var special_effects: Array              # 特殊效果
    var hiking_number_reward: int           # 徒步数奖励
    var difficulty_level: int               # 难度分级（1/2/3）
    var slope: float                        # 坡度（百分比）
    
    func _init(t_type: TerrainType):
        self.terrain_type = t_type
        self.special_effects = []
        self._init_by_type(t_type)
    
    func _init_by_type(t_type: TerrainType):
        match t_type:
            TerrainType.FLAT_ROAD:
                self.stamina_cost_min = 5.0
                self.stamina_cost_max = 5.0
                self.cumulative_elevation = 0.0
                self.is_downhill = false
                self.special_effects = []
                self.hiking_number_reward = 100
                self.difficulty_level = 1
                self.slope = 0.0
            
            TerrainType.UPHILL_GENTLE:
                self.stamina_cost_min = 8.0
                self.stamina_cost_max = 10.0
                self.cumulative_elevation = 50.0
                self.is_downhill = false
                self.special_effects = [{"type": "heart_rate", "value": 5}]
                self.hiking_number_reward = 200
                self.difficulty_level = 2
                self.slope = 10.0
            
            TerrainType.UPHILL_STEEP:
                self.stamina_cost_min = 15.0
                self.stamina_cost_max = 25.0
                self.cumulative_elevation = 150.0
                self.is_downhill = false
                self.special_effects = [
                    {"type": "fatigue", "value": 5},
                    {"type": "heart_rate", "value": 10}
                ]
                self.hiking_number_reward = 450
                self.difficulty_level = 3
                self.slope = 22.5
            
            TerrainType.ROCKY_PATH:
                self.stamina_cost_min = 12.0
                self.stamina_cost_max = 18.0
                self.cumulative_elevation = 80.0
                self.is_downhill = false
                self.special_effects = [{"type": "hunger", "value": 5}]
                self.hiking_number_reward = 320
                self.difficulty_level = 2
                self.slope = 7.5
            
            TerrainType.STREAM:
                self.stamina_cost_min = 8.0
                self.stamina_cost_max = 10.0
                self.cumulative_elevation = 20.0
                self.is_downhill = false
                self.special_effects = [{"type": "thirst", "value": 5}]
                self.hiking_number_reward = 180
                self.difficulty_level = 2
                self.slope = 2.5
            
            TerrainType.CLIFF_PATH:
                self.stamina_cost_min = 20.0
                self.stamina_cost_max = 30.0
                self.cumulative_elevation = 300.0
                self.is_downhill = false
                self.special_effects = [
                    {"type": "fear", "duration": 3.0},
                    {"type": "heart_rate", "value": 15}
                ]
                self.hiking_number_reward = 700
                self.difficulty_level = 3
                self.slope = 35.0
            
            TerrainType.DOWNHILL_GENTLE:
                self.stamina_cost_min = 3.0
                self.stamina_cost_max = 5.0
                self.cumulative_elevation = 0.0
                self.is_downhill = true
                self.special_effects = []
                self.hiking_number_reward = 50
                self.difficulty_level = 1
                self.slope = -10.0
            
            TerrainType.DOWNHILL_STEEP:
                self.stamina_cost_min = 2.0
                self.stamina_cost_max = 4.0
                self.cumulative_elevation = 0.0
                self.is_downhill = true
                self.special_effects = [{"type": "knee_damage", "probability": 0.1}]
                self.hiking_number_reward = 100
                self.difficulty_level = 1
                self.slope = -22.5
```

#### 3.1.4 接口定义

**地形系统公开接口**：

```gdscript
## 地形系统公开接口定义

# 获取地形配置接口
## 参数：
##   - terrain_type: 地形类型
## 返回值：地形配置数据
func get_terrain_config(terrain_type: TerrainType) -> TerrainConfig

# 获取地形难度等级接口
## 参数：
##   - terrain_type: 地形类型
## 返回值：难度等级（1/2/3）
func get_terrain_difficulty(terrain_type: TerrainType) -> int

# 获取地形累积爬升接口
## 参数：
##   - terrain_type: 地形类型
## 返回值：累积爬升（米）
func get_terrain_cumulative_elevation(terrain_type: TerrainType) -> float

# 判断是否为下坡地形接口（v2.0新增）
## 参数：
##   - terrain_type: 地形类型
## 返回值：是否为下坡
func is_downhill(terrain_type: TerrainType) -> bool

# 膝盖损伤检测接口（v2.0新增）
## 参数：
##   - downhill_count: 下坡穿越次数
## 返回值：是否触发膝盖损伤
func check_knee_damage(downhill_count: int) -> bool

# 应用地形效果接口
## 参数：
##   - terrain_type: 地形类型
##   - player_data: 玩家数据
func apply_terrain_effects(terrain_type: TerrainType, player_data: Dictionary) -> void
```

**信号定义**：

```gdscript
## 地形系统信号定义

# 地形穿越信号
## 参数：
##   - terrain_type: 地形类型
signal terrain_crossed(terrain_type: TerrainType)

# 膝盖损伤信号（v2.0新增）
## 参数：
##   - damage_amount: 损伤程度
signal knee_damage_triggered(damage_amount: float)

# 恐惧状态信号
## 参数：
##   - duration: 持续时间（秒）
signal fear_state_triggered(duration: float)
```

### 3.2 上坡下坡机制架构（v2.0新增）

#### 3.2.1 机制设计

**上坡机制**：

- **定义**：上坡路段计入累积爬升，体能消耗增加
- **地形类型**：缓坡上坡、陡坡上坡、乱石路、溪流、悬崖栈道
- **累积爬升计算**：Σ(所有上坡路段的垂直上升高度)
- **视觉效果**：向上箭头🔼（红色表示陡坡，橙色表示缓坡）
- **特殊效果**：心率上升、疲劳增加

**下坡机制**：

- **定义**：下坡路段不计入累积爬升，体能消耗减少，有膝盖磨损风险
- **地形类型**：缓坡下坡、陡坡下坡
- **累积爬升计算**：不计入累积爬升
- **视觉效果**：向下箭头🔽（红色表示陡坡下坡，橙色表示缓坡下坡）
- **特殊效果**：膝盖损伤（陡坡下坡，每3张检测一次，概率10%）

#### 3.2.2 膝盖损伤检测算法

**算法目标**：检测下坡时的膝盖损伤

**输入参数**：
- `downhill_count`：下坡穿越次数
- `terrain_type`：地形类型（陡坡下坡）

**输出结果**：是否触发膝盖损伤

**算法步骤**：

1. **检查地形类型**：
   - 如果不是陡坡下坡，返回false

2. **检查穿越次数**：
   - 每穿越3张陡坡下坡卡，检查一次膝盖损伤
   - 如果downhill_count % 3 != 0，返回false

3. **应用装备加成**：
   - 如果玩家装备了登山杖：膝盖损伤概率 × 0.5
   - 如果玩家装备了专业登山鞋：膝盖损伤概率 × 0.8

4. **计算膝盖损伤概率**：
   - 基础概率：10%
   - 应用装备加成后：概率 = 基础概率 × 装备系数

5. **触发膝盖损伤**：
   - 生成随机数（0-1）
   - 如果随机数 < 概率，触发膝盖损伤

6. **返回结果**

**伪代码**：

```
算法：check_knee_damage(downhill_count, terrain_type, player_equipment)
输入：downhill_count（下坡穿越次数），terrain_type（地形类型），player_equipment（玩家装备）
输出：is_triggered（是否触发膝盖损伤）

1. 检查地形类型
   如果terrain_type不是DOWNHILL_STEEP：
       返回false（非陡坡下坡，不检测）

2. 检查穿越次数
   如果downhill_count % 3 != 0：
       返回false（未达到检测条件）

3. 应用装备加成
   knee_damage_probability ← 0.1  # 基础概率10%
   
   如果玩家装备了登山杖：
       knee_damage_probability ← knee_damage_probability × 0.5
   
   如果玩家装备了专业登山鞋：
       knee_damage_probability ← knee_damage_probability × 0.8

4. 触发膝盖损伤
   random_value ← random()  # 生成0-1的随机数
   
   如果random_value < knee_damage_probability：
       返回true（触发膝盖损伤）
   否则：
       返回false（未触发膝盖损伤）
```

### 3.3 天气系统架构

#### 3.3.1 系统职责定义

**核心职责**：

- **天气管理**：管理6种天气类型（晴天、多云、高温、回南天、台风、浓雾）
- **天气效果处理**：处理天气对地形消耗、体能恢复的影响
- **天气动态变化**：支持关卡中途天气突变
- **天气视觉效果**：管理天气的视觉表现（粒子效果、颜色渐变）

**职责边界**：

- **不负责**：天气的具体生成（由CardSystem负责）
- **不负责**：天气影响的UI显示（由UIManager负责）
- **不负责**：天气的音效播放（由AudioManager负责）

#### 3.3.2 天气数据结构

**天气类型枚举**：

```gdscript
## 天气类型枚举
enum WeatherType {
    SUNNY,        # 晴天
    CLOUDY,       # 多云
    HOT,          # 高温
    DAMP,         # 回南天
    TYPHOON,      # 台风
    FOG           # 浓雾
}
```

**天气配置数据结构**：

```gdscript
## 天气配置数据结构
class WeatherConfig:
    var weather_type: WeatherType     # 天气类型
    var occurrence_probability: float  # 出现概率（0.0-1.0）
    var stamina_cost_modifier: float  # 体能消耗修正（1.0=无影响）
    var recovery_rate_modifier: float # 恢复速率修正（1.0=无影响）
    var terrain_cost_modifier: float  # 地形消耗修正（1.0=无影响）
    var heart_rate_modifier: float    # 心率修正（1.0=无影响）
    var visual_effects: Array        # 视觉效果
    var audio_effects: Array          # 音效
    
    func _init(w_type: WeatherType):
        self.weather_type = w_type
        self._init_by_type(w_type)
    
    func _init_by_type(w_type: WeatherType):
        match w_type:
            WeatherType.SUNNY:
                self.occurrence_probability = 0.4
                self.stamina_cost_modifier = 1.0
                self.recovery_rate_modifier = 1.0
                self.terrain_cost_modifier = 1.0
                self.heart_rate_modifier = 1.0
                self.visual_effects = []
                self.audio_effects = []
            
            WeatherType.CLOUDY:
                self.occurrence_probability = 0.25
                self.stamina_cost_modifier = 1.0
                self.recovery_rate_modifier = 1.0
                self.terrain_cost_modifier = 1.0
                self.heart_rate_modifier = 1.0
                self.visual_effects = [{"type": "dim", "value": 0.1}]
                self.audio_effects = []
            
            WeatherType.HOT:
                self.occurrence_probability = 0.15
                self.stamina_cost_modifier = 1.1
                self.recovery_rate_modifier = 1.0
                self.terrain_cost_modifier = 1.1
                self.heart_rate_modifier = 1.2
                self.visual_effects = [{"type": "heat_waves"}]
                self.audio_effects = ["heat_bg"]
            
            WeatherType.DAMP:
                self.occurrence_probability = 0.1
                self.stamina_cost_modifier = 1.0
                self.recovery_rate_modifier = 1.0
                self.terrain_cost_modifier = 1.0
                self.heart_rate_modifier = 1.0
                self.visual_effects = [{"type": "haze"}]
                self.audio_effects = []
            
            WeatherType.TYPHOON:
                self.occurrence_probability = 0.05
                self.stamina_cost_modifier = 1.3
                self.recovery_rate_modifier = 0.8
                self.terrain_cost_modifier = 1.3
                self.heart_rate_modifier = 1.5
                self.visual_effects = [{"type": "rain"}, {"type": "screen_shake"}]
                self.audio_effects = ["rain_bg", "thunder"]
            
            WeatherType.FOG:
                self.occurrence_probability = 0.05
                self.stamina_cost_modifier = 1.0
                self.recovery_rate_modifier = 0.9
                self.terrain_cost_modifier = 1.0
                self.heart_rate_modifier = 1.0
                self.visual_effects = [{"type": "fog"}]
                self.audio_effects = []
```

#### 3.3.3 接口定义

**天气系统公开接口**：

```gdscript
## 天气系统公开接口定义

# 设置当前天气接口
## 参数：
##   - weather_type: 天气类型
func set_current_weather(weather_type: WeatherType) -> void

# 获取当前天气接口
## 返回值：当前天气类型
func get_current_weather() -> WeatherType

# 获取天气配置接口
## 参数：
##   - weather_type: 天气类型
## 返回值：天气配置数据
func get_weather_config(weather_type: WeatherType) -> WeatherConfig

# 随机天气生成接口
## 返回值：随机天气类型
func generate_random_weather() -> WeatherType

# 天气动态变化接口（关卡中途）
## 参数：
##   - level_progress: 关卡进度（0.0-1.0）
## 返回值：是否触发天气变化
func trigger_weather_change(level_progress: float) -> bool

# 应用天气效果接口
## 参数：
##   - weather_type: 天气类型
##   - player_data: 玩家数据
func apply_weather_effects(weather_type: WeatherType, player_data: Dictionary) -> void
```

**信号定义**：

```gdscript
## 天气系统信号定义

# 天气变化信号
## 参数：
##   - weather_type: 新天气类型
signal weather_changed(weather_type: WeatherType)

# 天气效果触发信号
## 参数：
##   - effect_type: 效果类型
signal weather_effect_triggered(effect_type: String)
```

---

## 第四章：补给与疲劳系统架构（v2.0新增）

### 4.1 补给系统架构

#### 4.1.1 系统职责定义

**核心职责**：

- **补给管理**：管理补给品（水、运动饮料、巧克力、能量棒等）的消耗与恢复
- **补给需求计算**：根据徒步距离计算补给需求（每10公里需2水+1运动饮料+1巧克力）
- **补给点管理**：管理补给点的出现、内容、价格
- **补给不足警告**：当补给不足时显示警告
- **补给效果处理**：处理补给品使用后的效果（恢复属性）

**职责边界**：

- **不负责**：补给品的具体生成（由CardSystem负责）
- **不负责**：补给品的UI显示（由UIManager负责）
- **不负责**：补给品的购买逻辑（由EconomySystem负责）

#### 4.1.2 系统架构设计

```
补给系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  SupplySystem（补给系统管理器）                                 │
│  职责：协调补给管理、补给需求计算、补给点管理                      │
├─────────────────────────────────────────────────────────────────┤
│  补给品模块                                                    │
│  ├─ SupplyItem（补给品）                                       │
│  │   职责：管理补给品数据、效果、价格                            │
│  │   分类：水类、饮料类、食物类、综合补给类                      │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ SupplyCalculator（补给需求计算器）                         │
│  │   职责：根据徒步距离计算补给需求                             │
│  │   公式：需水量=距离/5，需运动饮料量=距离/10，需巧克力=距离/10   │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ SupplyEffect（补给效果处理器）                             │
│      职责：处理补给品使用后的效果                               │
│      效果：恢复体能、饥饿、口渴、疲劳等                         │
├─────────────────────────────────────────────────────────────────┤
│  补给点模块                                                    │
│  ├─ SupplyPoint（补给点）                                      │
│  │   职责：管理补给点出现、内容、价格                           │
│  │   类型：小型/中型/大型/超级补给点                            │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ SupplyPointManager（补给点管理器）                          │
│  │   职责：管理补给点的生成、位置、解锁条件                      │
│  │   规则：新手关每2层，标准关每2-3层，挑战关每3层               │
│  └────────────────────────────────────────────────────────────────┤
│  └─ SupplyWarning（补给不足警告器）                             │
│      职责：检测补给不足，显示警告                               │
│      触发条件：徒步距离达到5公里但补给不足                       │
└─────────────────────────────────────────────────────────────────┘
```

#### 4.1.3 补给品数据结构

**补给品类型枚举**：

```gdscript
## 补给品类型枚举
enum SupplyType {
    WATER,              # 矿泉水
    SPORTS_DRINK,       # 运动饮料
    CHOCOLATE,          # 巧克力
    ENERGY_BAR,         # 能量棒
    BANANA,             # 香蕉
    ELECTROLYTE_WATER,  # 电解质水
    SUPPLY_PACK         # 运动补给包
}
```

**补给品数据结构**：

```gdscript
## 补给品数据结构
class SupplyItem:
    var id: String                # 补给品唯一标识
    var name: String              # 补给品名称
    var description: String       # 补给品描述
    var supply_type: SupplyType   # 补给品类型
    var eco_cost: int            # 环保值价格
    var effects: Dictionary      # 恢复效果
    var icon: Texture2D           # 图标
    
    func _init(s_type: SupplyType):
        self.supply_type = s_type
        self.effects = {}
        self._init_by_type(s_type)
    
    func _init_by_type(s_type: SupplyType):
        match s_type:
            SupplyType.WATER:
                self.id = "water"
                self.name = "矿泉水"
                self.description = "补充水分，恢复口渴"
                self.eco_cost = 25
                self.effects = {"thirst": 20}
            
            SupplyType.SPORTS_DRINK:
                self.id = "sports_drink"
                self.name = "运动饮料"
                self.description = "补充电解质，恢复口渴和疲劳"
                self.eco_cost = 50
                self.effects = {"thirst": 15, "fatigue": -5}
            
            SupplyType.CHOCOLATE:
                self.id = "chocolate"
                self.name = "巧克力"
                self.description = "补充能量，恢复体能和饥饿"
                self.eco_cost = 75
                self.effects = {"stamina": 15, "hunger": 20}
            
            SupplyType.ENERGY_BAR:
                self.id = "energy_bar"
                self.name = "能量棒"
                self.description = "高能量补给，恢复体能和饥饿"
                self.eco_cost = 100
                self.effects = {"stamina": 20, "hunger": 15}
            
            SupplyType.BANANA:
                self.id = "banana"
                self.name = "香蕉"
                self.description = "富含钾元素，恢复体能"
                self.eco_cost = 60
                self.effects = {"stamina": 10}
            
            SupplyType.ELECTROLYTE_WATER:
                self.id = "electrolyte_water"
                self.name = "电解质水"
                self.description = "专业补给，恢复口渴和降低心率"
                self.eco_cost = 80
                self.effects = {"thirst": 30, "heart_rate": -10}
            
            SupplyType.SUPPLY_PACK:
                self.id = "supply_pack"
                self.name = "运动补给包"
                self.description = "综合补给，恢复口渴、体能、疲劳"
                self.eco_cost = 150
                self.effects = {"thirst": 25, "stamina": 20, "fatigue": -10}
```

#### 4.1.4 补给需求计算

**补给需求公式**：

```
需水量 = 徒步距离 / 5
需运动饮料量 = 徒步距离 / 10
需巧克力补给次数 = 徒步距离 / 10

示例：
- 徒步10公里：需水=2瓶，需运动饮料=1瓶，需巧克力=1次
- 徒步14公里：需水=2.8瓶，需运动饮料=1.4瓶，需巧克力=1.4次
- 徒步26公里：需水=5.2瓶，需运动饮料=2.6瓶，需巧克力=2.6次
```

**补给需求计算接口**：

```gdscript
## 补给需求计算接口

# 计算补给需求接口（v2.0新增）
## 参数：
##   - hiking_distance: 徒步距离（公里）
## 返回值：补给需求字典
func calculate_supply_demand(hiking_distance: float) -> Dictionary:
    var demand = {
        "water": hiking_distance / 5.0,
        "sports_drink": hiking_distance / 10.0,
        "chocolate": hiking_distance / 10.0
    }
    return demand

# 检查补给是否充足接口（v2.0新增）
## 参数：
##   - hiking_distance: 已徒步距离（公里）
##   - inventory: 当前补给库存
## 返回值：是否充足
func is_supply_sufficient(hiking_distance: float, inventory: Dictionary) -> bool:
    var demand = calculate_supply_demand(hiking_distance)
    var is_sufficient = true
    
    if inventory.get("water", 0) < demand.water:
        is_sufficient = false
    
    if inventory.get("sports_drink", 0) < demand.sports_drink:
        is_sufficient = false
    
    if inventory.get("chocolate", 0) < demand.chocolate:
        is_sufficient = false
    
    return is_sufficient
```

### 4.2 疲劳系统架构

#### 4.2.1 系统职责定义

**核心职责**：

- **疲劳管理**：管理疲劳的积累、恢复、突破
- **休息机制**：管理休息次数、休息效果、休息时间
- **疲劳突破**：管理疲劳突破机制（装备突破、照片卡突破）
- **疲劳警告**：检测疲劳达到警告或危险阈值

**职责边界**：

- **不负责**：疲劳积累的具体原因判断（由AttributeSystem负责）
- **不负责**：休息UI的显示（由UIManager负责）
- **不负责**：疲劳数值的平衡调整（由策划负责）

#### 4.2.2 系统架构设计

```
疲劳系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  FatigueSystem（疲劳系统管理器）                                │
│  职责：协调疲劳管理、休息机制、疲劳突破                           │
├─────────────────────────────────────────────────────────────────┤
│  疲劳计算模块                                                  │
│  ├─ FatigueCalculator（疲劳计算器）                             │
│  │   职责：根据徒步距离和累积爬升计算疲劳积累                      │
│  │   公式：疲劳积累 = (徒步距离 / 5) + (累积爬升 / 250)         │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ FatigueBreakthrough（疲劳突破）                             │
│      职责：管理疲劳突破机制（装备突破、照片卡突破）               │
│      效果：疲劳积累速度-20% ~ -50%                              │
├─────────────────────────────────────────────────────────────────┤
│  休息机制模块                                                  │
│  ├─ RestManager（休息管理器）                                   │
│  │   职责：管理休息次数、休息效果、休息时间                       │
│  │   限制：新手期3次，标准期2次，挑战期1次                       │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ RestType（休息类型）                                       │
│  │   职责：管理三种休息类型（快速/标准/深度）                     │
│  │   效果：快速（疲劳-5）、标准（疲劳-10，体能+20）、深度（疲劳-15，体能+30，饥饿+20，口渴+20）
│  └────────────────────────────────────────────────────────────────┤
│  └─ RestTimer（休息计时器）                                    │
│      职责：管理休息倒计时                                      │
│      时间：快速30秒、标准60秒、深度90秒                         │
└─────────────────────────────────────────────────────────────────┘
```

#### 4.2.3 休息类型数据结构

**休息类型枚举**：

```gdscript
## 休息类型枚举
enum RestType {
    QUICK,     # 快速休息
    STANDARD,  # 标准休息
    DEEP       # 深度休息
}
```

**休息类型数据结构**：

```gdscript
## 休息类型数据结构
class RestTypeData:
    var rest_type: RestType    # 休息类型
    var duration: int          # 休息时间（秒）
    var fatigue_reduction: int # 疲劳减少
    var stamina_recovery: int  # 体能恢复
    var hunger_recovery: int   # 饥饿恢复
    var thirst_recovery: int   # 口渴恢复
    
    func _init(r_type: RestType):
        self.rest_type = r_type
        self._init_by_type(r_type)
    
    func _init_by_type(r_type: RestType):
        match r_type:
            RestType.QUICK:
                self.duration = 30
                self.fatigue_reduction = 5
                self.stamina_recovery = 0
                self.hunger_recovery = 0
                self.thirst_recovery = 0
            
            RestType.STANDARD:
                self.duration = 60
                self.fatigue_reduction = 10
                self.stamina_recovery = 20
                self.hunger_recovery = 0
                self.thirst_recovery = 0
            
            RestType.DEEP:
                self.duration = 90
                self.fatigue_reduction = 15
                self.stamina_recovery = 30
                self.hunger_recovery = 20
                self.thirst_recovery = 20
```

#### 4.2.4 接口定义

**疲劳系统公开接口**：

```gdscript
## 疲劳系统公开接口定义

# 休息接口
## 参数：
##   - rest_type: 休息类型
## 返回值：是否休息成功
func take_rest(rest_type: RestType) -> bool

# 获取剩余休息次数接口
## 返回值：剩余休息次数
func get_remaining_rests() -> int

# 获取疲劳积累接口
## 返回值：疲劳积累（次）
func get_fatigue_accumulation() -> float

# 检查是否需要休息接口
## 参数：
##   - hiking_distance: 徒步距离（公里）
##   - cumulative_elevation: 累积爬升（米）
## 返回值：是否需要休息
func needs_rest(hiking_distance: float, cumulative_elevation: float) -> bool

# 应用疲劳突破效果接口
## 参数：
##   - breakthrough_type: 突破类型
##   - value: 突破值
func apply_fatigue_breakthrough(breakthrough_type: String, value: float) -> void
```

**信号定义**：

```gdscript
## 疲劳系统信号定义

# 休息完成信号
## 参数：
##   - rest_type: 休息类型
##   - effects: 恢复效果
signal rest_completed(rest_type: RestType, effects: Dictionary)

# 疲劳警告信号
## 参数：
##   - level: 警告级别（"warning"/"critical"）
signal fatigue_warning(level: String)

# 疲劳突破信号
## 参数：
##   - breakthrough_type: 突破类型
##   - value: 突破值
signal fatigue_breakthrough_triggered(breakthrough_type: String, value: float)
```

---

## 第五章：UI/UX架构设计

### 5.1 UI场景架构

#### 5.1.1 UI场景职责划分

**场景分类**：

| 场景类型 | 场景名称 | 职责范围 | 所属层级 |
|---------|---------|---------|---------|
| **主场景** | MainMenu | 游戏主菜单、模式选择、设置 | 表现层 |
| **角色场景** | CharacterSelection | 角色选择、角色属性预览 | 表现层 |
| **升级场景** | UpgradeMenu | 属性升级、装备兑换 | 表现层 |
| **战斗场景** | BattleScene | 核心战斗、卡牌交互、属性显示、累积爬升显示 | 表现层 |
| **路线场景** | JourneyScene | 路线选择、商店交易 | 表现层 |
| **结算场景** | VictoryScene | 胜利结算、奖励展示 | 表现层 |
| **结算场景** | DefeatScene | 失败结算、进度显示 | 表现层 |
| **设置场景** | SettingsMenu | 游戏设置、图形设置、音频设置 | 表现层 |

#### 5.1.2 BattleScene节点树设计（v2.0更新：增加累积爬升显示）

```
BattleScene节点树（PC端，v2.0更新）：

BattleScene（Node2D）
├─ BackgroundLayer（背景层，PC端高分辨率）
│   └─ BackgroundTexture（背景纹理，支持4K）
├─ CardLayer（卡牌层）
│   ├─ Camera2D（摄像机，支持平滑移动）
│   ├─ LayerContainer[13]（分层容器，最多13层）
│   │   └─ HikingCard[N]（徒步卡牌，支持8种地形类型）
│   └─ CurrentLayerIndicator（当前层指示器）
├─ AttributePanel（属性面板，PC端布局）
│   ├─ StaminaBar（体能条）
│   ├─ HungerBar（饥饿条）
│   ├─ ThirstBar（口渴条）
│   ├─ FatigueBar（疲劳条）
│   └─ HeartRateLabel（心率标签）
├─ ProgressPanel（进度面板，v2.0新增）
│   ├─ HikingDistanceLabel（徒步距离）
│   ├─ HikingDistanceProgressBar（徒步距离进度条）
│   ├─ CumulativeElevationLabel（累积爬升）
│   ├─ CumulativeElevationProgressBar（累积爬升进度条）
│   └─ AltitudeLabel（当前海拔）
├─ ComboPanel（连击面板，PC端）
│   ├─ ComboCounter（连击计数器）
│   ├─ ComboTypeLabel（连击类型）
│   ├─ ClimbComboCounter（攀登连击计数器）
│   └─ ComboTooltip（连击提示）
├─ ResourcePanel（资源面板，PC端，v2.0更新）
│   ├─ EcoValueLabel（环保值标签）
│   ├─ HikingNumLabel（徒步数标签）
│   └─ CumulativeElevationNumLabel（累积爬升标签）
├─ WeatherPanel（天气面板，PC端）
│   ├─ WeatherIcon（天气图标）
│   ├─ WeatherLabel（天气标签）
│   └─ WeatherTooltip（天气效果提示）
├─ TerrainIndicator（地形指示器，v2.0新增）
│   ├─ TerrainTypeLabel（地形类型）
│   ├─ SlopeArrow（坡度箭头）
│   ├─ CumulativeElevationGain（累积爬升增益）
│   └─ KneeDamageWarning（膝盖损伤警告）
├─ SupplyWarningPanel（补给不足警告，v2.0新增）
│   ├─ WarningTitle（警告标题）
│   ├─ SupplyStatus（补给状态）
│   ├─ ConsequenceText（后果说明）
│   └─ SuggestionText（建议）
├─ KeyboardShortcutPanel（键盘快捷键面板，PC端）
│   └─ ShortcutList（快捷键列表）
└─ EffectLayer（特效层，GPU加速）
    ├─ ParticleSystem（粒子系统）
    ├─ VFXContainer（特效容器）
    └─ ScreenShake（屏幕震动）
```

### 5.2 交互系统设计

#### 5.2.1 输入处理架构

（保持原有设计，详见v1.0文档）

#### 5.2.2 键盘快捷键设计

（保持原有设计，详见v1.0文档）

#### 5.2.3 鼠标交互设计

（保持原有设计，详见v1.0文档）

#### 5.2.4 工具提示系统设计（v2.0更新：增加地形信息）

**工具提示显示规范（v2.0更新）**：

```
工具提示显示规范（v2.0更新）：

1. 提示内容
   ├─ 卡牌名称
   ├─ 卡牌类型
   ├─ 体能消耗
   ├─ 累积爬升（v2.0新增：仅上坡显示）
   ├─ 爬升/下降指示（v2.0新增：上坡🔼，下坡🔽，平路→）
   ├─ 环保值奖励
   ├─ 徒步数奖励
   ├─ 特殊效果
   └─ 描述文本

2. 提示位置
   ├─ 默认位置：鼠标右下方（+20px, +20px）
   ├─ 边界检测：确保提示不超出屏幕边界
   ├─ 位置调整：如果超出边界，调整到屏幕内
   └─ 层级设置：确保提示在最上层（z_index=1000）

3. 提示样式
   ├─ 字体大小：12-14px（适配高分辨率）
   ├─ 文字颜色：黑色（白色背景）
   ├─ 背景颜色：白色（半透明，alpha=0.9）
   ├─ 边框：1px黑色（alpha=0.5）
   └─ 阴影：2px黑色（alpha=0.2）

4. 提示显示时机
   ├─ 延迟显示：0.5秒（避免频繁闪烁）
   ├─ 显示条件：鼠标悬停超过0.5秒
   └─ 隐藏时机：鼠标离开时立即隐藏
```

---

## 第六章：数据持久化架构

### 6.1 存档系统设计

（保持原有设计，详见v1.0文档）

### 6.2 配置系统设计（v2.0更新：增加真实路线配置）

#### 6.2.1 系统职责定义

**核心职责**：

- **配置管理**：管理游戏配置的加载、保存、更新
- **配置验证**：验证配置数据的有效性
- **配置热更新**：支持配置的热更新（重启后生效）
- **真实路线配置管理**（v2.0新增）：管理麦理浩径、澳门路线等真实路线配置

**职责边界**：

- **不负责**：配置数据的具体内容（由策划负责）
- **不负责**：配置数据的业务逻辑（由各系统负责）
- **不负责**：配置数据的平衡调整（由策划负责）

#### 6.2.2 真实路线配置（v2.0新增）

**路线配置数据结构**：

```gdscript
## 路线配置数据结构
class RouteData:
    var route_id: String           # 路线唯一标识
    var route_name: String         # 路线名称
    var route_type: String         # 路线类型（"mac_lehose"/"macau"）
    var total_distance: float      # 总距离（公里）
    var total_elevation: float     # 总累积爬升（米）
    var difficulty: int            # 难度等级（1-6）
    var layer_configs: Array       # 每层配置
    var terrain_distribution: Dictionary  # 地形分布
    var weather_probability: Dictionary  # 天气概率
    
    func _init():
        self.layer_configs = []
        self.terrain_distribution = {}
        self.weather_probability = {}
```

**麦理浩径配置示例**：

```json
{
  "route_id": "mac_lehose_stage_1",
  "route_name": "麦理浩径第1段",
  "route_type": "mac_lehose",
  "total_distance": 10.6,
  "total_elevation": 450,
  "difficulty": 2,
  "layer_configs": [
    {"layer_index": 1, "card_count": 4, "distance": 2.1, "elevation": 89},
    {"layer_index": 2, "card_count": 4, "distance": 2.1, "elevation": 89},
    {"layer_index": 3, "card_count": 4, "distance": 2.1, "elevation": 89},
    {"layer_index": 4, "card_count": 4, "distance": 2.1, "elevation": 89},
    {"layer_index": 5, "card_count": 4, "distance": 2.2, "elevation": 94}
  ],
  "terrain_distribution": {
    "flat_road": 0.3,
    "uphill_gentle": 0.4,
    "uphill_steep": 0.2,
    "rocky_path": 0.1
  },
  "weather_probability": {
    "sunny": 0.4,
    "cloudy": 0.25,
    "hot": 0.15,
    "damp": 0.1,
    "typhoon": 0.05,
    "fog": 0.05
  }
}
```

**澳门路线配置示例（v2.0新增）**：

```json
{
  "route_id": "luhuang_northeast",
  "route_name": "路环东北步行径",
  "route_type": "macau",
  "total_distance": 4.3,
  "total_elevation": 60,
  "difficulty": 1,
  "layer_configs": [
    {"layer_index": 1, "card_count": 4, "distance": 1.5, "elevation": 0},
    {"layer_index": 2, "card_count": 3, "distance": 1.3, "elevation": 30},
    {"layer_index": 3, "card_count": 1, "distance": 1.5, "elevation": 30}
  ],
  "terrain_distribution": {
    "flat_road": 0.6,
    "uphill_gentle": 0.4
  },
  "weather_probability": {
    "sunny": 0.5,
    "cloudy": 0.3,
    "hot": 0.15,
    "damp": 0.05
  }
}
```

---

## 第七章：性能优化架构

（保持原有设计，详见v1.0文档）

---

## 第八章：Steam平台集成

（保持原有设计，详见v1.0文档）

---

## 第九章：工具链架构

### 9.1 godot_parser集成

（保持原有设计，详见v1.0文档）

### 9.2 自动化构建流程

（保持原有设计，详见v1.0文档）

---

## 第十章：开发规范

### 10.1 代码规范

（保持原有设计，详见v1.0文档）

### 10.2 工作流程规范

（保持原有设计，详见v1.0文档）

---

## 附录A：快速参考

### A.1 核心公式速查（v2.0更新）

**体能消耗公式（v2.0）**：
```
体能消耗 = (徒步距离 / 20) + (累积爬升 / 20)

其中：
- 徒步距离单位：公里
- 累积爬升单位：米
- 体能消耗结果：点
- 基准：初始体能100 = 20公里徒步 或 2000米累积爬升
```

**疲劳积累公式（v2.0）**：
```
疲劳积累 = (徒步距离 / 5) + (累积爬升 / 250)

其中：
- 徒步距离单位：公里
- 累积爬升单位：米
- 疲劳积累结果：次（需要休息的次数）
- 基准：每5公里徒步需要1次休息缓解疲劳
```

**补给需求公式（v2.0）**：
```
需水量 = 徒步距离 / 5
需运动饮料量 = 徒步距离 / 10
需巧克力补给次数 = 徒步距离 / 10

基准：每10公里徒步需要2瓶水+1瓶运动饮料+1次巧克力补给
```

**徒步数计算公式（v2.0）**：
```
徒步数 = 徒步距离（公里）× 2,000

示例：
- 徒步10公里 = 10 × 2,000 = 20,000徒步数
- 徒步14公里 = 14 × 2,000 = 28,000徒步数
- 徒步26公里 = 26 × 2,000 = 52,000徒步数
```

**累积爬升定义（v2.0）**：
```
累积爬升 = Σ(所有上坡路段的垂直上升高度)

规则：
- 上坡路段计入累积爬升
- 下坡路段不计入累积爬升
- 平路（坡度<5%）不计入累积爬升
```

### A.2 地形类型速查（v2.0更新）

| 地形类型 | 体能消耗 | 累积爬升 | 是否下坡 | 徒步数 | 难度 |
|---------|---------|---------|---------|--------|------|
| 平坦道路 | 5点 | 0m | 否 | 100 | 1 |
| 缓坡上坡 | 8-10点 | 50m | 否 | 200 | 2 |
| 陡坡上坡 | 15-25点 | 150m | 否 | 450 | 3 |
| 乱石路 | 12-18点 | 80m | 否 | 320 | 2 |
| 溪流 | 8-10点 | 20m | 否 | 180 | 2 |
| 悬崖栈道 | 20-30点 | 300m | 否 | 700 | 3 |
| 缓坡下坡 | 3-5点 | 0m | 是 | 50 | 1 |
| 陡坡下坡 | 2-4点 | 0m | 是 | 100 | 1 |

### A.3 关卡配置速查（v2.0更新）

| 关卡类型 | 关卡编号 | 路线 | 层数 | 距离 | 爬升 | 难度 |
|---------|---------|------|------|------|------|------|
| 新手教学关 | 0 | 路环东北步行径 | 3 | 4.3km | 60m | ⭐ |
| 新手关 | 1-3 | 香港郊野公园入门 | 5 | 10km | 150m | ⭐⭐ |
| 澳门新手关 | 1.5 | 路环步行径 | 4 | 8.1km | 80m | ⭐⭐ |
| 标准关 | 4-6 | 麦理浩径第2-4段 | 7 | 14km | 400-600m | ⭐⭐⭐ |
| 挑战关 | 7-9 | 麦理浩径第5-8段 | 9 | 18km | 600-800m | ⭐⭐⭐⭐ |
| 精英关 | 10 | 麦理浩径第7段 | 11 | 22km | 800-1000m | ⭐⭐⭐⭐⭐ |
| BOSS关 | 11+ | 麦理浩径第10段 | 13 | 26km | 1000-1200m | ⭐⭐⭐⭐⭐⭐ |

---

## 附录B：术语表（v2.0更新）

| 术语 | 说明 |
|------|------|
| **AutoLoad** | Godot的单例自动加载机制，用于全局管理器 |
| **SceneTree** | Godot的场景树，管理所有节点的层级关系 |
| **Signal** | Godot的信号机制，用于节点间通信 |
| **Tween** | Godot的补间动画系统，用于平滑过渡效果 |
| **Extension** | Godot的扩展机制，用于集成C++模块 |
| **Card Framework** | 开源的卡牌拖拽和容器框架 |
| **godot_parser** | Python库，用于解析和生成Godot场景文件 |
| **Steamworks SDK** | Steam平台的官方开发工具包 |
| **PC端** | 个人电脑平台（Windows），指本项目的目标平台 |
| **Steam平台** | Valve公司的数字发行平台 |
| **UI** | User Interface，用户界面 |
| **UX** | User Experience，用户体验 |
| **FPS** | Frames Per Second，每秒帧数 |
| **LOD** | Level of Detail，细节层次 |
| **CI/CD** | Continuous Integration/Continuous Delivery，持续集成/持续交付 |
| **累积爬升** | 所有上坡路段的垂直上升高度总和，局外稀有货币（v2.0） |
| **补给系统** | 管理水、运动饮料、巧克力等补给的消耗与恢复（v2.0） |
| **疲劳系统** | 管理疲劳积累、休息次数、疲劳突破机制（v2.0） |
| **上坡下坡** | 区分上坡（计入累积爬升）和下坡（不计入累积爬升）的地形机制（v2.0） |
| **膝盖损伤** | 下坡时可能触发的损伤，每穿越3张陡坡下坡卡检测一次（v2.0） |
| **真实路线** | 基于麦理浩径、澳门路线等真实徒步路线设计的关卡（v2.0） |

---

## 附录C：参考资料

### C.1 Godot官方文档

- [Godot Engine官方文档](https://docs.godotengine.org/)
- [GDScript参考](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [节点和场景](https://docs.godotengine.org/en/stable/tutorials/scripting/node_and_scene_tree.html)
- [信号](https://docs.godotengine.org/en/stable/tutorials/scripting/signals.html)

### C.2 第三方项目

- [Card Framework GitHub仓库](https://github.com/chun92/card-framework)
- [godot_parser GitHub仓库](https://github.com/stevearc/godot_parser)
- [Steamworks SDK文档](https://partner.steamgames.com/doc/)

### C.3 游戏设计文档

- [《大湾区徒步》游戏设计文档 v7.0最终版](../design/game_design_doc_final.md)

---

**文档结束**

《大湾区徒步》Godot游戏开发技术架构文档 v2.0 完整版，基于《游戏设计文档 v7.0最终版》全面更新，新增累积爬升、补给系统、疲劳系统、上坡下坡机制等最新设计内容，为流动性强的初级开发工程师提供了标准化的技术架构参考，确保开发团队能够快速上手并保持代码质量一致性。

**文档编制**：Godot架构及技术专家团队  
**文档日期**：2026年01月30日  
**文档版本**：v2.0  
**更新内容**：
- 将"海拔数"货币更新为"累积爬升"
- 新增补给系统架构
- 新增疲劳系统架构
- 新增上坡下坡机制架构
- 更新地形类型（增加缓坡下坡、陡坡下坡）
- 新增真实路线配置（麦理浩径、澳门路线）
- 更新体能消耗和疲劳积累计算公式
- 新增膝盖损伤检测算法
- 更新UI场景架构（增加累积爬升显示）
- 更新核心公式速查
