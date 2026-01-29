# 《大湾区徒步》Godot游戏开发技术架构文档

**文档类型**：技术架构文档  
**适用对象**：初级开发工程师  
**Godot版本**：4.5.1  
**发布平台**：Steam（PC端）  
**文档版本**：v1.0  
**编制日期**：2026年01月28日  
**责任团队**：Godot架构及技术专家团队  

---

## 文档导读

### 文档定位

本文档为《大湾区徒步》Godot 4.5.1 PC端开发的标准技术架构文档，面向流动性强的初级开发工程师。文档采用分层架构设计，通过模块化、标准化、规范化的方式，降低学习曲线，确保开发团队能够快速上手并保持代码质量一致性。

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
├─ 第三章：UI/UX架构设计
│   ├─ 3.1 UI场景架构
│   └─ 3.2 交互系统设计
├─ 第四章：数据持久化架构
│   ├─ 4.1 存档系统设计
│   └─ 4.2 配置系统设计
└─ 第五章：性能优化架构
    ├─ 5.1 性能监控设计
    └─ 5.2 优化策略设计

【高级模块】（8-10天）
├─ 第六章：Steam平台集成
│   ├─ 6.1 成就系统设计
│   └─ 6.2 排行榜系统设计
├─ 第七章：工具链架构
│   ├─ 7.1 godot_parser集成
│   └─ 7.2 自动化构建流程
└─ 第八章：开发规范
    ├─ 8.1 代码规范
    └─ 8.2 工作流程规范
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

---

## 第一章：整体架构设计

### 1.1 架构原则

#### 1.1.1 核心设计原则

**分层原则**：系统按职责分为表现层、逻辑层、数据层三层，每层只关注自身职责，通过明确接口进行通信。

**模块化原则**：每个功能模块独立封装，低耦合高内聚，支持并行开发和独立测试。

**数据驱动原则**：游戏数据（卡牌属性、关卡配置、数值平衡）通过配置文件管理，支持热更新和版本控制。

**性能优先原则**：针对PC端特性实施性能优化策略，确保在高分辨率和高刷新率下稳定运行。

**标准化原则**：统一命名规范、代码风格、接口定义，降低人员变动对项目的影响。

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
| **CardSystem** | 卡牌生成、穿越判定、连击计算 | AttributeSystem、ComboSystem | BattleUI、ComboUI |
| **AttributeSystem** | 五维属性管理、恢复计算 | SaveManager | CardSystem、TerrainSystem |
| **ComboSystem** | 连击检测、奖励计算 | PhotoCardSystem | CardSystem、ComboUI |
| **EconomySystem** | 经济系统管理、商店交易 | SaveManager | ShopUI、PlayerData |
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
│       ├── localization/             # 本地化文件
│       └── culture/                  # 文化元素数据
├── scenes/                           # 场景文件目录
│   ├── main/                         # 主场景
│   ├── battle/                       # 战斗场景
│   ├── journey/                      # 路线场景
│   └── result/                       # 结算场景
├── scripts/                          # 核心脚本目录
│   ├── core/                         # 核心系统
│   ├── gameplay/                     # 玩法逻辑
│   ├── ui/                           # UI逻辑
│   ├── data/                         # 数据管理
│   └── utils/                        # 工具类
├── tools/                            # 工具脚本目录
│   ├── scene_builder.py              # 场景构建工具
│   ├── card_generator.py             # 卡牌生成工具
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
## 创建日期：2026-01-28
## 最后修改：2026-01-28

extends Node
class_name GameManager
```

**类注释**：

```gdscript
## 类名称：CardSystem
## 职责描述：管理卡牌生成、穿越判定、连击计算等卡牌相关逻辑
## 依赖模块：AttributeSystem、ComboSystem
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
# 计算难度系数
# 逻辑说明：
# 1. 基础难度为1.0
# 2. 每游玩1次，难度增加0.02
# 3. 难度上限为1.25
# 4. 应用游玩次数修正
var difficulty_coefficient = 1.0 + (play_count - 1) * 0.02
difficulty_coefficient = min(difficulty_coefficient, 1.25)
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
│  └─ SteamManager：Steam平台集成、成就系统                      │
├─────────────────────────────────────────────────────────────────┤
│  核心系统层                                                     │
│  ├─ CardSystem：卡牌系统、穿越判定、连击计算                     │
│  ├─ AttributeSystem：五维属性管理、恢复计算                    │
│  ├─ ComboSystem：连击检测、奖励计算                            │
│  ├─ EconomySystem：经济系统管理、商店交易                       │
│  ├─ TerrainSystem：地形障碍系统、特殊效果                      │
│  ├─ WeatherSystem：天气系统、环境影响                         │
│  └─ PhotoCardSystem：照片卡系统、流派加成                      │
├─────────────────────────────────────────────────────────────────┤
│  数据管理层                                                     │
│  ├─ PlayerData：玩家数据、配置管理                             │
│  ├─ ConfigData：配置数据、难度设置                             │
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

- **卡牌生成**：根据关卡配置和难度系数，程序化生成卡牌序列
- **穿越判定**：处理用户点击、长按等交互，判断是否满足穿越条件
- **连击计算**：检测连击状态，计算连击奖励，触发连击效果
- **层完成检测**：检测当前层是否全部穿越，触发层完成事件
- **卡牌状态管理**：管理卡牌的穿越状态、悬停状态等

**职责边界**：

- **不负责**：属性消耗计算（由AttributeSystem负责）
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
│  │   输入：关卡等级、游玩次数、难度系数                           │
│  │   输出：卡牌数据数组                                          │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ LayerContainer（分层容器，继承CardContainer）              │
│  │   职责：管理单层卡牌、计算卡牌位置、检测层完成                   │
│  │   扩展：正三角布局、海拔显示、层高亮/变暗                       │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ HikingCard（徒步卡牌，继承Card）                             │
│  │   职责：处理卡牌交互、管理穿越状态、播放穿越效果                 │
│  │   扩展：鼠标悬停效果、长按检测、地形确认框                       │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ CardPool（卡牌对象池）                                       │
│      职责：管理卡牌对象复用、优化内存分配                          │
│      实现：预分配卡牌对象、动态扩展对象池                          │
└─────────────────────────────────────────────────────────────────┘
```

#### 2.1.3 数据结构设计

**卡牌数据结构**：

```gdscript
## 卡牌类型枚举
enum CardType {
    SCENERY,      # 风景卡
    TERRAIN,      # 地形障碍卡
    RESOURCE,     # 资源卡
    ENVIRONMENT   # 环境卡
}

## 地形类型枚举
enum TerrainType {
    FLAT_ROAD,    # 平坦道路
    UPHILL_ROAD,  # 上坡路
    STEEP_SLOPE,  # 陡坡
    ROCKY_PATH,   # 乱石路
    STREAM,       # 溪流
    CLIFF_PATH    # 悬崖栈道
}

## 卡牌数据结构
struct CardData:
    String id              # 卡牌唯一标识
    String name            # 卡牌名称
    String description     # 卡牌描述
    CardType card_type     # 卡牌类型
    Texture2D texture      # 卡牌纹理
    int stamina_cost       # 体能消耗
    int eco_value_reward   # 环保值奖励
    bool is_crossed        # 是否已穿越
    Dictionary extra_data   # 扩展数据（如地形类型、特殊效果等）
```

**层级数据结构**：

```gdscript
## 层级数据结构
struct LayerData:
    int layer_index        # 层级索引
    int altitude          # 海拔值
    int max_cards         # 最大卡牌数
    Array[CardData] cards # 卡牌数组
```

#### 2.1.4 接口定义

**卡牌系统公开接口**：

```gdscript
## 卡牌系统公开接口定义

# 卡牌生成接口
## 参数：
##   - level: 关卡等级
##   - play_count: 游玩次数
func generate_level(level: int, play_count: int) -> void

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

# PC端：卡牌悬停信号
## 参数：card: 悬停的卡牌
signal card_hovered(card: HikingCard)

# PC端：卡牌悬停取消信号
## 参数：card: 取消悬停的卡牌
signal card_unhovered(card: HikingCard)
```

#### 2.1.5 核心算法描述

**卡牌生成算法**：

**算法目标**：根据关卡配置和游玩次数，生成符合规则要求的卡牌序列

**输入参数**：
- `level`：关卡等级（1-10）
- `play_count`：游玩次数（1+）
- `difficulty_coefficient`：难度系数（0.8-1.25）

**输出结果**：卡牌数据数组

**算法步骤**：

1. **确定关卡配置**：
   - 根据游玩次数确定关卡层数（5/7/9/11层）
   - 根据游玩次数和关卡等级确定难度系数
   - 根据难度系数计算地形障碍率、资源卡率、环境卡率

2. **计算卡牌权重**：
   - 初始权重：风景卡0.4、地形卡0.3、资源卡0.2、环境卡0.1
   - 根据难度系数调整权重（地形卡权重随难度增加）
   - 归一化权重（确保总和为1.0）

3. **生成每层卡牌**：
   - 根据层级和关卡类型确定卡牌数量
   - 循环生成每张卡牌：
     - 应用保底机制：每层至少1张风景卡（最后一张）
     - 应用防连卡机制：禁止连续3张同类型卡牌
     - 根据权重随机选择卡牌类型
     - 根据类型随机选择具体卡牌

4. **验证卡牌序列**：
   - 验证每层至少1张风景卡
   - 验证无连续3张同类型卡牌
   - 验证地形卡数量符合配置要求
   - 如果验证失败，重新生成该层

**伪代码**：

```
算法：generate_card_sequence(level, play_count, difficulty_coefficient)
输入：level（关卡等级），play_count（游玩次数），difficulty_coefficient（难度系数）
输出：card_sequence（卡牌序列）

1. 确定关卡配置
   total_layers ← 根据play_count确定（5/7/9/11）
   layer_configs ← 根据total_layers和level确定每层卡牌数量
   
2. 初始化卡牌序列
   card_sequence ← 空数组
   
3. 对于每一层（从第1层到第total_layers层）
   3.1 获取当前层配置
       layer_config ← layer_configs[layer_index]
       card_count ← layer_config.card_count
       
   3.2 初始化生成状态
       sequence ← 空数组
       last_two_types ← 空数组（记录最后两张卡牌类型）
       
   3.3 循环生成每张卡牌（从第1张到第card_count张）
       3.3.1 检查是否为最后一张卡牌
           如果是最后一张且sequence中无风景卡：
               生成风景卡（保底机制）
           否则：
               选择卡牌类型（考虑防连卡机制）
       
       3.3.2 生成卡牌数据
           根据卡牌类型和difficulty_coefficient生成具体卡牌
       
       3.3.3 添加到sequence
           sequence.append(card_data)
       
       3.3.4 更新类型记录
           last_two_types.append(card_data.card_type)
           如果last_two_types.size() > 2：
               last_two_types.pop_front()
   
   3.4 验证sequence
       如果验证失败：
           重新生成该层（回到3.3）
   
   3.5 添加到card_sequence
       card_sequence.append(sequence)

4. 返回card_sequence
```

**穿越判定算法**：

**算法目标**：判断卡牌是否可以穿越，处理不同类型的穿越条件

**输入参数**：
- `card`：要穿越的卡牌
- `player_stamina`：玩家当前体能值

**输出结果**：穿越是否成功

**算法步骤**：

1. **获取卡牌信息**：
   - 获取卡牌类型（风景卡/地形卡/资源卡/环境卡）
   - 获取地形类型（如果是地形卡）
   - 获取体能消耗
   - 获取特殊效果

2. **检查穿越条件**：
   - **风景卡/资源卡/环境卡**：
     - 无条件穿越
     - 返回成功
   
   - **地形卡**：
     - **平坦道路**：
       - 无条件穿越
       - 返回成功
     - **上坡路/乱石路/溪流**：
       - 需要长按1.5秒
       - 检查长按是否完成
       - 如果完成，进入步骤3
       - 如果未完成，返回失败
     - **陡坡/悬崖栈道**：
       - 需要长按1.5秒
       - 检查长按是否完成
       - 如果完成，显示确认框
       - 等待用户确认
       - 如果确认，进入步骤3
       - 如果取消，返回失败

3. **检查体能消耗**：
   - 比较玩家当前体能与卡牌消耗
   - 如果体能不足，返回失败
   - 如果体能充足，进入步骤4

4. **执行穿越**：
   - 消耗体能
   - 标记卡牌为已穿越
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
   special_effects ← card.special_effects

2. 检查穿越条件
   如果card_type是SCENERY或RESOURCE或ENVIRONMENT：
       进入步骤3
   否则如果card_type是TERRAIN：
       如果terrain_type是FLAT_ROAD：
           进入步骤3
       否则如果terrain_type是UPHILL_ROAD或ROCKY_PATH或STREAM：
           如果长按时间 >= 1.5秒：
               进入步骤3
           否则：
               返回false（长按时间不足）
       否则如果terrain_type是STEEP_SLOPE或CLIFF_PATH：
           如果长按时间 >= 1.5秒：
               显示确认框
               等待用户确认
               如果用户确认：
                   进入步骤3
               否则：
                   返回false（用户取消）
           否则：
               返回false（长按时间不足）
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
   应用特殊效果（special_effects）
   播放穿越效果（音效、动画、粒子）
   返回true（穿越成功）
```

### 2.2 属性系统架构

#### 2.2.1 系统职责定义

**核心职责**：

- **属性管理**：管理五维属性（体能、饥饿、口渴、疲劳、心率）的当前值
- **恢复计算**：根据五维属性的当前值，计算体能的恢复速率
- **消耗处理**：处理各种原因导致的属性消耗（地形卡、天气等）
- **边界检查**：检查属性是否达到警告或危险阈值，触发相应事件
- **恢复系统**：管理定时恢复机制，持续恢复体能

**职责边界**：

- **不负责**：属性消耗的原因判断（由CardSystem负责）
- **不负责**：恢复速率的显示（由UIManager负责）
- **不负责**：存档管理（由SaveManager负责）
- **不负责**：属性数值的平衡调整（由策划负责）

#### 2.2.2 系统架构设计

```
属性系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  AttributeSystem（属性系统管理器）                              │
│  职责：协调属性管理、恢复计算、边界检测                           │
├─────────────────────────────────────────────────────────────────┤
│  五维属性模块                                                  │
│  ├─ Stamina（体能）                                           │
│  │   职责：管理玩家当前体能值、处理体能消耗、执行体能恢复           │
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
└─────────────────────────────────────────────────────────────────┘
```

#### 2.2.3 数据结构设计

**属性数据结构**：

```gdscript
## 五维属性数据结构
struct AttributeData:
    String attribute_name  # 属性名称
    float current_value   # 当前值
    float min_value       # 最小值
    float max_value       # 最大值
    float warning_value   # 警告阈值
    float critical_value # 危险阈值
```

**属性定义**：

```gdscript
## 五维属性定义

## 体能（Stamina）
## 取值范围：0-100
## 起始值：100
## 特点：主属性，为0时游戏结束
## 影响因素：地形卡消耗、天气影响、恢复速率
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

### 2.3 经济系统架构

#### 2.3.1 系统职责定义

**核心职责**：

- **货币管理**：管理三种货币（徒步数、海拔数、环保值）的当前值
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
经济系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  EconomySystem（经济系统管理器）                                │
│  职责：协调货币管理、商店交易、资源同步                           │
├─────────────────────────────────────────────────────────────────┤
│  货币管理模块                                                  │
│  ├─ HikingNumber（徒步数）                                     │
│  │   职责：管理玩家当前徒步数（局外经验值）                      │
│  │   特点：用于解锁内容、升级属性                               │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ AltitudeNumber（海拔数）                                   │
│  │   职责：管理玩家当前海拔数（局外稀有货币）                    │
│  │   特点：用于购买高级装备、解锁槽位                            │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ EcoValue（环保值）                                        │
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

**货币数据结构**：

```gdscript
## 货币类型枚举
enum CurrencyType {
    HIKING_NUMBER,  # 徒步数（局外经验值）
    ALTITUDE_NUMBER, # 海拔数（局外稀有货币）
    ECO_VALUE      # 环保值（局内货币）
}

## 货币数据结构
struct CurrencyData:
    CurrencyType type   # 货币类型
    int current_amount  # 当前数量
    String name        # 货币名称
    String description # 货币描述
```

**商品数据结构**：

```gdscript
## 商品数据结构
struct ItemData:
    String id                    # 商品唯一标识
    String name                  # 商品名称
    String description           # 商品描述
    CurrencyType currency_type    # 货币类型
    int price                   # 商品价格
    String category             # 商品分类（"food"/"water"/"equipment"/"photo_card"）
    Dictionary effect           # 商品效果
    Texture2D icon              # 商品图标
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

## 第三章：UI/UX架构设计

### 3.1 UI场景架构

#### 3.1.1 UI场景职责划分

**场景分类**：

| 场景类型 | 场景名称 | 职责范围 | 所属层级 |
|---------|---------|---------|---------|
| **主场景** | MainMenu | 游戏主菜单、模式选择、设置 | 表现层 |
| **角色场景** | CharacterSelection | 角色选择、角色属性预览 | 表现层 |
| **升级场景** | UpgradeMenu | 属性升级、装备兑换 | 表现层 |
| **战斗场景** | BattleScene | 核心战斗、卡牌交互、属性显示 | 表现层 |
| **路线场景** | JourneyScene | 路线选择、商店交易 | 表现层 |
| **结算场景** | VictoryScene | 胜利结算、奖励展示 | 表现层 |
| **结算场景** | DefeatScene | 失败结算、进度显示 | 表现层 |
| **设置场景** | SettingsMenu | 游戏设置、图形设置、音频设置 | 表现层 |

#### 3.1.2 UI场景架构设计

```
UI场景架构：

┌─────────────────────────────────────────────────────────────────┐
│  UIManager（UI场景管理器）                                    │
│  职责：协调UI场景切换、UI交互控制、UI事件处理                   │
├─────────────────────────────────────────────────────────────────┤
│  UI场景层（PC端布局）                                          │
│  ├─ MainMenu（主菜单场景）                                    │
│  │   职责：游戏主菜单、模式选择、键盘快捷键                       │
│  │   PC端特性：键盘快捷键提示、高分辨率显示                      │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ CharacterSelection（角色选择场景）                          │
│  │   职责：角色选择、角色属性预览                               │
│  │   PC端特性：键盘导航、鼠标悬停效果                            │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ UpgradeMenu（升级菜单场景）                                │
│  │   职责：属性升级、装备兑换                                   │
│  │   PC端特性：工具提示系统、高分辨率显示                          │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ BattleScene（战斗场景）                                    │
│  │   职责：核心战斗、卡牌交互、属性显示                           │
│  │   PC端特性：鼠标悬停效果、键盘快捷键、工具提示                  │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ JourneyScene（路线场景）                                   │
│  │   职责：路线选择、商店交易                                   │
│  │   PC端特性：高分辨率显示、键盘导航                             │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ VictoryScene（胜利结算场景）                              │
│  │   职责：胜利结算、奖励展示                                   │
│  │   PC端特性：Steam成就弹窗、高分辨率显示                         │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ DefeatScene（失败结算场景）                                │
│  │   职责：失败结算、进度显示                                   │
│  │   PC端特性：Steam排行榜弹窗、高分辨率显示                        │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ SettingsMenu（设置场景）                                   │
│      职责：游戏设置、图形设置、音频设置                            │
│      PC端特性：高分辨率支持、5.1声道支持、VSync支持                │
└─────────────────────────────────────────────────────────────────┘
```

#### 3.1.3 UI节点树设计

**标准UI节点树结构**：

```
标准UI场景节点树：

场景根节点（Control）
├─ BackgroundLayer（背景层，PC端高分辨率）
│   ├─ BackgroundTexture（背景纹理）
│   ├─ ParallaxBackground（视差背景，可选）
│   └─ PostProcessing（后处理，可选，PC端高级特效）
├─ UIRootLayer（UI根层）
│   ├─ HeaderLayer（头部层）
│   │   ├─ TitleLabel（标题标签）
│   │   ├─ BackButton（返回按钮）
│   │   └─ KeyboardShortcuts（键盘快捷键提示，PC端）
│   ├─ ContentLayer（内容层）
│   │   ├─ MainContainer（主容器）
│   │   │   ├─ LeftPanel（左面板，可选）
│   │   │   ├─ CenterPanel（中央面板）
│   │   │   └─ RightPanel（右面板，可选）
│   │   └─ TooltipLayer（工具提示层，PC端）
│   │       └─ TooltipPanel（工具提示面板）
│   └─ FooterLayer（底部层）
│       ├─ StatusPanel（状态面板）
│       ├─ ResourcePanel（资源面板）
│       └─ ActionPanel（操作面板）
└─ OverlayLayer（覆盖层）
    ├─ DialogLayer（对话框层）
    ├─ PopupLayer（弹窗层）
    └─ EffectLayer（特效层）
```

**BattleScene节点树（PC端）**：

```
BattleScene节点树（PC端）：

BattleScene（Node2D）
├─ BackgroundLayer（背景层，PC端高分辨率）
│   └─ BackgroundTexture（背景纹理，支持4K）
├─ CardLayer（卡牌层）
│   ├─ Camera2D（摄像机，支持平滑移动）
│   ├─ LayerContainer[11]（分层容器，11层）
│   │   └─ HikingCard[N]（徒步卡牌，鼠标悬停效果）
│   └─ CurrentLayerIndicator（当前层指示器）
├─ AttributePanel（属性面板，PC端布局）
│   ├─ StaminaBar（体能条）
│   ├─ HungerBar（饥饿条）
│   ├─ ThirstBar（口渴条）
│   ├─ FatigueBar（疲劳条）
│   └─ HeartRateLabel（心率标签）
├─ ComboPanel（连击面板，PC端）
│   ├─ ComboCounter（连击计数器）
│   ├─ ComboTypeLabel（连击类型）
│   ├─ ClimbComboCounter（攀登连击计数器）
│   └─ ComboTooltip（连击提示）
├─ ResourcePanel（资源面板，PC端）
│   ├─ EcoValueLabel（环保值标签）
│   ├─ HikingNumLabel（徒步数标签）
│   └─ AltitudeNumLabel（海拔数标签）
├─ WeatherPanel（天气面板，PC端）
│   ├─ WeatherIcon（天气图标）
│   ├─ WeatherLabel（天气标签）
│   └─ WeatherTooltip（天气效果提示）
├─ KeyboardShortcutPanel（键盘快捷键面板，PC端）
│   └─ ShortcutList（快捷键列表）
└─ EffectLayer（特效层，GPU加速）
    ├─ ParticleSystem（粒子系统）
    ├─ VFXContainer（特效容器）
    └─ ScreenShake（屏幕震动）
```

### 3.2 交互系统设计

#### 3.2.1 输入处理架构

**输入类型分类**：

| 输入类型 | 处理方式 | PC端特性 |
|---------|---------|---------|
| **键盘输入** | 通过InputEventKey处理，映射到Action | 支持快捷键、组合键 |
| **鼠标输入** | 通过InputEventMouseButton处理 | 支持悬停、拖拽、双击 |
| **滚轮输入** | 通过InputEventMouse处理 | 支持缩放、滚动 |
| **触摸输入** | 通过InputEventScreenTouch处理 | PC端不使用 |

**输入处理流程**：

```
输入处理流程：

1. 输入事件捕获
   ├─ 键盘输入 → InputEventKey
   ├─ 鼠标输入 → InputEventMouseButton
   ├─ 滚轮输入 → InputEventMouse
   └─ 触摸输入 → InputEventScreenTouch（PC端不使用）

2. 输入事件分发
   ├─ 通过InputEvent.action_match()匹配Action
   ├─ 通过信号的connect()连接到处理器
   └─ 通过_call_deferred()异步处理

3. 输入事件处理
   ├─ 检查输入有效性（是否在交互状态）
   ├─ 执行对应处理逻辑
   └─ 发射相应信号（如ui_accept、ui_cancel）

4. 输入反馈
   ├─ 播放音效（AudioManager）
   ├─ 播放动画（Tween）
   └─ 更新UI（UIManager）
```

#### 3.2.2 键盘快捷键设计

**PC端键盘快捷键定义**：

| 快捷键 | 功能 | 说明 |
|-------|------|------|
| **W / A / S / D** | 卡牌选择 | 上下左右选择卡牌 |
| **Space** | 确认/穿越 | 确认选择、穿越卡牌 |
| **Escape** | 取消/返回 | 取消操作、返回上一级 |
| **Tab** | 切换焦点 | 切换焦点、显示快捷键 |
| **1 / 2 / 3 / 4** | 快速使用道具 | 快速使用第1-4号道具 |
| **F5** | 快速存档 | 快速保存当前进度 |
| **F9** | 快速截图 | Steam原生截图 |
| **F12** | 截图 | Steam原生截图 |
| **P** | 暂停/继续 | 暂停/继续游戏 |

**快捷键配置格式**：

```ini
# project.godot中的快捷键配置

[input]
ui_left={
    "deadzone": 0.5,
    "events": [Object(InputEventKey,"keycode":65,"physical_keycode":0)]
}

ui_right={
    "deadzone": 0.5,
    "events": [Object(InputEventKey,"keycode":68,"physical_keycode":0)]
}

ui_up={
    "deadzone": 0.5,
    "events": [Object(InputEventKey,"keycode":87,"physical_keycode":0)]
}

ui_down={
    "deadzone": 0.5,
    "events": [Object(InputEventKey,"keycode":83,"physical_keycode":0)]
}

ui_accept={
    "deadzone": 0.5,
    "events": [Object(InputEventKey,"keycode":32,"physical_keycode":0)]
}

ui_cancel={
    "deadzone": 0.5,
    "events": [Object(InputEventKey,"keycode":4194306,"physical_keycode":0)]
}
```

#### 3.2.3 鼠标交互设计

**鼠标交互类型**：

| 交互类型 | 处理方式 | PC端特性 |
|---------|---------|---------|
| **鼠标悬停** | 通过mouse_entered/mouse_exited信号 | 显示工具提示、缩放效果 |
| **鼠标点击** | 通过InputEventMouseButton处理 | 穿越卡牌、选择选项 |
| **鼠标拖拽** | 通过Card Framework的拖拽系统 | 不使用（本游戏不需要） |
| **双击** | 通过InputEventMouseButton.double_click | 快速穿越（可选） |

**鼠标悬停效果设计**：

```
鼠标悬停效果流程：

1. 鼠标进入卡牌区域
   ├─ 触发mouse_entered信号
   ├─ 发射card_hovered信号
   ├─ 播放缩放动画（1.0 → 1.1倍）
   └─ 启动工具提示延迟计时器（0.5秒）

2. 工具提示延迟计时器到期
   ├─ 检查鼠标是否仍在卡牌区域
   ├─ 如果仍在，显示工具提示
   └─ 发射card_tooltip_shown信号

3. 鼠标离开卡牌区域
   ├─ 触发mouse_exited信号
   ├─ 发射card_unhovered信号
   ├─ 取消工具提示延迟计时器
   ├─ 隐藏工具提示
   └─ 播放缩放动画（1.1 → 1.0倍）
```

#### 3.2.4 工具提示系统设计

**工具提示系统职责**：

- **提示显示**：根据鼠标悬停位置和内容，显示工具提示
- **提示隐藏**：鼠标离开时隐藏工具提示
- **提示定位**：计算工具提示位置，避免超出屏幕边界
- **提示更新**：动态更新工具提示内容

**工具提示显示规范**：

```
工具提示显示规范：

1. 提示内容
   ├─ 卡牌名称
   ├─ 卡牌类型
   ├─ 体能消耗
   ├─ 环保值奖励
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

## 第四章：数据持久化架构

### 4.1 存档系统设计

#### 4.1.1 系统职责定义

**核心职责**：

- **存档管理**：管理游戏存档的创建、读取、删除、同步
- **数据序列化**：将游戏数据序列化为JSON格式
- **数据反序列化**：将JSON格式的存档数据反序列化为游戏数据
- **存档验证**：验证存档数据的完整性和一致性
- **Steam云同步**：同步存档到Steam云存储

**职责边界**：

- **不负责**：游戏数据的收集（由GameManager负责）
- **不负责**：存档数据的具体内容（由PlayerData负责）
- **不负责**：存档数据的业务逻辑（由策划负责）
- **不负责**：存档数据的加密（由策划决定）

#### 4.1.2 系统架构设计

```
存档系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  SaveManager（存档管理器）                                    │
│  职责：协调存档管理、Steam云同步、数据验证                       │
├─────────────────────────────────────────────────────────────────┤
│  存档管理模块                                                  │
│  ├─ SaveSlotManager（存档槽管理器）                            │
│  │   职责：管理存档槽、创建新存档、删除存档                        │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ DataSerializer（数据序列化器）                             │
│  │   职责：将游戏数据序列化为JSON格式、反序列化JSON数据            │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ SaveValidator（存档验证器）                                │
│  │   职责：验证存档数据的完整性、一致性、校验和                      │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ AutoSaveManager（自动存档管理器）                           │
│      职责：定时自动存档、关键节点自动存档                            │
├─────────────────────────────────────────────────────────────────┤
│  Steam云同步模块                                                │
│  ├─ CloudSyncManager（云同步管理器）                            │
│  │   职责：Steam云同步、云存档冲突解决                            │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ CloudSyncScheduler（云同步调度器）                         │
│      职责：调度云同步任务、处理同步失败                            │
└─────────────────────────────────────────────────────────────────┘
```

#### 4.1.3 数据结构设计

**存档数据结构**：

```gdscript
## 存档数据结构
struct SaveData:
    String version          # 存档版本
    float timestamp        # 时间戳
    int play_time_seconds  # 游玩时间（秒）
    PlayerData player_data  # 玩家数据
    ProgressData progress  # 进度数据
    SettingsData settings  # 设置数据
    String checksum        # 校验和
```

**玩家数据结构**：

```gdscript
## 玩家数据结构
struct PlayerData:
    int current_level        # 当前关卡
    int play_count          # 游玩次数
    int max_level           # 最大关卡
    Dictionary attributes  # 五维属性
    Dictionary currencies  # 三种货币
    Dictionary inventory    # 库存
    Dictionary achievements # 成就状态
```

#### 4.1.4 接口定义

**存档系统公开接口**：

```gdscript
## 存档系统公开接口定义

# 存档游戏接口
## 参数：
##   - slot: 存档槽位（0-2）
## 返回值：是否存档成功
func save_game(slot: int) -> bool

# 读取游戏接口
## 参数：
##   - slot: 存档槽位（0-2）
## 返回值：是否读取成功
func load_game(slot: int) -> bool

# 删除存档接口
## 参数：
##   - slot: 存档槽位（0-2）
## 返回值：是否删除成功
func delete_save(slot: int) -> bool

# 获取最新存档槽位接口
## 返回值：存档槽位（-1表示无存档）
func get_latest_save_slot() -> int

# 获取存档槽位信息接口
## 参数：
##   - slot: 存档槽位（0-2）
## 返回值：存档槽位信息（SaveSlotInfo）
func get_save_slot_info(slot: int) -> SaveSlotInfo
```

**信号定义**：

```gdscript
## 存档系统信号定义

# 存档完成信号
## 参数：
##   - slot: 存档槽位
##   - success: 是否成功
signal save_completed(slot: int, success: bool)

# 读取完成信号
## 参数：
##   - slot: 存档槽位
##   - success: 是否成功
signal load_completed(slot: int, success: bool)

# 存档槽位变化信号
signal save_slots_changed()

# Steam云同步完成信号
## 参数：
##   - success: 是否成功
signal cloud_sync_completed(success: bool)
```

#### 4.1.5 核心算法描述

**校验和计算算法**：

**算法目标**：计算存档数据的校验和，用于验证存档完整性

**输入参数**：
- `save_data`：存档数据字典

**输出结果**：校验和（整数）

**算法步骤**：

1. **序列化存档数据**：
   - 将存档数据字典转换为JSON字符串
   - 去除空白字符和换行符

2. **计算哈希值**：
   - 使用Godot内置的hash()函数计算JSON字符串的哈希值
   - 哈希算法：MurmurHash3（Godot默认算法）

3. **返回校验和**：
   - 将哈希值转换为整数返回

**伪代码**：

```
算法：calculate_checksum(save_data)
输入：save_data（存档数据字典）
输出：checksum（校验和）

1. 序列化存档数据
   json_string ← JSON.stringify(save_data)

2. 清理JSON字符串
   cleaned_string ← 移除json_string中的空白字符和换行符

3. 计算哈希值
   hash_value ← hash(cleaned_string)

4. 转换为整数
   checksum ← int(hash_value)

5. 返回checksum
```

### 4.2 配置系统设计

#### 4.2.1 系统职责定义

**核心职责**：

- **配置管理**：管理游戏配置的加载、保存、更新
- **配置验证**：验证配置数据的有效性
- **配置热更新**：支持配置的热更新（重启后生效）

**职责边界**：

- **不负责**：配置数据的具体内容（由策划负责）
- **不负责**：配置数据的业务逻辑（由各系统负责）
- **不负责**：配置数据的平衡调整（由策划负责）

#### 4.2.2 系统架构设计

```
配置系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  ConfigManager（配置管理器）                                  │
│  职责：协调配置管理、配置验证、配置热更新                         │
├─────────────────────────────────────────────────────────────────┤
│  配置加载模块                                                  │
│  ├─ ConfigLoader（配置加载器）                                │
│  │   职责：从JSON/TRES文件加载配置数据                            │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ ConfigValidator（配置验证器）                             │
│  │   职责：验证配置数据的有效性、数据类型、范围                      │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ ConfigWatcher（配置监视器）                               │
│      职责：监视配置文件变化、触发配置重载                           │
└─────────────────────────────────────────────────────────────────┘
```

#### 4.2.3 配置数据结构

**游戏配置数据结构**：

```gdscript
## 游戏配置数据结构
struct GameConfig:
    float difficulty_coefficient  # 难度系数（0.8-1.25）
    int max_combo                 # 最大连击数（默认10）
    float combo_interval         # 连击间隔（默认2.5秒）
    float cross_layer_interval   # 跨层连击间隔（默认4.0秒）
    Dictionary card_weights     # 卡牌权重
    Dictionary terrain_costs     # 地形消耗
```

---

## 第五章：性能优化架构

### 5.1 性能监控设计

#### 5.1.1 系统职责定义

**核心职责**：

- **性能监控**：实时监控游戏性能指标（FPS、内存、Draw Calls）
- **性能分析**：分析性能瓶颈，提供优化建议
- **自动优化**：根据性能指标自动应用优化策略
- **性能报告**：生成性能报告，记录性能数据

**职责边界**：

- **不负责**：性能优化的具体实现（由各系统负责）
- **不负责**：性能指标的平衡调整（由策划负责）
- **不负责**：性能问题的根本原因分析（由技术负责）

#### 5.1.2 系统架构设计

```
性能监控系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  PerformanceMonitor（性能监控管理器）                          │
│  职责：协调性能监控、性能分析、自动优化                           │
├─────────────────────────────────────────────────────────────────┤
│  性能监控模块                                                  │
│  ├─ FPSMonitor（帧率监控器）                                   │
│  │   职责：监控当前帧率、计算平均帧率、检测帧率波动                  │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ MemoryMonitor（内存监控器）                                │
│  │   职责：监控内存占用、检测内存泄漏、记录内存峰值                  │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ DrawCallsMonitor（Draw Calls监控器）                      │
│  │   职责：监控Draw Calls、检测Draw Calls超标                    │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ LoadTimeMonitor（加载时间监控器）                           │
│      职责：监控场景加载时间、记录加载时间峰值                        │
├─────────────────────────────────────────────────────────────────┤
│  性能分析模块                                                  │
│  ├─ PerformanceAnalyzer（性能分析器）                           │
│  │   职责：分析性能数据、识别性能瓶颈、提供优化建议                   │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ PerformanceReporter（性能报告器）                           │
│      职责：生成性能报告、记录性能历史数据、导出性能数据               │
├─────────────────────────────────────────────────────────────────┤
│  自动优化模块                                                  │
│  ├─ AutoOptimizer（自动优化器）                                 │
│  │   职责：根据性能指标自动应用优化策略                             │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ OptimizationScheduler（优化调度器）                         │
│      职责：调度优化任务、管理优化级别、记录优化历史                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 5.1.3 性能指标定义

**PC端性能指标**：

| 性能指标 | 目标值 | 警告阈值 | 临界阈值 | 监控频率 |
|---------|-------|---------|---------|---------|
| **帧率（1080p）** | ≥60 FPS | <50 FPS | <30 FPS | 1秒 |
| **帧率（1440p）** | ≥60 FPS | <50 FPS | <30 FPS | 1秒 |
| **帧率（4K）** | ≥30 FPS | <20 FPS | <15 FPS | 1秒 |
| **内存占用（1080p）** | ≤500MB | >700MB | >900MB | 1秒 |
| **内存占用（1440p/4K）** | ≤800MB | >1.0GB | >1.2GB | 1秒 |
| **Draw Calls** | ≤500 | >600 | >800 | 1秒 |
| **加载时间（SSD）** | ≤2秒 | >3秒 | >5秒 | 事件触发 |
| **加载时间（HDD）** | ≤5秒 | >8秒 | >10秒 | 事件触发 |

#### 5.1.4 接口定义

**性能监控公开接口**：

```gdscript
## 性能监控公开接口定义

# 性能数据获取接口
## 返回值：性能数据字典（FPS、内存、Draw Calls等）
func get_performance_data() -> Dictionary

# 性能警告检查接口
## 返回值：是否有性能警告
func has_performance_warning() -> bool

# 自动优化应用接口
## 参数：
##   - level: 优化级别（0=无优化，1=轻度，2=深度）
func apply_optimization(level: int) -> void

# 性能报告生成接口
## 返回值：性能报告字符串
func generate_performance_report() -> String
```

**信号定义**：

```gdscript
## 性能监控信号定义

# 性能数据变化信号
## 参数：
##   - metric_name: 指标名称
##   - value: 当前值
signal performance_metric_changed(metric_name: String, value: float)

# 性能警告信号
## 参数：
##   - warning_type: 警告类型（"fps_low"/"memory_high"/"draw_calls_high"）
##   - message: 警告信息
signal performance_warning(warning_type: String, message: String)

# 自动优化触发信号
## 参数：
##   - level: 优化级别
signal auto_optimization_triggered(level: int)
```

### 5.2 优化策略设计

#### 5.2.1 优化策略分类

**优化策略分类表**：

| 优化策略 | 适用场景 | 优化效果 | 实施成本 | PC端优先级 |
|---------|---------|---------|---------|-----------|
| **对象池** | 频繁创建销毁的对象（卡牌、粒子） | 高 | 低 | 高 |
| **LOD（细节层次）** | 高分辨率显示 | 中 | 中 | 中 |
| **视口剔除** | 场景复杂度高 | 高 | 中 | 高 |
| **多线程加载** | 大资源加载 | 中 | 高 | 低 |
| **纹理压缩** | 内存占用高 | 中 | 低 | 中 |
| **批处理渲染** | Draw Calls高 | 中 | 中 | 中 |
| **Shader优化** | Shader性能差 | 低 | 高 | 低 |

#### 5.2.2 对象池优化

**对象池设计原则**：

```
对象池设计原则：

1. 预分配原则
   ├─ 游戏启动时预分配常用对象（卡牌、粒子）
   ├─ 预分配数量根据预估需求设置
   └─ 避免运行时频繁创建销毁

2. 动态扩展原则
   ├─ 对象池不足时动态扩展
   ├─ 扩展数量为当前数量的1.5倍
   └─ 避免对象池过大浪费内存

3. 对象回收原则
   ├─ 对象使用完后立即回收到对象池
   ├─ 重置对象状态（位置、缩放、可见性等）
   └─ 避免对象池溢出时直接销毁

4. 分级池化原则
   ├─ 按类型分池（风景卡池、地形卡池、粒子池等）
   ├─ 避免不同类型对象混用
   └─ 每个池独立管理大小和扩展
```

**对象池接口设计**：

```gdscript
## 对象池公开接口定义

# 对象获取接口
## 参数：
##   - pool_id: 对象池标识
## 返回值：对象节点
func get_object(pool_id: String) -> Node

# 对象回收接口
## 参数：
##   - pool_id: 对象池标识
##   - obj: 要回收的对象
func return_object(pool_id: String, obj: Node) -> void

# 对象池清空接口
## 参数：
##   - pool_id: 对象池标识
func clear_pool(pool_id: String) -> void
```

#### 5.2.3 LOD优化

**LOD（细节层次）设计**：

```
LOD设计方案：

1. 设备等级划分
   ├─ 低端设备（<4GB内存，1080p）：LOD Level 0
   ├─ 中端设备（4-8GB内存，1080p-1440p）：LOD Level 1
   ├─ 高端设备（>8GB内存，1440p-4K）：LOD Level 2
   └─ 超高端设备（>16GB内存，4K+144Hz）：LOD Level 3

2. 细节层次设置
   ├─ LOD Level 0（低画质）
   │   ├─ 纹理质量：低
   │   ├─ 阴影质量：关闭
   │   ├─ 粒子数量：50%减少
   │   └─ 后处理：关闭
   ├─ LOD Level 1（中画质）
   │   ├─ 纹理质量：中
   │   ├─ 阴影质量：低
   │   ├─ 粒子数量：正常
   │   └─ 后处理：基础
   ├─ LOD Level 2（高画质）
   │   ├─ 纹理质量：高
   │   ├─ 阴影质量：中
   │   ├─ 粒子数量：150%
   │   └─ 后处理：完整
   └─ LOD Level 3（超高画质）
       ├─ 纹理质量：超高
       ├─ 阴影质量：高
       ├─ 粒子数量：200%
       └─ 后处理：高级（光追、SSR等）

3. 动态LOD调整
   ├─ 根据当前性能指标动态调整LOD
   ├─ FPS < 50时：降低一级LOD
   ├─ FPS > 60且所有指标正常时：尝试提升一级LOD
   └─ 避免频繁切换LOD（设置切换冷却时间）
```

#### 5.2.4 视口剔除优化

**视口剔除设计**：

```
视口剔除设计方案：

1. 剔除原则
   ├─ 剔除视口外的不可见节点
   ├─ 设置剔除缓冲区（视口大小+20%）
   ├─ 剔除被遮挡的节点（背面剔除）
   └─ 剔除距离摄像机过远的节点（距离剔除）

2. 剔除实现
   ├─ 使用Camera2D的视口剔除
   ├─ 使用CanvasItem的visibility_rect
   ├─ 使用Node2D的distance检查
   └─ 使用Tween的动画优化（剔除静止节点）

3. 性能监控
   ├─ 监控剔除前后的Draw Calls
   ├─ 监控剔除前后的性能提升
   └─ 根据监控结果调整剔除策略
```

---

## 第六章：Steam平台集成

### 6.1 成就系统设计

#### 6.1.1 系统职责定义

**核心职责**：

- **成就管理**：管理成就的定义、状态、解锁条件
- **成就解锁**：检测成就触发条件、解锁成就
- **成就显示**：显示成就解锁通知（Steam原生通知）
- **成就统计**：统计成就解锁进度、计算成就完成率

**职责边界**：

- **不负责**：成就的具体内容（由策划负责）
- **不负责**：成就的平衡调整（由策划负责）
- **不负责**：成就的本地存储（由Steam负责）

#### 6.1.2 系统架构设计

```
Steam成就系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  SteamAchievementManager（Steam成就管理器）                     │
│  职责：协调成就管理、成就解锁、成就统计                           │
├─────────────────────────────────────────────────────────────────┤
│  成就管理模块                                                  │
│  ├─ AchievementRegistry（成就注册表）                           │
│  │   职责：管理成就定义、注册成就、查询成就状态                     │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ AchievementTrigger（成就触发器）                           │
│  │   职责：监听游戏事件、检测成就触发条件、触发成就解锁               │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ AchievementNotifier（成就通知器）                           │
│      职责：显示成就解锁通知、Steam原生通知、自定义通知                │
└─────────────────────────────────────────────────────────────────┘
```

#### 6.1.3 成就数据结构

**成就数据结构**：

```gdscript
## 成就数据结构
struct AchievementData:
    String id             # 成就唯一标识
    String name           # 成就名称
    String description    # 成就描述
    Texture2D icon       # 成就图标
    bool unlocked         # 是否已解锁
    float progress       # 成就进度（0.0-1.0）
    Dictionary triggers   # 成就触发条件
```

**成就触发条件示例**：

```
成就触发条件示例：

1. 首次攀登
   ├─ 触发条件：完成第1关
   ├─ 触发事件：level_completed(1)
   └─ 成就ID：first_climb

2. 风景大师
   ├─ 触发条件：收集10张风景照片卡
   ├─ 触发事件：card_collected_count("scenery") >= 10
   └─ 成就ID：scenery_master

3. 连击之神
   ├─ 触发条件：达到10连击
   ├─ 触发事件：combo_count >= 10
   └─ 成就ID：combo_master

4. 大湾区通
   ├─ 触发条件：通关所有10个关卡
   ├─ 触发事件：level_count >= 10
   └─ 成就ID：greater_bay_area_master
```

#### 6.1.4 接口定义

**成就系统公开接口**：

```gdscript
## 成就系统公开接口定义

# 成就解锁接口
## 参数：
##   - achievement_id: 成就标识
func unlock_achievement(achievement_id: String) -> void

# 成就进度更新接口
## 参数：
##   - achievement_id: 成就标识
##   - progress: 成就进度（0.0-1.0）
func update_achievement_progress(achievement_id: String, progress: float) -> void

# 成就状态获取接口
## 参数：
##   - achievement_id: 成就标识
## 返回值：是否已解锁
func is_achievement_unlocked(achievement_id: String) -> bool

# 成就进度获取接口
## 参数：
##   - achievement_id: 成就标识
## 返回值：成就进度（0.0-1.0）
func get_achievement_progress(achievement_id: String) -> float

# 全部成就数据获取接口
## 返回值：全部成就数据字典
func get_all_achievements() -> Dictionary
```

**信号定义**：

```gdscript
## 成就系统信号定义

# 成就解锁信号
## 参数：
##   - achievement_id: 成就标识
signal achievement_unlocked(achievement_id: String)

# 成就进度更新信号
## 参数：
##   - achievement_id: 成就标识
##   - progress: 成就进度
signal achievement_progress_updated(achievement_id: String, progress: float)

# 所有成就解锁信号
signal all_achievements_unlocked()
```

### 6.2 排行榜系统设计

#### 6.2.1 系统职责定义

**核心职责**：

- **排行榜管理**：管理排行榜的定义、分数上传、分数下载
- **分数上传**：上传玩家分数到Steam排行榜
- **分数下载**：下载Steam排行榜数据
- **排行榜显示**：显示排行榜（本地好友、全球、自定义范围）

**职责边界**：

- **不负责**：排行榜的具体内容（由策划负责）
- **不负责**：排行榜的平衡调整（由策划负责）
- **不负责**：排行榜的本地存储（由Steam负责）

#### 6.2.2 系统架构设计

```
Steam排行榜系统架构：

┌─────────────────────────────────────────────────────────────────┐
│  SteamLeaderboardManager（Steam排行榜管理器）                    │
│  职责：协调排行榜管理、分数上传、分数下载、排行榜显示                │
├─────────────────────────────────────────────────────────────────┤
│  排行榜管理模块                                                │
│  ├─ LeaderboardRegistry（排行榜注册表）                        │
│  │   职责：管理排行榜定义、注册排行榜、查询排行榜状态                │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ ScoreUploader（分数上传器）                                │
│  │   职责：上传玩家分数到Steam排行榜、处理上传失败、重试上传        │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ ScoreDownloader（分数下载器）                             │
│  │   职责：下载Steam排行榜数据、缓存排行榜数据、更新排行榜显示       │
│  └────────────────────────────────────────────────────────────────┤
└─ LeaderboardDisplay（排行榜显示器）                           │
      职责：显示排行榜UI、排行榜数据格式化、排行榜排序                  │
```

#### 6.2.3 排行榜数据结构

**排行榜数据结构**：

```gdscript
## 排行榜数据结构
struct LeaderboardData:
    String leaderboard_id   # 排行榜唯一标识
    String name           # 排行榜名称
    String display_type   # 显示类型（"numeric"/"time"/"score"）
    int sort_method       # 排序方式（0=升序，1=降序）
    int max_entries       # 最大条目数
```

**排行榜条目数据结构**：

```gdscript
## 排行榜条目数据结构
struct LeaderboardEntry:
    int rank            # 排名
    String player_name  # 玩家名称
    int score           # 分数
    int user_id         # Steam用户ID
    String data         # 自定义数据
```

#### 6.2.4 接口定义

**排行榜系统公开接口**：

```gdscript
## 排行榜系统公开接口定义

# 分数上传接口
## 参数：
##   - leaderboard_id: 排行榜标识
##   - score: 分数
## 返回值：是否上传成功
func upload_score(leaderboard_id: String, score: int) -> bool

# 排行榜下载接口
## 参数：
##   - leaderboard_id: 排行榜标识
##   - range_start: 起始排名
##   - range_end: 结束排名
## 返回值：排行榜条目数组
func download_leaderboard(leaderboard_id: String, range_start: int, range_end: int) -> Array

# 玩家排名获取接口
## 参数：
##   - leaderboard_id: 排行榜标识
## 返回值：玩家排名（-1表示未上榜）
func get_player_rank(leaderboard_id: String) -> int
```

**信号定义**：

```gdscript
## 排行榜系统信号定义

# 分数上传完成信号
## 参数：
##   - leaderboard_id: 排行榜标识
##   - score: 分数
##   - success: 是否成功
signal score_uploaded(leaderboard_id: String, score: int, success: bool)

# 排行榜数据更新信号
## 参数：
##   - leaderboard_id: 排行榜标识
##   - entries: 排行榜条目数组
signal leaderboard_updated(leaderboard_id: String, entries: Array)
```

---

## 第七章：工具链架构

### 7.1 godot_parser集成

#### 7.1.1 工具链架构设计

```
godot_parser工具链架构：

┌─────────────────────────────────────────────────────────────────┐
│  Python工具脚本层                                               │
│  ├─ scene_builder.py（场景构建工具）                           │
│  │   职责：程序化生成战斗场景、UI场景、PC端高分辨率支持            │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ card_generator.py（卡牌生成工具）                           │
│  │   职责：程序化生成卡牌数据JSON、批量管理卡牌数据                │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ localization_parser.py（本地化提取工具）                     │
│  │   职责：从GDScript文件中提取可翻译字符串、生成POT文件          │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ steam_config_generator.py（Steam配置生成工具）               │
│  │   职责：生成Steam成就配置、Steam排行榜配置                      │
│  └────────────────────────────────────────────────────────────────┤
│  └─ pc_resource_optimizer.py（PC端资源优化工具）                  │
│      职责：优化PC端资源、压缩纹理、生成高分辨率资源                  │
├─────────────────────────────────────────────────────────────────┤
│  godot_parser核心层                                            │
│  ├─ GDScene（场景类）                                          │
│  │   职责：解析和生成Godot场景文件（.tscn）                        │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ GDResource（资源类）                                        │
│  │   职责：解析和生成Godot资源文件（.tres）                        │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ Node（节点类）                                              │
│  │   职责：表示Godot场景树中的节点                              │
│  └────────────────────────────────────────────────────────────────┤
│  └─ ExtResource（外部资源类）                                 │
│      职责：表示Godot场景中的外部资源引用                          │
└─────────────────────────────────────────────────────────────────┘
```

#### 7.1.2 工具链使用流程

```
godot_parser工具链使用流程：

1. 场景生成流程
   ├─ 步骤1：编写JSON配置文件
   ├─ 步骤2：调用scene_builder.py生成场景文件
   ├─ 步骤3：在Godot编辑器中验证场景文件
   ├─ 步骤4：提交场景文件到版本控制
   └─ 步骤5：CI/CD流水线自动生成不同分辨率场景

2. 卡牌数据生成流程
   ├─ 步骤1：编写卡牌配置JSON模板
   ├─ 步骤2：调用card_generator.py生成卡牌数据
   ├─ 步骤3：验证卡牌数据格式和内容
   ├─ 步骤4：提交卡牌数据到版本控制
   └─ 步骤5：CI/CD流水线自动更新卡牌数据

3. 本地化提取流程
   ├─ 步骤1：在GDScript中使用tr()函数包装文本
   ├─ 步骤2：调用localization_parser.py提取文本
   ├─ 步骤3：生成POT（Portable Object Template）文件
   ├─ 步骤4：翻译人员使用翻译工具（Poedit、Crowdin）
   ├─ 步骤5：生成最终翻译文件（PO、MO）
   └─ 步骤6：提交翻译文件到版本控制

4. Steam配置生成流程
   ├─ 步骤1：编写成就配置JSON
   ├─ 步骤2：调用steam_config_generator.py生成Steam配置
   ├─ 步骤3：在Steamworks后台上传配置
   ├─ 步骤4：验证成就和排行榜配置
   └─ 步骤5：提交Steam配置到版本控制
```

#### 7.1.3 工具链开发规范

**Python脚本开发规范**：

```python
## Python脚本开发规范

# 1. 文件头注释
"""
## 文件名称：scene_builder.py
## 职责描述：程序化生成Godot场景文件，支持PC端高分辨率
## 作者：开发团队
## 创建日期：2026-01-28
## 最后修改：2026-01-28
"""

# 2. 函数注释
def create_battle_scene(output_path: str, level_data: dict, resolution: str = "1920x1080") -> None:
    """
    创建战斗场景（PC端版本）
    
    Args:
        output_path: 输出文件路径
        level_data: 关卡数据字典
        resolution: PC端分辨率（1920x1080/2560x1440/3840x2160）
    
    Returns:
        None
    """

# 3. 类注释
class BattleSceneBuilder:
    """战斗场景构建器"""
    
    def __init__(self):
        """初始化战斗场景构建器"""
        pass
```

**godot_parser使用规范**：

```python
## godot_parser使用规范

# 1. 导入godot_parser模块
from godot_parser import GDScene, Node, ExtResource

# 2. 创建场景
scene = GDScene()

# 3. 使用with语句管理场景树（推荐）
with scene.use_tree() as tree:
    # 设置根节点
    tree.root = Node("BattleScene", type="Node2D")
    
    # 添加子节点
    background = Node("Background", type="TextureRect")
    tree.root.add_child(background)

# 4. 写入场景文件
scene.write(output_path)

# 5. 不推荐方式（不使用with语句）
# scene.tree.root = Node("BattleScene", type="Node2D")
# scene.tree.root.add_child(background)
# scene.write(output_path)
```

### 7.2 自动化构建流程

#### 7.2.1 CI/CD流水线设计

```
CI/CD流水线架构：

┌─────────────────────────────────────────────────────────────────┐
│  持续集成（Continuous Integration）                            │
│  ├─ 代码提交（Push）                                           │
│  │   ├─ 开发人员提交代码到Git仓库                              │
│  │   ├─ 触发GitHub Actions流水线                              │
│  │   └─ 执行代码检查和自动化测试                                 │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ 代码检查（Lint）                                           │
│  │   ├─ GDScript代码格式检查（使用gdformat）                   │
│  │   ├─ Python代码格式检查（使用black）                        │
│  │   ├─ 代码风格检查（使用pylint）                            │
│  │   └─ 代码复杂度检查（使用radon）                           │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ 单元测试（Unit Test）                                      │
│  │   ├─ GDScript单元测试（使用GUT）                          │
│  │   ├─ Python单元测试（使用pytest）                          │
│  │   └─ 测试覆盖率检查（目标≥80%）                             │
│  └────────────────────────────────────────────────────────────────┤
└─ 构建验证（Build Verification）                                 │
      ├─ Godot项目构建验证                                       │
      ├─ 场景文件加载验证                                         │
      ├─ 资源文件完整性验证                                       │
      └─ 生成构建报告                                             │
├─────────────────────────────────────────────────────────────────┤
│  持续交付（Continuous Delivery）                                │
│  ├─ 场景生成自动化                                             │
│  │   ├─ 调用scene_builder.py生成所有场景文件                     │
│  │   ├─ 生成不同分辨率场景（1080p/1440p/4K）                   │
│  │   └─ 验证场景文件正确性                                     │
│  ├────────────────────────────────────────────────────────────────┤
│  ├─ 卡牌数据生成自动化                                         │
│  │   ├─ 调用card_generator.py生成所有卡牌数据                     │
│  │   ├─ 验证卡牌数据格式和内容                                   │
│  │   └─ 提交卡牌数据到版本控制                                   │
│  ├────────────────────────────────────────────────────────────────┤
│  └─ 打包发布自动化                                             │
│      ├─ Godot项目导出                                           │
│      ├─ 生成Steam发布版本                                        │
│      ├─ 自动化测试发布版本                                       │
│      └─ 上传到Steam                                             │
└─────────────────────────────────────────────────────────────────┘
```

#### 7.2.2 构建脚本设计

**主构建脚本（build.sh）**：

```bash
## 主构建脚本（build.sh）

#!/bin/bash

## 构建步骤
## 1. 检查环境
echo "检查环境..."
python3 --version || { echo "Python3未安装"; exit 1; }
godot --version || { echo "Godot未安装"; exit 1; }

## 2. 生成场景文件
echo "生成场景文件..."
python3 tools/scene_builder.py battle_scene res://scenes/battle/battle_scene_1080p.tscn 1920x1080
python3 tools/scene_builder.py battle_scene res://scenes/battle/battle_scene_1440p.tscn 2560x1440
python3 tools/scene_builder.py battle_scene res://scenes/battle/battle_scene_4k.tscn 3840x2160

## 3. 生成卡牌数据
echo "生成卡牌数据..."
python3 tools/card_generator.py res://assets/data/cards/ 10

## 4. 验证文件
echo "验证文件..."
python3 tools/validate_scene.py res://scenes/battle/*.tscn
python3 tools/validate_cards.py res://assets/data/cards/*.json

## 5. Godot构建
echo "Godot构建..."
godot --headless --export "Steam Windows" "build/steam/greater_bay_area_hiking.exe"

## 6. 测试构建
echo "测试构建..."
./build/steam/greater_bay_area_hiking.exe --test

## 7. 完成
echo "构建完成！"
```

---

## 第八章：开发规范

### 8.1 代码规范

#### 8.1.1 GDScript代码规范

**代码风格规范**：

```gdscript
## GDScript代码风格规范

# 1. 缩进
## 使用4个空格缩进，不使用Tab
func my_function():
    var my_variable = 0
    if my_variable > 0:
        print("Positive")

# 2. 行长度
## 单行最大长度120字符
## 超过120字符时换行，保持逻辑完整
var very_long_variable_name = some_function_with_many_parameters(
    param1, param2, param3
)

# 3. 空行
## 函数之间使用1个空行
## 逻辑块之间使用1个空行
## 类定义之后使用1个空行
func function1():
    pass

func function2():
    pass

# 4. 类型注解
## 所有函数参数和返回值必须使用类型注解
func my_function(param1: int, param2: String) -> bool:
    return param1 > 0
```

**类型使用规范**：

```gdscript
## GDScript类型使用规范

# 1. 基本类型
## 使用int、float、String、bool等基本类型
var my_int: int = 0
var my_float: float = 0.0
var my_string: String = ""
var my_bool: bool = false

# 2. 数组类型
## 使用Array[]、Dictionary等容器类型
var my_array: Array[int] = []
var my_dict: Dictionary = {}

# 3. 自定义类型
## 使用class_name定义自定义类型
extends Node
class_name MyCustomNode

# 4. 可空类型
## 使用?标记可空类型
var my_nullable: String? = null
```

#### 8.1.2 错误处理规范

**错误处理原则**：

```
错误处理原则：

1. 错误检测
   ├─ 输入验证：验证函数参数的有效性
   ├─ 状态检查：检查对象状态是否有效
   ├─ 边界检查：检查数值是否在有效范围内
   └─ 资源检查：检查资源是否存在、是否有效

2. 错误处理
   ├─ 返回错误：函数返回错误码或null
   ├─ 抛出错误：使用assert抛出错误（仅调试模式）
   ├─ 记录错误：使用print_err记录错误信息
   └─ 发射错误信号：通过信号通知上层

3. 错误恢复
   ├─ 自动恢复：尝试自动修复错误
   ├─ 降级运行：降低功能等级继续运行
   ├─ 安全退出：无法恢复时安全退出
   └─ 错误上报：将错误信息上报到错误收集系统
```

**错误处理示例**：

```gdscript
## 错误处理示例

# 1. 输入验证
func save_game(slot: int) -> bool:
    if slot < 0 or slot >= MAX_SLOTS:
        print_err("Invalid save slot: %d" % slot)
        return false
    
    # 继续处理
    return true

# 2. 状态检查
func consume_stamina(amount: float) -> bool:
    if not is_initialized:
        print_err("AttributeSystem not initialized")
        return false
    
    # 继续处理
    stamina -= amount
    return true

# 3. 边界检查
func modify_attribute(attribute: String, amount: float) -> void:
    if not attribute in ATTRIBUTES:
        print_err("Unknown attribute: %s" % attribute)
        return
    
    var current_value = attributes[attribute]
    var min_value = ATTRIBUTES[attribute].min_value
    var max_value = ATTRIBUTES[attribute].max_value
    
    if current_value + amount < min_value:
        print_err("Attribute would exceed minimum value")
        return
    
    if current_value + amount > max_value:
        print_err("Attribute would exceed maximum value")
        return
    
    # 继续处理
    attributes[attribute] += amount

# 4. 资源检查
func load_resource(resource_path: String) -> Resource:
    if not ResourceLoader.exists(resource_path):
        print_err("Resource not found: %s" % resource_path)
        return null
    
    var resource = ResourceLoader.load(resource_path)
    if resource == null:
        print_err("Failed to load resource: %s" % resource_path)
        return null
    
    return resource

# 5. 错误信号发射
func load_game(slot: int) -> bool:
    var save_data = _load_save_data(slot)
    if save_data == null:
        error_signal.emit("Failed to load save data for slot %d" % slot)
        return false
    
    # 继续处理
    return true
```

### 8.2 工作流程规范

#### 8.2.1 开发工作流程

```
开发工作流程：

1. 需求分析
   ├─ 理解需求文档（PRD、设计文档）
   ├─ 技术可行性分析
   ├─ 工作量评估
   └─ 制定开发计划

2. 技术设计
   ├─ 编写技术设计文档
   ├─ 设计接口定义
   ├─ 设计数据结构
   └─ 设计算法流程

3. 编码实现
   ├─ 创建脚本文件
   ├─ 编写代码（遵循代码规范）
   ├─ 编写单元测试
   └─ 代码审查（Code Review）

4. 测试验证
   ├─ 运行单元测试
   ├─ 运行集成测试
   ├─ 手动测试
   └─ Bug修复

5. 提交代码
   ├─ Git提交代码
   ├─ 编写提交信息
   ├─ 触发CI/CD流水线
   └─ 通过自动化测试

6. 部署上线
   ├─ 构建发布版本
   ├─ 测试发布版本
   ├─ 提交到Steam
   └─ 上线发布
```

#### 8.2.2 Git提交规范

**提交信息格式**：

```
Git提交信息格式：

<type>(<scope>): <subject>

<body>

<footer>

# 示例

feat(card_system): 添加卡牌生成功能

- 添加CardGenerator类
- 实现generate_level()方法
- 添加单元测试

Closes #123
```

**提交类型（type）**：

| 类型 | 说明 |
|------|------|
| **feat** | 新功能 |
| **fix** | Bug修复 |
| **docs** | 文档更新 |
| **style** | 代码格式调整（不影响逻辑） |
| **refactor** | 代码重构（不影响功能） |
| **perf** | 性能优化 |
| **test** | 测试相关 |
| **chore** | 构建/工具链相关 |

**提交范围（scope）**：

| 范围 | 说明 |
|------|------|
| **card_system** | 卡牌系统 |
| **attribute_system** | 属性系统 |
| **economy_system** | 经济系统 |
| **ui** | UI/UX |
| **steam** | Steam集成 |
| **tools** | 工具链 |
| **performance** | 性能优化 |
| **bug** | Bug修复 |

---

## 附录A：快速参考

### A.1 常用节点类型

| 节点类型 | 说明 | 使用场景 |
|---------|------|---------|
| **Node** | 基础节点，不提供任何功能 | 作为场景根节点、容器节点 |
| **Node2D** | 2D节点，提供2D位置和变换 | 卡牌层、特效层、背景层 |
| **Control** | UI控件节点，提供UI交互功能 | 所有UI场景、UI面板 |
| **Label** | 文本标签节点 | 文本显示、标题、按钮文本 |
| **Button** | 按钮节点 | 所有可点击的UI元素 |
| **ProgressBar** | 进度条节点 | 属性条、加载进度条 |
| **TextureRect** | 纹理矩形节点 | 图片显示、背景、卡牌图片 |
| **Panel** | 面板节点 | 容器、背景面板 |
| **VBoxContainer** | 垂直布局容器 | 垂直排列的UI元素 |
| **HBoxContainer** | 水平布局容器 | 水平排列的UI元素 |
| **PanelContainer** | 面板容器（带背景） | 带背景的面板 |

### A.2 常用信号

| 信号 | 说明 | 发射时机 |
|------|------|---------|
| **ready()** | 节点准备就绪 | 节点添加到场景树时 |
| **tree_entered()** | 进入场景树 | 节点添加到场景树后 |
| **tree_exited()** | 退出场景树 | 节点从场景树移除前 |
| **process(delta)** | 每帧处理 | 每一帧都会调用 |
| **physics_process(delta)** | 物理处理 | 每一帧都会调用（物理步长） |
| **input(event)** | 输入处理 | 接收输入事件 |
| **mouse_entered()** | 鼠标进入 | 鼠标进入节点区域 |
| **mouse_exited()** | 鼠标离开 | 鼠标离开节点区域 |
| **resized()** | 尺寸变化 | 节点尺寸变化时 |

### A.3 常用方法

| 方法 | 说明 | 使用场景 |
|------|------|---------|
| **queue_free()** | 将节点加入空闲队列，在当前帧结束后销毁 | 删除节点时 |
| **add_child(node)** | 添加子节点 | 添加子节点到当前节点 |
| **remove_child(node)** | 移除子节点 | 从当前节点移除子节点 |
| **get_node(path)** | 获取节点 | 根据节点路径获取子节点 |
| **connect(signal, callback)** | 连接信号 | 连接信号到回调函数 |
| **emit_signal(signal, args)** | 发射信号 | 发射信号，传递参数 |
| **create_tween()** | 创建补间动画 | 创建Tween动画对象 |
| **get_tree()** | 获取场景树 | 获取当前场景树 |
| **get_viewport()** | 获取视口 | 获取当前视口 |

---

## 附录B：术语表

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

---

**文档结束**

《大湾区徒步》Godot游戏开发技术架构文档完成，为流动性强的初级开发工程师提供了标准化的技术架构参考，确保开发团队能够快速上手并保持代码质量一致性。

**文档编制**：Godot架构及技术专家团队  
**文档日期**：2026年01月28日  
**文档版本**：v1.0
