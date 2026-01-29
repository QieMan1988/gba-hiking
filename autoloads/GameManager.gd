# ============================================================
# 脚本名称：GameManager
# 功能描述：全局游戏管理器，负责游戏生命周期、状态管理、场景切换
# 作者：Godot开发团队
# 创建日期：2026-01-29
# 最后修改：2026-01-29
# 依赖项：SaveManager, UIManager, AudioManager
# ============================================================
extends Node

## 全局游戏管理器
##
## 负责管理游戏的全局状态、生命周期、场景切换和核心流程
## 作为AutoLoad单例在游戏启动时自动加载

## 信号定义
signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(success: bool, reason: String)
signal scene_changed(scene_name: String)

## 游戏状态枚举
enum GameState {
	MENU,           # 主菜单
	BATTLE,         # 战斗场景
	PAUSE,          # 暂停
	GAME_OVER,      # 游戏结束
	LOADING         # 加载中
}

## 全局变量
var _current_state: GameState = GameState.MENU
var _current_scene: Node = null
var _current_level_id: int = 1
var _is_paused: bool = false

## 游戏配置
var _game_config: Dictionary = {
	"version": "1.0.0",
	"max_level_count": 10,
	"save_slots": 3,
	"enable_steam": true,
	"enable_debug": false
}

## 运行时数据
var _runtime_data: Dictionary = {
	"play_time": 0,
	"battle_count": 0,
	"total_cards_crossed": 0,
	"total_combo_count": 0
}

## 初始化
func _ready() -> void:
	print_debug("[GameManager] Game manager initialized")
	_load_game_config()
	_initialize_systems()

func _process(delta: float) -> void:
	"""每帧更新"""
	if not _is_paused and _current_state == GameState.BATTLE:
		_runtime_data["play_time"] += delta

## 公开方法

## 初始化系统
func _initialize_systems() -> void:
	"""初始化各个系统"""
	print_debug("[GameManager] Initializing systems...")
	
	# 初始化保存系统
	SaveManager.initialize()
	
	# 初始化音频系统
	AudioManager.initialize()
	
	# 初始化Steam系统
	if _game_config.enable_steam:
		SteamManager.initialize()
	
	print_debug("[GameManager] All systems initialized")

## 加载游戏配置
func _load_game_config() -> void:
	"""从配置文件加载游戏配置"""
	var config_path = "res://config/game_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			_game_config.merge(json.data, true)
			print_debug("[GameManager] Game config loaded")
		else:
			push_error("[GameManager] Failed to parse game config: %s" % json.get_error_message())
	else:
		print_debug("[GameManager] Game config file not found, using defaults")

## 场景管理

## 切换场景
func change_scene(scene_path: String) -> void:
	"""切换到指定场景
	
	Args:
		scene_path: 目标场景路径（如 "res://scenes/main_menu/Main_Menu.tscn"）
	"""
	print_debug("[GameManager] Changing scene to: %s" % scene_path)
	
	# 卸载当前场景
	if _current_scene != null:
		_current_scene.queue_free()
	
	# 加载新场景
	var new_scene = load(scene_path)
	if new_scene == null:
		push_error("[GameManager] Failed to load scene: %s" % scene_path)
		return
	
	_current_scene = new_scene.instantiate()
	get_tree().root.add_child(_current_scene)
	
	# 更新游戏状态
	var scene_name = scene_path.get_file().get_basename()
	if scene_name == "Main_Menu":
		_set_game_state(GameState.MENU)
	elif scene_name == "Battle_Scene":
		_set_game_state(GameState.BATTLE)
	
	emit_signal("scene_changed", scene_name)
	print_debug("[GameManager] Scene changed successfully")

## 游戏状态管理

## 设置游戏状态
func _set_game_state(state: GameState) -> void:
	"""设置游戏状态
	
	Args:
		state: 新的游戏状态
	"""
	_current_state = state
	print_debug("[GameManager] Game state changed to: %s" % GameState.keys()[state])

## 获取当前游戏状态
func get_game_state() -> GameState:
	"""获取当前游戏状态
	
	Returns:
		GameState: 当前游戏状态
	"""
	return _current_state

## 暂停游戏
func pause_game() -> void:
	"""暂停游戏"""
	if _current_state == GameState.BATTLE and not _is_paused:
		_is_paused = true
		_set_game_state(GameState.PAUSE)
		get_tree().paused = true
		emit_signal("game_paused")
		print_debug("[GameManager] Game paused")

## 恢复游戏
func resume_game() -> void:
	"""恢复游戏"""
	if _is_paused:
		_is_paused = false
		_set_game_state(GameState.BATTLE)
		get_tree().paused = false
		emit_signal("game_resumed")
		print_debug("[GameManager] Game resumed")

## 开始新游戏
func start_new_game() -> void:
	"""开始新游戏"""
	print_debug("[GameManager] Starting new game...")
	
	# 重置运行时数据
	_runtime_data = {
		"play_time": 0,
		"battle_count": 0,
		"total_cards_crossed": 0,
		"total_combo_count": 0
	}
	
	# 初始化系统
	CardSystem.initialize()
	AttributeSystem.initialize()
	ComboSystem.initialize()
	EconomySystem.initialize()
	
	# 切换到战斗场景
	change_scene("res://scenes/battle/Battle_Scene.tscn")
	emit_signal("game_started")

## 结束游戏
func end_game(success: bool, reason: String) -> void:
	"""结束游戏
	
	Args:
		success: 是否成功
		reason: 结束原因
	"""
	_set_game_state(GameState.GAME_OVER)
	emit_signal("game_over", success, reason)
	
	print_debug("[GameManager] Game ended - Success: %s, Reason: %s" % [success, reason])
	
	# 保存统计数据
	_save_runtime_data()
	
	# 显示结算界面
	UIManager.show_game_over(success, reason)

## 关卡管理

## 设置当前关卡
func set_current_level(level_id: int) -> void:
	"""设置当前关卡
	
	Args:
		level_id: 关卡ID
	"""
	_current_level_id = level_id
	print_debug("[GameManager] Current level set to: %d" % level_id)

## 获取当前关卡
func get_current_level() -> int:
	"""获取当前关卡ID
	
	Returns:
		int: 当前关卡ID
	"""
	return _current_level_id

## 数据获取

## 获取游戏配置
func get_config() -> Dictionary:
	"""获取游戏配置
	
	Returns:
		Dictionary: 游戏配置字典
	"""
	return _game_config.duplicate()

## 获取运行时数据
func get_runtime_data() -> Dictionary:
	"""获取运行时数据
	
	Returns:
		Dictionary: 运行时数据字典
	"""
	return _runtime_data.duplicate()

## 更新运行时数据
func update_runtime_data(key: String, value) -> void:
	"""更新运行时数据
	
	Args:
		key: 数据键
		value: 数据值
	"""
	_runtime_data[key] = value

## 私有方法

## 保存运行时数据
func _save_runtime_data() -> void:
	"""保存运行时数据到存档"""
	var save_data = {
		"slot_id": 0,
		"runtime_data": _runtime_data,
		"timestamp": Time.get_unix_time_from_system()
	}
	SaveManager.save_game(save_data)

## 退出游戏
func quit_game() -> void:
	"""退出游戏"""
	print_debug("[GameManager] Quitting game...")
	
	# 保存游戏
	if _current_state == GameState.BATTLE:
		_save_runtime_data()
	
	# 关闭Steam
	if _game_config.enable_steam:
		SteamManager.shutdown()
	
	get_tree().quit()
