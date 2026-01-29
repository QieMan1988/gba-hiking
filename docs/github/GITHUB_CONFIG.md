# GitHub项目配置

## 仓库信息

- **仓库地址**：https://github.com/QieMan1988/gba-hiking
- **用户名**：QieMan1988
- **项目名称**：gba-hiking
- **项目类型**：2D卡牌Roguelike策略休闲游戏

## 认证信息

- **认证方式**：Personal Access Token (PAT)
- **Token用途**：代码推送、仓库管理

## 分支策略

- **main分支**：稳定版本，生产环境代码
- **develop分支**：开发分支，日常开发合并到此分支
- **feature/*分支**：功能开发分支
- **bugfix/*分支**：Bug修复分支
- **hotfix/*分支**：紧急修复分支

## 提交规范

提交信息格式：`<type>(<scope>): <subject>`

### Type 类型

- `feat`：新功能
- `fix`：修复bug
- `docs`：文档更新
- `style`：代码格式调整（不影响功能）
- `refactor`：重构（不是新增功能也不是修复bug）
- `perf`：性能优化
- `test`：测试相关
- `chore`：构建工具、辅助工具等

### Scope 范围

- `CardSystem`：卡牌系统
- `UI`：用户界面
- `Attribute`：属性系统
- `Economy`：经济系统
- `Save`：存档系统
- `Steam`：Steam集成
- `Build`：构建系统
- `Docs`：文档

### 示例

```
feat(CardSystem): 实现卡牌穿越机制
fix(UI): 修复卡牌选中高亮显示bug
docs(README): 更新安装说明
refactor(Attribute): 重构属性计算逻辑
perf(UI): 优化卡牌动画性能
```

## 工作流程

### 1. 功能开发流程

```
1. 从develop分支创建feature分支
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name

2. 在feature分支进行开发
   编写代码
   编写测试
   提交代码

3. 推送到远程仓库
   git push origin feature/your-feature-name

4. 创建Pull Request
   从feature/your-feature-name合并到develop
   请求代码审查

5. 合并后删除feature分支
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
```

### 2. Bug修复流程

```
1. 从develop分支创建bugfix分支
   git checkout develop
   git pull origin develop
   git checkout -b bugfix/bug-description

2. 修复bug
   定位问题
   编写修复代码
   编写测试验证

3. 推送并创建Pull Request
   从bugfix/bug-description合并到develop

4. 合并后删除bugfix分支
```

### 3. 紧急修复流程

```
1. 从main分支创建hotfix分支
   git checkout main
   git pull origin main
   git checkout -b hotfix/critical-bug

2. 快速修复bug
   优先修复
   简化测试

3. 推送并创建Pull Request
   从hotfix/critical-bug合并到main和develop

4. 合并后删除hotfix分支
```

## Pull Request 规范

### PR标题格式

`<type>: <subject>`

示例：`feat: 添加卡牌连击系统`

### PR描述模板

```markdown
## 变更类型
- [ ] 新功能
- [ ] Bug修复
- [ ] 重构
- [ ] 文档更新
- [ ] 性能优化

## 变更描述
简要描述本次PR的变更内容

## 相关Issue
Closes #(issue编号)

## 测试情况
- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 手动测试通过

## 截图（如适用）
（如果有UI变更，请提供截图）

## 检查清单
- [ ] 代码遵循项目规范
- [ ] 已添加必要的注释
- [ ] 已更新相关文档
- [ ] 测试覆盖率达标
```

## 代码审查规范

### 审查清单

- [ ] 代码遵循《项目开发指导规范》
- [ ] 函数和变量命名清晰
- [ ] 添加必要的注释和文档
- [ ] 错误处理完善
- [ ] 性能无明显问题
- [ ] 无安全漏洞
- [ ] 测试覆盖充分
- [ ] 不引入新bug

### 审查流程

1. 提交Pull Request
2. 至少一名团队成员审查
3. 根据反馈进行修改
4. 审查通过后合并
5. 合并后删除功能分支

## Issue 规范

### Issue标题格式

`<type>: <subject>`

示例：`bug: 卡牌穿越时游戏崩溃`

### Issue类型

- `bug`：Bug报告
- `feature`：功能请求
- `enhancement`：改进建议
- `documentation`：文档改进
- `performance`：性能问题
- `question`：问题咨询

### Issue描述模板

```markdown
## 问题类型
- [ ] Bug
- [ ] 功能请求
- [ ] 改进建议

## 环境信息
- Godot版本：
- 操作系统：
- 复现步骤：

## 问题描述
详细描述问题或需求

## 期望行为
描述期望的正确行为

## 实际行为
描述当前的实际行为

## 截图/日志
（如果有相关的截图或日志，请附加）

## 其他信息
任何其他相关信息
```

## 仓库保护规则

### 分支保护

- **main分支**
  - 需要Pull Request审查
  - 需要至少1次审查通过
  - 需要通过所有CI检查
  - 禁止强制推送

- **develop分支**
  - 需要Pull Request审查
  - 需要至少1次审查通过
  - 禁止强制推送

### 合并策略

- **Squash merge**：合并时压缩所有提交为一个
- **Rebase and merge**：变基后合并（保持线性历史）
- **Merge commit**：创建合并提交

推荐使用：**Squash merge**

## 安全注意事项

### Token管理

- Personal Access Token仅存储在本地
- 不要将Token提交到代码仓库
- Token定期更新（建议每3个月）

### 敏感信息

- 不要在代码中硬编码密码、密钥
- 使用环境变量或配置文件管理敏感信息
- 敏感配置文件添加到.gitignore

## CI/CD 配置

### GitHub Actions

项目使用GitHub Actions进行持续集成和持续部署。

```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v1
        with:
          version: 4.5.1
      - name: Run tests
        run: ./run_tests.sh all
```

## 版本管理

### 版本号格式

`主版本.次版本.修订版本 (Major.Minor.Patch)`

- **主版本**：不兼容的API修改
- **次版本**：向下兼容的新功能
- **修订版本**：向下兼容的问题修复

### 版本标签

创建版本标签：

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### 发布管理

在GitHub Releases页面创建发布，包含：
- 版本号
- 发布说明
- 变更日志
- 下载链接

## 许可证

项目许可证：[待定]

## 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork本仓库
2. 创建feature分支
3. 提交变更
4. 推送到分支
5. 创建Pull Request

## 联系方式

- **GitHub**：@QieMan1988
- **邮箱**：gba-hiking@example.com

---

**最后更新**：2026年1月29日
