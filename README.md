# 《大湾区徒步》Godot项目

**项目类型**：2D卡牌Roguelike策略休闲游戏  
**开发引擎**：Godot Engine 4.5.1  
**目标平台**：Steam (PC/Windows)  
**项目版本**：1.0.0  
**创建日期**：2026年1月29日  

---

## 项目简介

《大湾区徒步》是一款以大湾区地理文化为背景，融合登山式消除、轻Roguelike卡牌构筑与环保教育的单人策略休闲游戏。玩家通过"穿越"卡牌模拟徒步登山，在爽快操作中深度体验岭南自然人文之美。

## 核心玩法

- **登山式卡牌布局**：正三角登山式布局，从底部山脚到顶部山顶，层数递减
- **穿越式消除机制**：穿越当前层所有卡牌才能"向上攀登"进入下一层
- **分级翻越系统**：翻越（平地）、攀岩（陡坡）、速降（下坡）三种模式
- **连击体系**：相同类型卡牌连续穿越触发连击，获得额外奖励
- **卡牌系统**：风景卡、地形障碍卡、资源卡、环境卡、照片卡
- **五维属性系统**：体能、背包容量、耐力、速度、心率
- **经济系统**：徒步数、海拔数、环保值

## 项目结构

```
gba-hiking/
├── autoloads/          # AutoLoad全局管理器
│   ├── GameManager.gd      # 游戏管理器
│   ├── CardSystem.gd       # 卡牌系统
│   ├── AttributeSystem.gd  # 属性系统
│   ├── ComboSystem.gd      # 连击系统
│   ├── EconomySystem.gd    # 经济系统
│   ├── SaveManager.gd      # 存档管理器
│   ├── UIManager.gd        # UI管理器
│   ├── AudioManager.gd     # 音频管理器
│   └── SteamManager.gd     # Steam管理器
├── config/             # 配置文件
│   ├── card_database.json  # 卡牌数据库
│   ├── level_config.json   # 关卡配置
│   ├── balance_config.json # 数值平衡配置
│   └── game_config.json    # 游戏配置
├── scenes/             # 场景文件
│   ├── main_menu/      # 主菜单
│   ├── battle/         # 战斗场景
│   ├── ui/             # UI场景
│   ├── cards/          # 卡牌场景
│   ├── shop/           # 商店场景
│   └── settings/       # 设置场景
├── scripts/            # 脚本文件
│   ├── managers/       # 管理器脚本
│   ├── controllers/    # 控制器脚本
│   ├── data/           # 数据类脚本
│   ├── ui/             # UI脚本
│   └── utils/          # 工具脚本
├── resources/          # 资源文件
│   ├── textures/       # 纹理贴图
│   ├── audio/          # 音频资源
│   ├── fonts/          # 字体文件
│   └── materials/      # 材质文件
├── tests/              # 测试文件
│   ├── unit/           # 单元测试
│   └── integration/    # 集成测试
├── tools/              # 开发工具
├── project.godot       # Godot项目配置
├── icon.svg            # 项目图标
└── .gitignore          # Git忽略文件
```

## 技术栈

- **游戏引擎**：Godot Engine 4.5.1+
- **主要语言**：GDScript (主语言)
- **辅助语言**：C# (性能关键模块)、C++ (GDExtension)
- **版本控制**：Git
- **目标平台**：Steam (PC/Windows)

## 开发规范

本项目严格遵循《项目开发指导规范》，所有开发任务必须按照规范执行：

### 核心规范

1. **编码规范**：统一的命名规范、代码风格、注释规范
2. **测试规范**：单元测试、集成测试、覆盖率要求
3. **工作流程规范**：Git工作流、代码审查、发布流程
4. **架构设计规范**：分层架构、模块通信、性能优化

### 关键原则

- **分层架构**：表现层、逻辑层、数据层
- **模块化设计**：低耦合高内聚，支持并行开发
- **数据驱动**：游戏数据配置化管理，支持热更新
- **性能优先**：PC端优化，高分辨率高刷新率稳定运行
- **标准化**：统一命名、代码风格、接口定义

## 快速开始

### 环境要求

- Godot Engine 4.5.1+
- Git
- Steamworks SDK (可选，用于Steam集成)

### 安装步骤

1. 克隆项目
```bash
git clone [repository-url] gba-hiking
cd gba-hiking
```

2. 使用Godot打开项目
```bash
godot --editor --path .
```

3. 运行项目
```bash
godot
```

### 开发流程

1. 阅读相关文档（《游戏设计文档》、《技术架构文档》）
2. 编写功能设计文档
3. 按照《项目开发指导规范》开发
4. 编写单元测试和集成测试
5. 代码审查
6. 合并到主分支

## 文档

### 核心文档

- [游戏设计文档 v5.4](./docs/design/game_design_doc.md)
- [技术架构文档 v1.0](./docs/architecture/architecture_doc.md)
- [项目开发指导规范](./PROJECT_DEVELOPMENT_GUIDE.md)
- [项目状态报告](./docs/PROJECT_STATUS.md)

### GitHub文档

- [GitHub配置](./docs/github/GITHUB_CONFIG.md)
- [贡献指南](./docs/github/CONTRIBUTING.md)

### 开发文档

- [快速开始](./docs/quickstart.md)
- [架构设计](./docs/architecture/overview.md)
- [API文档](./docs/api/reference.md)

## 团队

- **开发团队**：Godot开发团队
- **项目类型**：初级开发工程师为主，人员流动性高

## 许可证

待定

## 联系方式

- 项目邮箱：gba-hiking@example.com
- 项目地址：[repository-url]

---

**最后更新**：2026年1月29日
