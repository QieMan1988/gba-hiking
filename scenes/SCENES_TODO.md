# 场景文件说明

## 需要创建的场景

使用Godot编辑器创建以下场景文件：

### 1. 主菜单场景
- 路径：`res://scenes/main_menu/Main_Menu.tscn`
- 根节点：Control (Main_Menu)
- 包含元素：
  - 开始游戏按钮
  - 加载游戏按钮
  - 设置按钮
  - 退出按钮

### 2. 战斗场景
- 路径：`res://scenes/battle/Battle_Scene.tscn`
- 根节点：Node2D (Battle_Scene)
- 包含元素：
  - 卡牌容器
  - 属性显示面板
  - 连击显示面板
  - 经济显示面板

### 3. UI场景
- 主菜单UI：`res://scenes/ui/MainMenu_UI.tscn`
- 战斗UI：`res://scenes/ui/Battle_UI.tscn`
- 设置UI：`res://scenes/ui/Settings_UI.tscn`
- 商店UI：`res://scenes/ui/Shop_UI.tscn`

## 创建步骤

1. 打开Godot编辑器
2. 选择 `新建场景`
3. 选择合适的根节点类型
4. 添加子节点
5. 配置节点属性
6. 附加脚本文件
7. 保存场景文件

## 注意事项

- 所有场景必须按照项目规范命名
- 场景路径必须与配置文件一致
- 脚本文件必须先创建，再附加到节点
