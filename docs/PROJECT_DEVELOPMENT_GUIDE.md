# 《大湾区徒步》项目开发指导规范

**文档类型**：项目开发规范  
**文档版本**：v1.0  
**创建日期**：2026年1月29日  
**维护团队**：Godot开发团队  
**适用范围**：所有开发团队成员

---

## 文档说明

本文档是《大湾区徒步》Godot项目的**核心开发规范文档**，基于Specification-Driven Development（规范驱动开发）方法论制定。所有开发任务必须严格遵循本规范执行，确保代码质量一致性、开发效率最大化、团队协作顺畅。

**规范驱动开发原则**：
- **先定义后实现**：所有功能开发前必须先明确规范
- **规范优先**：遇到冲突时，以规范为准，可讨论修改规范但不得随意违反
- **全员遵守**：所有团队成员必须严格遵守，无例外
- **持续优化**：规范是动态文档，可根据实践反馈持续优化

---

## 第一章：项目概述

### 1.1 项目基本信息

| 项目名称 | 大湾区徒步 |
|---------|-----------|
| 游戏类型 | 2D卡牌 Roguelike 策略休闲游戏 |
| 开发引擎 | Godot Engine 4.5.1 |
| 目标平台 | Steam (PC/Windows) |
| 主要语言 | GDScript (主语言)、C# (性能关键模块)、C++ (GDExtension) |
| 团队特点 | 初级开发工程师为主，人员流动性高 |
| 开发周期 | 待定 |

### 1.2 核心玩法概述

以大湾区地理文化为背景的登山式消除卡牌游戏：
- **核心机制**：穿越式消除 + 分级翻越系统 + 连击体系
- **卡牌体系**：风景卡、地形障碍卡、资源卡、环境卡、照片卡
- **属性系统**：体能、背包容量、耐力、速度、心率（五维属性）
- **经济系统**：徒步数、海拔数、环保值
- **文化元素**：大湾区地标、岭南文化、环保教育

### 1.3 架构设计原则

**分层架构**：表现层 - 逻辑层 - 数据层  
**模块化设计**：低耦合高内聚，支持并行开发  
**数据驱动**：游戏数据配置化管理，支持热更新  
**性能优先**：PC端优化，高分辨率高刷新率稳定运行  
**标准化**：统一命名、代码风格、接口定义

---

## 第二章：编码规范

### 2.1 文件命名规范

#### 2.1.1 场景文件命名

```
规范：[模块名]_[功能名].tscn
示例：
- Main_Menu.tscn (主菜单)
- Battle_Scene.tscn (战斗场景)
- Card_Editor.tscn (卡牌编辑器)
```

#### 2.1.2 脚本文件命名

```
规范：[模块名][功能名].gd (GDScript)
     [模块名][功能名].cs (C#)
示例：
- GameManager.gd (游戏管理器)
- CardController.gd (卡牌控制器)
- UIManager.cs (UI管理器C#版本)
```

#### 2.1.3 资源文件命名

```
规范：[类型]_[名称]_[序号].扩展名

类型前缀：
- tex_ (纹理贴图)
- snd_ (音频资源)
- spr_ (精灵帧)
- font_ (字体)
- mat_ (材质)
- cfg_ (配置文件)
- anim_ (动画资源)

示例：
- tex_background_01.png
- snd_click_01.wav
- spr_card_icon_01.png
- font_normal.tres
- cfg_card_database.json
```

#### 2.1.4 AutoLoad单例命名

```
规范：[模块名]Manager (全局管理器)
     [模块名]System (核心系统)
示例：
- GameManager (游戏管理器)
- AudioManager (音频管理器)
- CardSystem (卡牌系统)
- SaveManager (存档管理器)
```

### 2.2 代码结构规范

#### 2.2.1 脚本头部注释模板

```gdscript
# ============================================================
# 脚本名称：CardController
# 功能描述：卡牌控制器，负责卡牌的生成、交互、消除逻辑
# 作者：[作者名]
# 创建日期：2026-01-29
# 最后修改：2026-01-29
# 依赖项：CardData, CardSystem, ComboSystem
# ============================================================
extends Node2D

class_name CardController
```

#### 2.2.2 类定义规范

```gdscript
# 1. 使用 class_name 定义类名
class_name CardController

# 2. 使用 extends 继承合适的基类
extends Node2D

# 3. 定义导出变量（Inspector可编辑）
@export var card_id: int = 0
@export var card_type: String = ""

# 4. 定义私有变量（使用下划线前缀）
var _card_data: CardData = null
var _is_hovered: bool = false

# 5. 定义信号
signal card_selected(card_id: int)
signal card_activated(card_id: int)
```

#### 2.2.3 函数定义规范

```gdscript
# 1. 公有函数：使用 snake_case 命名
func select_card(card_id: int) -> void:
    """选择卡牌
    
    Args:
        card_id: 卡牌ID
    """
    if _card_data and _card_data.id == card_id:
        _card_data.is_selected = true
        emit_signal("card_selected", card_id)

# 2. 私有函数：使用 _snake_case 命名
func _update_card_visual() -> void:
    """更新卡牌视觉效果（私有方法）"""
    pass

# 3. 虚函数：重写基类方法
func _ready() -> void:
    """节点准备好时调用"""
    super._ready()
    _initialize_card()

func _process(delta: float) -> void:
    """每帧处理"""
    pass
```

#### 2.2.4 信号连接规范

```gdscript
# 方式1：使用 connect 方法（推荐）
func _ready() -> void:
    card_button.pressed.connect(_on_card_button_pressed)

# 方式2：在编辑器中连接（简单场景）

# 回调函数命名规范：_on_[节点名]_[信号名]
func _on_card_button_pressed() -> void:
    """卡牌按钮被按下时调用"""
    emit_signal("card_selected", card_id)
```

### 2.3 变量命名规范

#### 2.3.1 变量命名规则

```gdscript
# 1. 布尔值：使用 is_ 前缀
var is_active: bool = false
var is_hovered: bool = true

# 2. 集合：使用复数形式
var cards: Array[CardData] = []
var enemies: Dictionary = {}

# 3. 常量：使用全大写 + 下划线
const MAX_CARD_COUNT: int = 10
const BASE_ENERGY: int = 100

# 4. 枚举：使用 PascalCase
enum CardType { SCENERY, TERRAIN, RESOURCE, ENVIRONMENT, PHOTO }
enum GameState { MENU, BATTLE, PAUSE, GAME_OVER }

# 5. 私有变量：使用 _ 前缀
var _internal_state: int = 0
```

#### 2.3.2 类型注解规范

```gdscript
# GDScript 4.x 支持类型注解，必须使用

# 基本类型
var health: int = 100
var name: String = "Player"
var speed: float = 1.5

# 集合类型
var cards: Array[CardData] = []
var card_map: Dictionary[String, CardData] = {}

# 可选类型
var current_card: CardData = null

# 数组类型
var positions: Array[Vector2] = [Vector2.ZERO, Vector2(100, 100)]
```

### 2.4 注释规范

#### 2.4.1 文件注释

```gdscript
# ============================================================
# 文件说明：CardController.gd
# 模块：卡牌系统
# 功能：控制单张卡牌的交互、动画、状态管理
# 作者：开发团队
# 创建日期：2026-01-29
# 依赖：
#   - CardData (数据类)
#   - CardSystem (系统级单例)
#   - ComboSystem (连击系统)
# ============================================================
```

#### 2.4.2 函数注释

```gdscript
func create_card(type: String, tier: int) -> CardData:
    """创建新卡牌
    
    根据指定类型和等级生成卡牌数据，包含基础属性和特殊效果
    
    Args:
        type: 卡牌类型（"scenery", "terrain", "resource", "environment", "photo"）
        tier: 卡牌等级（1-5）
    
    Returns:
        CardData: 生成的卡牌数据对象
    
    Raises:
        ValueError: 当类型或等级无效时抛出
    
    Example:
        >>> var card = create_card("scenery", 3)
        >>> print(card.name)
        "维多利亚港"
    """
    if type not in CardType:
        raise ValueError("Invalid card type: %s" % type)
    if tier < 1 or tier > 5:
        raise ValueError("Invalid tier: %d (must be 1-5)" % tier)
    
    # 实现逻辑...
    pass
```

#### 2.4.3 行内注释

```gdscript
# 单行注释：简洁描述代码意图
var energy = 100  # 玩家初始能量

# 复杂逻辑必须添加注释
if _current_layer_index >= _max_layers:
    # 已到达山顶，触发胜利逻辑
    _trigger_victory()
    _save_game_data()
    return

# TODO: 待优化项
# FIXME: 临时修复
# HACK: 快速方案，需要重构
# NOTE: 重要提示
```

### 2.5 代码格式规范

#### 2.5.1 缩进与空格

```gdscript
# 使用 Tab 缩进（4空格宽度）
# 不使用空格缩进

# 运算符两侧添加空格
var result = a + b * c

# 逗号后添加空格
func add(a: int, b: int) -> int:
    return a + b

# 不在行尾添加多余空格
var x = 0  # 正确
var y = 0   # 错误（行尾多余空格）
```

#### 2.5.2 行长度

```gdscript
# 单行代码不超过 120 字符
# 超过则换行，使用缩进对齐

# 正确示例
func complex_function(param1: int, param2: String, 
                     param3: float, param4: bool) -> void:
    pass

# 错误示例（单行过长）
func complex_function(param1: int, param2: String, param3: float, param4: bool) -> void:
    pass
```

#### 2.5.3 空行使用

```gdscript
# 函数之间空一行
func function1():
    pass

func function2():
    pass

# 逻辑块之间空一行
# 1. 初始化
var energy = 100

# 2. 计算消耗
var cost = 10

# 3. 扣除能量
energy -= cost
```

### 2.6 错误处理规范

#### 2.6.1 异常处理

```gdscript
# 1. 使用 assert 进行前置条件检查
func process_card(card_id: int) -> void:
    assert(card_id >= 0, "card_id must be non-negative")
    assert(_card_map.has(card_id), "Card %d not found" % card_id)
    
    var card = _card_map[card_id]
    _apply_card_effect(card)

# 2. 使用 try-catch 处理外部依赖
func load_config(config_path: String) -> Dictionary:
    var config = {}
    var file = FileAccess.open(config_path, FileAccess.READ)
    
    if file == null:
        push_error("Failed to open config file: %s" % config_path)
        return config
    
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var error = json.parse(json_string)
    
    if error != OK:
        push_error("JSON parse error: %s" % json.get_error_message())
        return config
    
    return json.data

# 3. 使用 guard clause 避免深层嵌套
func process_player_action(action: Dictionary) -> void:
    if not action.has("type"):
        push_error("Action missing 'type' field")
        return
    
    if not action.has("data"):
        push_error("Action missing 'data' field")
        return
    
    var action_type = action["type"]
    _execute_action(action_type, action["data"])
```

#### 2.6.2 日志规范

```gdscript
# 1. 使用 print 输出调试信息
print("Player position: ", player_position)

# 2. 使用 push_warning 输出警告
if energy < 20:
    push_warning("Low energy: %d" % energy)

# 3. 使用 push_error 输出错误
if card_id < 0:
    push_error("Invalid card ID: %d" % card_id)

# 4. 结构化日志输出
print_debug("[CardSystem] Created card: type=%s, tier=%d, id=%d" % [card_type, tier, card_id])
```

### 2.7 日志文件生成规范

#### 2.7.1 日志文件目录结构

```
res://logs/
├── game/              # 游戏运行日志
│   ├── main.log       # 主流程日志
│   ├── debug.log      # 调试日志
│   └── error.log      # 错误日志
├── session/           # 会话日志（每次启动一个文件）
│   └── session_YYYYMMDD_HHMMSS.log
└── archive/           # 归档日志
    └── YYYY/
        └── MM/
```

#### 2.7.2 日志文件命名规范

```
格式：[类型]_[日期]_[时间].log 或 [类型].log

类型：
- main: 主日志，记录关键流程
- debug: 调试日志，记录详细调试信息
- error: 错误日志，仅记录错误和异常
- session: 会话日志，记录单次运行所有日志
- performance: 性能日志，记录FPS、内存等

示例：
- main.log (主日志，覆盖写入)
- error.log (错误日志，追加写入)
- session_20260129_143025.log (会话日志)
- performance_20260129.log (性能日志)
```

#### 2.7.3 日志内容规范

```gdscript
# 日志管理器实现
class_name Logger
extends Node

enum LogLevel { DEBUG, INFO, WARNING, ERROR, CRITICAL }
enum LogType { MAIN, DEBUG, ERROR, SESSION, PERFORMANCE }

var _log_files: Dictionary = {}
var _session_start_time: String = ""

func _ready() -> void:
    """初始化日志系统"""
    _session_start_time = Time.get_datetime_string_from_system().replace(" ", "_").replace(":", "")
    _init_log_files()
    _write_session_start()

func _init_log_files() -> void:
    """初始化日志文件"""
    var log_dir = "res://logs/"
    if not DirAccess.dir_exists_absolute(log_dir):
        DirAccess.make_dir_absolute(log_dir)
    
    # 创建子目录
    for sub_dir in ["game", "session", "archive"]:
        var dir_path = log_dir + sub_dir + "/"
        if not DirAccess.dir_exists_absolute(dir_path):
            DirAccess.make_dir_absolute(dir_path)
    
    # 初始化日志文件句柄
    _log_files[LogType.MAIN] = FileAccess.open(log_dir + "game/main.log", FileAccess.WRITE)
    _log_files[LogType.DEBUG] = FileAccess.open(log_dir + "game/debug.log", FileAccess.WRITE)
    _log_files[LogType.ERROR] = FileAccess.open(log_dir + "game/error.log", FileAccess.WRITE)
    _log_files[LogType.SESSION] = FileAccess.open(log_dir + "session/session_%s.log" % _session_start_time, FileAccess.WRITE)

func log(level: LogLevel, type: LogType, message: String, context: Dictionary = {}) -> void:
    """记录日志
    
    Args:
        level: 日志级别（DEBUG, INFO, WARNING, ERROR, CRITICAL）
        type: 日志类型（MAIN, DEBUG, ERROR, SESSION, PERFORMANCE）
        message: 日志消息
        context: 上下文数据（可选）
    """
    var timestamp = Time.get_datetime_string_from_system()
    var level_str = LogLevel.keys()[level]
    var log_line = "[%s] [%s] %s" % [timestamp, level_str, message]
    
    # 添加上下文信息
    if not context.is_empty():
        log_line += " | Context: " + str(context)
    
    # 写入对应的日志文件
    if _log_files.has(type) and _log_files[type] != null:
        _log_files[type].store_line(log_line)
    
    # 如果是ERROR或CRITICAL，同时写入error.log
    if level >= LogLevel.ERROR:
        if _log_files.has(LogType.ERROR) and _log_files[LogType.ERROR] != null:
            _log_files[LogType.ERROR].store_line(log_line)
    
    # 所有日志都写入session.log
    if _log_files.has(LogType.SESSION) and _log_files[LogType.SESSION] != null:
        _log_files[LogType.SESSION].store_line(log_line)
    
    # 控制台输出
    match level:
        LogLevel.DEBUG, LogLevel.INFO:
            print(log_line)
        LogLevel.WARNING:
            push_warning(log_line)
        LogLevel.ERROR, LogLevel.CRITICAL:
            push_error(log_line)

func _write_session_start() -> void:
    """写入会话开始信息"""
    var session_info = {
        "session_id": _session_start_time,
        "start_time": Time.get_datetime_string_from_system(),
        "godot_version": Engine.get_version_info(),
        "system_info": OS.get_name(),
        "user_locale": OS.get_locale_language()
    }
    
    log(LogLevel.INFO, LogType.SESSION, "Session started", session_info)

func close_logs() -> void:
    """关闭所有日志文件"""
    log(LogLevel.INFO, LogType.SESSION, "Session ended", {
        "end_time": Time.get_datetime_string_from_system()
    })
    
    for log_file in _log_files.values():
        if log_file != null:
            log_file.close()
```

#### 2.7.4 日志记录最佳实践

```gdscript
# 1. 使用Logger单例记录日志
extends Node

func _ready() -> void:
    # 从GameManager获取Logger实例
    var logger = GameManager.logger
    
    # 记录关键流程
    logger.log(Logger.LogLevel.INFO, Logger.LogType.MAIN, "Game started")
    
    # 记录调试信息
    logger.log(Logger.LogLevel.DEBUG, Logger.LogType.DEBUG, "Card created", {
        "card_id": 1001,
        "card_type": "scenery"
    })
    
    # 记录错误
    logger.log(Logger.LogLevel.ERROR, Logger.LogType.ERROR, "Failed to load card", {
        "card_id": 9999,
        "error": "Card not found in database"
    })

# 2. 使用结构化日志
func process_card(card_id: int) -> void:
    var logger = GameManager.logger
    
    # 记录处理开始
    logger.log(Logger.LogLevel.DEBUG, Logger.LogType.DEBUG, "Processing card", {
        "card_id": card_id,
        "timestamp": Time.get_unix_time_from_system()
    })
    
    var card = _get_card(card_id)
    if card == null:
        logger.log(Logger.LogLevel.ERROR, Logger.LogType.ERROR, "Card not found", {
            "card_id": card_id
        })
        return
    
    # 记录处理完成
    logger.log(Logger.LogLevel.INFO, Logger.LogType.MAIN, "Card processed successfully", {
        "card_id": card_id,
        "card_type": card.type
    })

# 3. 性能日志
func _process(delta: float) -> void:
    var logger = GameManager.logger
    var fps = Engine.get_frames_per_second()
    
    if fps < 30:
        logger.log(Logger.LogLevel.WARNING, Logger.LogType.PERFORMANCE, "Low FPS detected", {
            "fps": fps,
            "delta": delta
        })
```

#### 2.7.5 日志归档规范

```gdscript
# 日志归档管理器
class_name LogArchiver
extends Node

const MAX_LOG_SIZE_KB = 1024  # 单个日志文件最大1MB
const MAX_LOG_FILES = 10      # 每种类型最多保留10个日志文件

func archive_old_logs() -> void:
    """归档旧日志"""
    var log_dir = "res://logs/game/"
    var dir = DirAccess.open(log_dir)
    
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        
        while file_name != "":
            if not dir.current_is_dir() and file_name.ends_with(".log"):
                var file_path = log_dir + file_name
                var file_size = FileAccess.open(file_path, FileAccess.READ).get_length()
                
                # 如果文件超过大小限制，归档
                if file_size > MAX_LOG_SIZE_KB * 1024:
                    _archive_file(file_path, file_name)
            
            file_name = dir.get_next()

func _archive_file(file_path: String, file_name: String) -> void:
    """归档单个文件"""
    var datetime = Time.get_datetime_string_from_system()
    var year = str(datetime.year)
    var month = str(datetime.month).pad_zeros(2)
    
    var archive_dir = "res://logs/archive/%s/%s/" % [year, month]
    if not DirAccess.dir_exists_absolute(archive_dir):
        DirAccess.make_dir_absolute(archive_dir)
    
    var archive_name = "%s_%s" % [file_name.replace(".log", ""), datetime]
    var archive_path = archive_dir + archive_name + ".log"
    
    # 移动文件
    DirAccess.rename_absolute(file_path, archive_path)
```

#### 2.7.6 日志安全规范

```
1. 敏感信息过滤
   - 禁止记录用户密码、密钥等敏感信息
   - 禁止记录完整的用户个人数据
   - 记录用户ID时使用脱敏处理

2. 日志访问控制
   - 仅授权人员可访问日志文件
   - 生产环境日志加密存储
   - 定期清理旧日志

3. 日志完整性
   - 日志文件添加时间戳
   - 防止日志被篡改
   - 关键操作必须记录日志
```

---

## 第三章：工作流程规范

### 3.1 功能开发流程规范

#### 3.1.1 开发前准备（强制执行）

```
【重要】每次开发任务开始前，必须执行以下检查：

1. 设计文档审查（必做）
   ├─ 阅读《游戏设计文档》相关章节
   │   └─ 路径：gba-hiking/docs/design/game_design_doc.md
   ├─ 阅读《技术架构文档》相关章节
   │   └─ 路径：gba-hiking/docs/architecture/architecture_doc.md
   ├─ 确认是否有详细设计
   └─ 如果没有详细设计：
       ├─ 先补充设计文档
       ├─ 明确功能边界和技术实现方案
       ├─ 定义接口和信号
       └─ 设计审核通过后再开始开发

2. 开发规范确认（必做）
   ├─ 确认符合《项目开发指导规范》
   ├─ 确认编码规范（文件命名、代码结构等）
   ├─ 确认架构设计规范（分层架构、模块通信）
   └─ 确认日志记录规范

3. 任务拆分（推荐）
   ├─ 将功能拆分为可测试的小任务
   ├─ 预估工时
   └─ 排定开发优先级

【违规处理】：
- 未审查设计文档直接开发的代码不得合并
- 未遵循开发规范的代码将被退回修改
- 重复违反规范的团队成员将进行培训
```

#### 3.1.2 开发实施流程

### 3.1 功能开发流程

#### 3.1.1 开发前准备

```
1. 需求分析（必做）
   ├─ 阅读《游戏设计文档》相关章节
   ├─ 阅读《技术架构文档》相关章节
   └─ 明确功能边界和技术实现方案

2. 设计文档编写（必做）
   ├─ 编写功能设计文档（含时序图、类图）
   ├─ 定义接口和信号
   └─ 审核通过后进入开发

3. 任务拆分（推荐）
   ├─ 将功能拆分为可测试的小任务
   ├─ 预估工时
   └─ 排定开发优先级
```

#### 3.1.2 开发实施流程

```
1. 创建文件
   ├─ 场景文件 (.tscn)
   ├─ 脚本文件 (.gd)
   └─ 资源文件（如有）

2. 编写代码
   ├─ 遵循编码规范
   ├─ 添加必要注释
   └─ 使用类型注解

3. 本地测试
   ├─ 单元测试（如有）
   ├─ 功能测试
   └─ 边界测试

4. 代码审查
   ├─ 提交Pull Request
   ├─ 团队成员审查
   └─ 根据反馈修改

5. 合并发布
   ├─ 合并到主分支
   ├─ 更新版本号
   └─ 部署到测试环境
```

### 3.2 Git工作流规范

#### 3.2.1 分支管理

```
分支策略：
- main（主分支）：稳定版本，仅接受经过测试的代码
- develop（开发分支）：日常开发，功能合并到此处
- feature/*（功能分支）：从 develop 分出，完成后合并回 develop
- bugfix/*（修复分支）：从 develop 分出，修复后合并回 develop
- hotfix/*（紧急修复）：从 main 分出，修复后合并回 main 和 develop

分支命名规范：
- feature/CardSystem (卡牌系统功能)
- bugfix/MemoryLeak (内存泄漏修复)
- hotfix/CrashOnStart (启动崩溃修复)
```

#### 3.2.2 提交规范

```
提交信息格式：<type>(<scope>): <subject>

Type 类型：
- feat: 新功能
- fix: 修复bug
- docs: 文档更新
- style: 代码格式调整（不影响功能）
- refactor: 重构（不是新增功能也不是修复bug）
- perf: 性能优化
- test: 测试相关
- chore: 构建工具、辅助工具等

Scope 范围：
- CardSystem: 卡牌系统
- UI: 用户界面
- Attribute: 属性系统
- Economy: 经济系统
- Save: 存档系统
- Steam: Steam集成
- Build: 构建系统

示例提交信息：
feat(CardSystem): 实现卡牌穿越机制
fix(UI): 修复卡牌选中高亮显示bug
refactor(Attribute): 重构属性计算逻辑
docs(README): 更新安装说明
perf(UI): 优化卡牌动画性能
```

#### 3.2.3 代码审查规范

```
审查清单：
□ 代码遵循本规范文档
□ 函数和变量命名清晰
□ 添加必要的注释和文档
□ 错误处理完善
□ 性能无明显问题
□ 无安全漏洞
□ 测试覆盖充分
□ 不引入新bug

审查流程：
1. 提交Pull Request
2. 至少一名团队成员审查
3. 根据反馈进行修改
4. 审查通过后合并
```

### 3.3 测试规范

#### 3.3.1 单元测试

```gdscript
# 测试文件命名：[模块名]_test.gd
# 位置：tests/unit/[模块名]_test.gd

extends "res://tests/test_framework.gd"

func test_create_card() -> void:
    """测试卡牌创建功能"""
    var card = CardSystem.create_card("scenery", 1)
    assert_not_null(card, "Card should not be null")
    assert_eq(card.type, "scenery", "Card type should be scenery")
    assert_eq(card.tier, 1, "Card tier should be 1")

func test_card_energy_cost() -> void:
    """测试卡牌能量消耗"""
    var card = CardSystem.create_card("terrain", 3)
    var cost = CardSystem.get_energy_cost(card)
    assert_true(cost > 0, "Energy cost should be positive")
```

#### 3.3.2 集成测试

```gdscript
# 测试文件命名：[模块名]_integration_test.gd
# 位置：tests/integration/[模块名]_integration_test.gd

extends "res://tests/test_framework.gd"

func test_card_crossing_workflow() -> void:
    """测试卡牌穿越完整流程"""
    # 1. 创建关卡
    var level = LevelManager.create_level(1)
    assert_not_null(level, "Level should be created")
    
    # 2. 生成卡牌
    LevelManager.generate_cards(level)
    assert_true(level.get_card_count() > 0, "Should have cards")
    
    # 3. 穿越卡牌
    var first_card = level.get_card_at(0)
    var result = CardSystem.cross_card(first_card)
    assert_true(result.success, "Card should be crossed")
    
    # 4. 检查连击
    if CardSystem.check_combo():
        assert_true(ComboSystem.combo_count > 0, "Combo should be active")
```

#### 3.3.3 测试覆盖率

```
覆盖率要求：
- 核心系统（CardSystem、AttributeSystem、EconomySystem）：≥ 80%
- UI模块：≥ 60%
- 工具模块：≥ 90%
- 整体代码：≥ 70%

覆盖率检查工具：
- 使用 Godot Test Framework
- 定期生成覆盖率报告
- 不达标的功能不得合并
```

---

## 第四章：架构设计规范

### 4.1 分层架构实施

#### 4.1.1 表现层规范

```
职责：UI渲染、动画播放、音效播放、用户输入处理
技术：Control节点、Tween动画、AudioStreamPlayer2D

规范：
1. 表现层不包含业务逻辑
2. 通过信号接收逻辑层通知
3. 所有动画使用Tween实现平滑过渡
4. 用户输入事件传递到逻辑层处理

示例：
# BattleUI.gd (表现层)
extends Control

func _ready():
    # 连接信号
    CardSystem.card_crossed.connect(_on_card_crossed)
    ComboSystem.combo_changed.connect(_on_combo_changed)

func _on_card_crossed(card_id: int):
    """卡牌穿越时更新UI"""
    _update_card_visual(card_id)
    _play_crossing_animation(card_id)
```

#### 4.1.2 逻辑层规范

```
职责：游戏逻辑、规则判定、状态管理、事件处理
技术：GDScript脚本、状态机、事件总线、信号机制

规范：
1. 逻辑层不直接操作UI
2. 所有状态变化通过信号通知
3. 使用状态机管理复杂逻辑
4. 单元测试覆盖核心逻辑

示例：
# CardSystem.gd (逻辑层)
extends Node

signal card_crossed(card_id: int)
signal layer_completed(layer_index: int)

func cross_card(card_id: int) -> void:
    """穿越卡牌"""
    var card = _get_card(card_id)
    _apply_crossing_effect(card)
    _check_layer_completion()
    emit_signal("card_crossed", card_id)
```

#### 4.1.3 数据层规范

```
职责：数据存储、配置加载、存档管理、网络同步
技术：Resource资源、JSON配置、文件系统、Steam云同步

规范：
1. 所有配置文件版本化管理
2. 存档数据加密存储
3. 支持热更新配置
4. 数据访问通过数据管理器

示例：
# SaveManager.gd (数据层)
extends Node

func save_game(data: Dictionary) -> bool:
    """保存游戏数据"""
    var save_path = "user://savegame_%d.sav" % data["slot_id"]
    var file = FileAccess.open(save_path, FileAccess.WRITE)
    
    if file == null:
        push_error("Failed to open save file: %s" % save_path)
        return false
    
    var json_string = JSON.stringify(data)
    file.store_string(json_string)
    file.close()
    
    return true
```

### 4.2 模块通信规范

#### 4.2.1 信号通信

```gdscript
# 发送信号
emit_signal("card_crossed", card_id)

# 接收信号
CardSystem.card_crossed.connect(_on_card_crossed)

# 自定义信号
signal custom_event(event_data: Dictionary, priority: int)
```

#### 4.2.2 接口通信

```gdscript
# 定义接口（使用虚函数）
class_name ICardEffect

extends RefCounted

func apply_effect(card_data: CardData, target: Node) -> void:
    """应用卡牌效果"""
    pass

# 实现接口
class_name TerrainCardEffect extends ICardEffect

func apply_effect(card_data: CardData, target: Node) -> void:
    """地形卡效果"""
    AttributeSystem.consume_energy(target, card_data.energy_cost)
```

### 4.3 性能优化规范

#### 4.3.1 内存管理

```gdscript
# 1. 及时释放不用的资源
func unload_unused_resources():
    """卸载未使用的资源"""
    var unused_textures = []
    for texture in _loaded_textures:
        if not texture.get_ref_count() > 1:
            unused_textures.append(texture)
    
    for texture in unused_textures:
        texture.unload()
        _loaded_textures.erase(texture)

# 2. 使用对象池避免频繁创建销毁
var _card_pool: Array[CardController] = []

func get_card() -> CardController:
    """从对象池获取卡牌"""
    if _card_pool.size() > 0:
        return _card_pool.pop_back()
    return _create_new_card()

func return_card(card: CardController):
    """归还卡牌到对象池"""
    card.reset()
    _card_pool.append(card)
```

#### 4.3.2 渲染优化

```gdscript
# 1. 使用可见性剔除
func _process(delta: float):
    """每帧检查可见性"""
    for card in _cards:
        if not _is_visible_on_screen(card):
            card.visible = false

# 2. 减少重绘
func set_card_color(card: CardController, color: Color):
    """设置卡牌颜色（减少重绘）"""
    if card.modulate != color:
        card.modulate = color
```

#### 4.3.3 性能监控

```gdscript
# PerformanceMonitor.gd
extends Node

var _frame_times: Array[float] = []
var _fps_history: Array[int] = []

func _process(delta: float):
    """监控性能"""
    _frame_times.append(delta)
    _fps_history.append(Engine.get_frames_per_second())
    
    # 保持最近100帧的数据
    if _frame_times.size() > 100:
        _frame_times.pop_front()
        _fps_history.pop_front()

func get_average_fps() -> float:
    """获取平均FPS"""
    if _fps_history.is_empty():
        return 0.0
    return float(_fps_history.reduce(func(a, b): return a + b) / _fps_history.size())

func check_performance() -> void:
    """检查性能问题"""
    var avg_fps = get_average_fps()
    if avg_fps < 30:
        push_warning("Low FPS detected: %.2f" % avg_fps)
        PerformanceMonitor.auto_optimize()
```

---

## 第五章：资源管理规范

### 5.1 资源目录结构

```
res://
├── scenes/
│   ├── main_menu/
│   │   └── Main_Menu.tscn
│   ├── battle/
│   │   ├── Battle_Scene.tscn
│   │   └── Card_Scene.tscn
│   └── ui/
│       ├── Battle_UI.tscn
│       └── Shop_UI.tscn
├── scripts/
│   ├── managers/
│   │   ├── GameManager.gd
│   │   ├── CardSystem.gd
│   │   └── SaveManager.gd
│   ├── controllers/
│   │   ├── CardController.gd
│   │   └── UIController.gd
│   └── data/
│       └── CardData.gd
├── resources/
│   ├── textures/
│   │   ├── cards/
│   │   ├── ui/
│   │   └── backgrounds/
│   ├── audio/
│   │   ├── sfx/
│   │   └── music/
│   └── fonts/
├── autoloads/
│   ├── GameManager.gd
│   ├── CardSystem.gd
│   └── SaveManager.gd
├── config/
│   ├── card_database.json
│   ├── level_config.json
│   └── balance_config.json
└── tests/
    ├── unit/
    └── integration/
```

### 5.2 资源导入规范

```
1. 图片资源
   - 分辨率：2x 项目目标分辨率
   - 格式：PNG（透明背景）、JPG（不透明）
   - 压缩：使用Godot默认压缩设置

2. 音频资源
   - 格式：OGG（音乐）、WAV（音效）
   - 采样率：44100Hz
   - 比特率：128kbps（音乐）、16bit（音效）

3. 字体资源
   - 格式：TTF、OTF
   - 支持字符：中文、英文、数字、符号

4. 配置文件
   - 格式：JSON
   - 编码：UTF-8
   - 缩进：2空格
```

### 5.3 配置文件规范

#### 5.3.1 卡牌配置示例

```json
{
  "version": "1.0",
  "cards": [
    {
      "id": 1001,
      "name": "维多利亚港",
      "type": "scenery",
      "tier": 1,
      "icon_path": "res://resources/textures/cards/scenery_victoria_harbor.png",
      "description": "香港地标，穿越后恢复10点体能",
      "effects": [
        {
          "type": "restore_energy",
          "value": 10
        }
      ],
      "combo_bonus": {
        "type": "extra_energy",
        "value": 5
      }
    }
  ]
}
```

#### 5.3.2 关卡配置示例

```json
{
  "version": "1.0",
  "levels": [
    {
      "id": 1,
      "name": "澳门塔",
      "phase": "early",
      "layers": [
        {
          "layer_index": 1,
          "card_count": 4,
          "altitude": 220
        },
        {
          "layer_index": 2,
          "card_count": 3,
          "altitude": 250
        }
      ],
      "weather": {
        "type": "sunny",
        "effects": {
          "temperature_mod": 1.0,
          "visibility_mod": 1.0
        }
      }
    }
  ]
}
```

---

## 第六章：Steam集成规范

### 6.1 成就系统集成

```gdscript
# SteamManager.gd
extends Node

signal achievement_unlocked(achievement_id: String)

func unlock_achievement(achievement_id: String) -> bool:
    """解锁成就
    
    Args:
        achievement_id: 成就ID（如 "first_climb", "combo_master"）
    
    Returns:
        bool: 是否解锁成功
    """
    if not Steam.is_initialized():
        push_error("Steam not initialized")
        return false
    
    var success = Steam.set_achievement(achievement_id)
    if success:
        Steam.store_stats()
        emit_signal("achievement_unlocked", achievement_id)
        print_debug("[Steam] Achievement unlocked: %s" % achievement_id)
    
    return success
```

### 6.2 排行榜系统集成

```gdscript
# SteamManager.gd
extends Node

func submit_leaderboard_score(leaderboard_name: String, score: int) -> bool:
    """提交排行榜分数
    
    Args:
        leaderboard_name: 排行榜名称
        score: 分数
    
    Returns:
        bool: 是否提交成功
    """
    if not Steam.is_initialized():
        push_error("Steam not initialized")
        return false
    
    var call_result = Steam.set_leaderboard_score(leaderboard_name, score)
    return call_result != null
```

### 6.3 云存档同步

```gdscript
# SaveManager.gd
extends Node

func save_to_cloud(slot_id: int, data: Dictionary) -> bool:
    """保存到Steam云端
    
    Args:
        slot_id: 存档槽位ID
        data: 存档数据
    
    Returns:
        bool: 是否保存成功
    """
    if not Steam.is_initialized():
        push_error("Steam not initialized")
        return false
    
    # 先保存到本地
    if not save_game(data):
        return false
    
    # 上传到云端
    var save_path = "user://savegame_%d.sav" % slot_id
    var file = FileAccess.open(save_path, FileAccess.READ)
    var content = file.get_as_text()
    file.close()
    
    # Steam云端文件存储（需要C#或C++扩展）
    # 这里只是伪代码
    Steam.set_cloud_file("savegame_%d.json" % slot_id, content)
    
    return true
```

---

## 第七章：工具链规范

### 7.1 godot_parser集成

```python
# tools/card_generator.py
import json
from godot_parser import GDScene, Node, Resource

def generate_card_scene(card_config: dict):
    """生成卡牌场景文件
    
    Args:
        card_config: 卡牌配置字典
    
    Returns:
        GDScene: 卡牌场景对象
    """
    scene = GDScene()
    
    # 创建根节点
    root = Node("CardController")
    root.type = "Node2D"
    scene.add_child(root)
    
    # 添加精灵节点
    sprite = Node("Sprite2D")
    sprite.type = "Sprite2D"
    sprite.texture = f"res://resources/textures/cards/{card_config['icon_path']}"
    root.add_child(sprite)
    
    # 保存场景
    output_path = f"res://scenes/cards/{card_config['name']}.tscn"
    scene.write(output_path)
    
    return scene
```

### 7.2 自动化构建流程

```bash
# tools/build.sh
#!/bin/bash

echo "Starting build process..."

# 1. 导出项目
godot --headless --export "Windows Desktop" build/大湾区徒步.exe

# 2. 打包资源
# (根据需要执行)

# 3. 运行测试
godot --headless --script tests/run_tests.gd

# 4. 生成版本号
VERSION=$(date +%Y.%m.%d)
echo "Build version: $VERSION"

echo "Build completed successfully!"
```

---

## 第八章：文档规范

### 8.1 设计文档规范

```
1. 文档结构
   - 标题页：包含文档名称、版本、作者、日期
   - 目录：自动生成，保持更新
   - 正文：按照逻辑层次组织
   - 附录：参考资料、术语表等

2. 内容要求
   - 语言简洁、清晰、准确
   - 包含必要的图表和示例
   - 引用外部资料需注明来源
   - 版本更新需记录变更内容

3. 审查流程
   - 初稿完成后进行团队审查
   - 根据反馈修改完善
   - 审查通过后发布正式版本
   - 定期更新维护
```

### 8.2 代码文档规范

```gdscript
# 类文档
class_name CardSystem
extends Node

## 卡牌系统
##
## 负责卡牌的生成、管理、穿越判定、连击计算等核心功能
## 依赖于 AttributeSystem 和 ComboSystem
##
## Example:
##     [codeblock]
##     var card = CardSystem.create_card("scenery", 1)
##     CardSystem.cross_card(card.id)
##     [/codeblock]

# 函数文档
func create_card(type: String, tier: int) -> CardData:
    """创建新卡牌
    
    根据指定类型和等级生成卡牌数据
    
    [b]Args:[/b]
        type: 卡牌类型
        tier: 卡牌等级（1-5）
    
    [b]Returns:[/b]
        CardData: 生成的卡牌数据对象
    
    [b]Raises:[/b]
        ValueError: 当类型或等级无效时
    
    [b]Example:[/b]
        [codeblock]
        var card = CardSystem.create_card("scenery", 3)
        print(card.name) # 输出：维多利亚港
        [/codeblock]
    """
    # 实现...
```

---

## 第九章：版本管理规范

### 9.1 版本号规范

```
版本号格式：主版本.次版本.修订版本 (Major.Minor.Patch)

主版本（Major）：不兼容的API修改
次版本（Minor）：向下兼容的新功能
修订版本（Patch）：向下兼容的问题修复

示例：
- 1.0.0：首次正式发布
- 1.1.0：新增卡牌系统
- 1.1.1：修复卡牌穿越bug
- 2.0.0：重构整体架构（不兼容）
```

### 9.2 发布流程

```
1. 开发完成
   - 所有功能开发完成
   - 所有测试通过
   - 代码审查通过

2. 创建发布分支
   - 从 develop 创建 release/v1.0.0
   - 更新版本号
   - 更新 CHANGELOG

3. 测试验证
   - 运行所有测试
   - 进行全面回归测试
   - 修复发现的问题

4. 打包发布
   - 导出可执行文件
   - 打包资源
   - 生成安装包

5. 合并发布
   - 合并到 main
   - 合并回 develop
   - 打标签 v1.0.0

6. 上传Steam
   - 上传到Steam后台
   - 创建更新日志
   - 发布更新
```

---

## 第十章：团队协作规范

### 10.1 沟通规范

```
1. 日常沟通
   - 使用团队协作工具（Slack、Discord等）
   - 重要决策记录在文档中
   - 定期召开站会

2. 问题汇报
   - 使用问题跟踪系统
   - 详细描述问题复现步骤
   - 附上日志和截图

3. 代码审查
   - Pull Request必须附上说明
   - 审查意见要明确具体
   - 及时响应审查意见
```

### 10.2 任务分配

```
1. 任务创建
   - 在项目管理工具中创建任务
   - 明确任务目标、验收标准、截止日期
   - 指定负责人和优先级

2. 任务执行
   - 按照规范开发
   - 及时更新任务状态
   - 遇到问题及时沟通

3. 任务验收
   - 自测通过后提交审查
   - 审查通过后标记完成
   - 验收不合格则返回修改
```

---

## 附录A：检查清单

### A.1 代码提交检查清单

```
□ 代码符合本规范文档
□ 所有测试通过
□ 无编译警告和错误
□ 添加必要的注释
□ 更新相关文档
□ 提交信息格式正确
□ 已同步最新代码
```

### A.2 功能发布检查清单

```
□ 所有功能开发完成
□ 所有测试通过
□ 代码审查通过
□ 文档更新完成
□ 版本号更新
□ CHANGELOG更新
□ Steam配置更新
□ 安装包测试通过
```

---

## 附录B：常见问题

### B.1 如何处理不规范的代码？

```
1. 先在代码审查中指出问题
2. 使用统一代码格式化工具
3. 提交PR修正问题
4. 更新规范文档（如需要）
```

### B.2 如何紧急修复生产问题？

```
1. 从 main 创建 hotfix 分支
2. 快速修复问题
3. 紧急审查和测试
4. 合并回 main 和 develop
5. 打标签发布
```

### B.3 如何添加新的依赖库？

```
1. 先评估必要性和风险
2. 团队讨论通过
3. 添加到项目配置
4. 更新文档
5. 通知所有成员
```

---

## 附录C：工具推荐

### C.1 开发工具

```
- Godot Engine 4.5.1+
- Visual Studio Code (推荐编辑器)
- Git (版本控制)
- Godot Test Framework (测试)
- godot_parser (场景文件处理)
```

### C.2 辅助工具

```
- Prettier (代码格式化)
- ESLint (代码检查)
- Markdown编辑器 (文档编写)
- Figma (UI设计)
- GIMP/Photoshop (图像处理)
```

---

## 附录D：参考资源

### D.1 Godot官方文档

- [Godot Engine文档](https://docs.godotengine.org/)
- [GDScript参考](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
- [节点和场景](https://docs.godotengine.org/en/stable/tutorials/scripting/node_and_scene_tree.html)

### D.2 项目文档

- 《大湾区徒步》游戏设计文档 v5.4
- 《大湾区徒步》技术架构文档 v1.0
- 《大湾区徒步》美术风格指南

### D.3 外部资源

- [Steamworks SDK文档](https://partner.steamgames.com/doc/)
- [Card Framework](https://github.com/chun92/card-framework)
- [godot_parser](https://github.com/stevearc/godot_parser)

---

**文档结束**

《大湾区徒步》项目开发指导规范 v1.0  
**维护团队**：Godot开发团队  
**最后更新**：2026年1月29日

**重要提醒**：
- 本规范是强制性文档，所有开发任务必须严格遵守
- 遇到规范冲突或模糊之处，及时在团队中讨论解决
- 规范会根据项目进展持续优化，保持更新
- 违反规范的代码不得合并到主分支
