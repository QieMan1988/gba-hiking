# 《大湾区徒步》项目贡献指南

感谢你对《大湾区徒步》项目的关注和贡献！

## 如何贡献

### 1. 准备工作

#### Fork仓库

1. 访问项目仓库：https://github.com/QieMan1988/gba-hiking
2. 点击右上角的"Fork"按钮
3. 选择你的GitHub账号作为Fork目标

#### 克隆仓库

```bash
git clone https://github.com/YOUR_USERNAME/gba-hiking.git
cd gba-hiking
```

#### 添加上游仓库

```bash
git remote add upstream https://github.com/QieMan1988/gba-hiking.git
```

### 2. 开发流程

#### 创建开发分支

```bash
git checkout develop
git pull upstream develop
git checkout -b feature/your-feature-name
```

#### 进行开发

1. 按照项目规范编写代码
2. 确保代码通过测试
3. 更新相关文档

#### 提交变更

```bash
git add .
git commit -m "feat(scope): description"
```

提交信息格式：`<type>(<scope>): <subject>`

#### 推送到你的仓库

```bash
git push origin feature/your-feature-name
```

#### 创建Pull Request

1. 访问你的Fork仓库
2. 点击"New Pull Request"
3. 选择你的feature分支
4. 填写PR标题和描述
5. 提交PR

### 3. 代码审查

- 等待团队成员审查你的代码
- 根据反馈进行修改
- 审查通过后，代码将被合并到develop分支

### 4. 同步上游仓库

```bash
git checkout develop
git pull upstream develop
git push origin develop
```

## 开发规范

### 编码规范

请严格遵守《项目开发指导规范》中的编码规范：

- 文件命名：`[模块名][功能名].gd`
- 类命名：`PascalCase`
- 函数命名：`snake_case`
- 变量命名：`snake_case`
- 常量命名：`UPPER_SNAKE_CASE`

### 代码示例

```gdscript
# ============================================================
# 脚本名称：CardController
# 功能描述：卡牌控制器
# 作者：贡献者姓名
# 创建日期：2026-01-29
# ============================================================
extends Node2D

class_name CardController

## 信号定义
signal card_clicked(card_id: int)

## 导出变量
@export var card_id: int = 0

## 私有变量
var _is_hovered: bool = false

func _ready() -> void:
    """初始化"""
    pass

func on_card_click() -> void:
    """卡牌点击事件"""
    emit_signal("card_clicked", card_id)
```

### 测试要求

- 单元测试覆盖率 ≥ 70%
- 核心系统测试覆盖率 ≥ 80%
- 所有测试必须通过

### 文档要求

- 所有公共函数必须添加文档注释
- 复杂逻辑必须添加行内注释
- 新增功能需要更新README或相关文档

## 贡献类型

### Bug修复

1. 在Issue中描述bug
2. 等待维护者确认
3. 从develop分支创建bugfix分支
4. 修复bug并添加测试
5. 提交PR

### 新功能

1. 在Issue中提出功能建议
2. 等待维护者讨论和确认
3. 从develop分支创建feature分支
4. 实现功能并添加测试
5. 更新文档
6. 提交PR

### 文档改进

1. 直接在GitHub上编辑文档
2. 提交PR到develop分支
3. 说明改进内容

### 性能优化

1. 在Issue中描述性能问题
2. 从develop分支创建feature分支
3. 优化代码并添加性能测试
4. 提交PR

## 代码审查标准

### 必须满足

- [ ] 代码遵循项目规范
- [ ] 所有测试通过
- [ ] 添加必要的注释
- [ ] 更新相关文档
- [ ] 无安全漏洞
- [ ] 无性能问题

### 期望满足

- [ ] 代码可读性高
- [ ] 变量命名清晰
- [ ] 函数单一职责
- [ ] 错误处理完善

## Issue 指南

### 报告Bug

使用Bug报告模板：

```markdown
## 问题描述
简要描述bug

## 复现步骤
1. 步骤1
2. 步骤2
3. 步骤3

## 期望行为
描述期望的正确行为

## 实际行为
描述实际发生的行为

## 环境信息
- Godot版本：
- 操作系统：
- 其他相关信息：

## 截图/日志
如果有相关的截图或日志，请附加
```

### 提出功能请求

```markdown
## 功能描述
简要描述你想要的功能

## 使用场景
描述这个功能的使用场景

## 期望效果
描述你期望的效果

## 替代方案
描述你考虑过的替代方案

## 其他信息
任何其他相关信息
```

## 行为准则

### 我们的承诺

为了营造开放和友好的环境，我们承诺：
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

### 不可接受的行为

- 使用性别化语言或图像
- 人身攻击或侮辱性评论
- 公开或私下骚扰
- 未经许可发布他人的私人信息
- 其他不专业或不道德的行为

### 执行

违反这些准则的后果：
- 第一次：警告
- 第二次：临时禁止
- 严重违反：永久禁止

## 获得帮助

如果你有任何问题或需要帮助：

1. 查看[项目文档](../docs/)
2. 在GitHub Issues中提问
3. 联系维护者

## 认可贡献者

我们会在项目的贡献者列表中列出所有贡献者，感谢他们的帮助！

## 许可证

通过贡献代码，你同意你的贡献将在项目许可证下发布。

---

**感谢你的贡献！**
