# ============================================================
# 脚本名称：GameManager
# 功能描述：游戏主管理器 - 负责游戏流程控制、关卡管理、游戏状态
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node

## 信号定义
signal game_started(level_config: Dictionary)
signal game_paused()
signal game_resumed()
signal game_completed(success: bool, result: Dictionary)
signal level_changed(level_index: int)
signal game_state_changed(new_state: GameState)

## 游戏状态枚举
enum GameState {
	MENU,           # 主菜单
	LEVEL_SELECT,   # 关卡选择
	PLAYING,        # 游戏进行中
	PAUSED,         # 游戏暂停
	COMPLETED,      # 关卡完成
	GAME_OVER,      # 游戏结束
	SHOP            # 商店界面
}

## 当前游戏状态
var current_state: GameState = GameState.MENU

## 当前关卡信息
var current_level_index: int = 0
var current_level_config: Dictionary = {}
var current_play_count: int = 0

## 游戏统计
var total_hiking_distance: float = 0.0  # 总徒步距离（公里）
var total_elevation_gain: float = 0.0   # 总累积爬升（米）
var total_hiking_points: int = 0        # 总徒步数
var total_environmental_value: int = 0  # 总环保值

## 层级信息
var current_layer_index: int = 0        # 当前层级
var total_layers: int = 0               # 总层数
var layer_distance_per: float = 2.0     # 每层距离（公里）

## 地形信息
var current_terrain_type: String = "flat"  # 当前地形类型
var terrain_history: Array = []             # 地形历史记录

## 天气信息
var current_weather: String = "sunny"      # 当前天气
var weather_duration: int = 0              # 天气持续回合数

## 游戏配置引用
var game_config: Dictionary = {}
var balance_config: Dictionary = {}
var card_database: Dictionary = {}

## 性能统计
var frame_count: int = 0
var start_time: float = 0.0

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[GameManager] Initializing game manager...")
	load_game_configs()
	_initialize_signals()
	start_time = Time.get_ticks_msec() / 1000.0
	print_debug("[GameManager] Game manager initialized")

## 加载游戏配置
func load_game_configs() -> void:
	"""加载所有游戏配置文件"""
	var config_manager = get_node_or_null("/root/ConfigManager")
	if config_manager != null:
		game_config = config_manager.get_config("game_config")
		balance_config = config_manager.get_config("balance_config")
		card_database = config_manager.get_config("card_database")
	else:
		var config_loader = ConfigLoader.new()
		game_config = config_loader.load_config("res://config/game_config.json")
		balance_config = config_loader.load_config("res://config/balance_config.json")
		card_database = config_loader.load_config("res://config/card_database.json")

	if game_config.is_empty():
		push_error("[GameManager] Failed to load game_config.json")
		_set_default_game_config()

	if balance_config.is_empty():
		push_error("[GameManager] Failed to load balance_config.json")
		_set_default_balance_config()

	if card_database.is_empty():
		push_error("[GameManager] Failed to load card_database.json")

	print_debug("[GameManager] Game configurations loaded")

## 设置默认游戏配置（配置文件不存在时使用）
func _set_default_game_config() -> void:
	game_config = {
		"version": "1.0.0",
		"initial_energy": 100,
		"initial_hunger": 100,
		"initial_thirst": 100,
		"initial_fatigue": 0,
		"max_energy": 100,
		"min_energy": 0,
		"layer_distance_per": 2.0,
		"hiking_points_per_km": 2000,
		"max_layers_per_level": 13,
		"min_layers_per_level": 3
	}

## 设置默认平衡配置（配置文件不存在时使用）
func _set_default_balance_config() -> void:
	balance_config = {
		"version": "1.0.0",
		"terrain_weights": {
			"flat": 0.4,
			"gentle_up": 0.25,
			"steep_up": 0.15,
			"gentle_down": 0.12,
			"steep_down": 0.05,
			"cliff": 0.03
		},
		"weather_weights": {
			"sunny": 0.4,
			"cloudy": 0.25,
			"rain": 0.15,
			"hot": 0.12,
			"typhoon": 0.08
		},
		"rest_required_per_5km": 1.0,
		"supplies_required_per_10km": {
			"water": 2,
			"sports_drink": 1,
			"chocolate": 1
		}
	}

## 初始化信号连接
func _initialize_signals() -> void:
	TerrainSystem.knee_damage_taken.connect(_on_knee_damage_taken)

# ============================================================
# 游戏流程控制
# ============================================================

## 启动游戏
func start_game(level_config: Dictionary) -> void:
	"""开始新游戏"""
	print_debug("[GameManager] Starting game with level: %s" % level_config.get("name", "Unknown"))

	# 设置关卡配置
	current_level_config = level_config
	current_level_index = level_config.get("level_id", 0)
	total_layers = level_config.get("layers", 5)

	# 初始化层级
	current_layer_index = 0
	layer_distance_per = level_config.get(
		"layer_distance_per",
		game_config.get("layer_distance_per", layer_distance_per)
	)

	# 生成地形序列
	_generate_terrain_sequence()
	if terrain_history.size() > 0:
		current_terrain_type = terrain_history[0]
	_apply_terrain_effects(current_terrain_type)

	# 初始化天气
	_generate_initial_weather()

	# 初始化属性系统
	AttributeSystem.initialize()

	# 初始化卡牌系统
	CardSystem.initialize()

	# 初始化经济系统
	EconomySystem.initialize()

	# 初始化连击系统
	ComboSystem.initialize()

	# 初始化UI
	UIManager.show_battle_scene()

	# 改变游戏状态
	change_state(GameState.PLAYING)

	# 发送信号
	game_started.emit(level_config)

	print_debug("[GameManager] Game started")

## 暂停游戏
func pause_game() -> void:
	"""暂停游戏"""
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		get_tree().paused = true
		game_paused.emit()
		print_debug("[GameManager] Game paused")

## 恢复游戏
func resume_game() -> void:
	"""恢复游戏"""
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		get_tree().paused = false
		game_resumed.emit()
		print_debug("[GameManager] Game resumed")

## 完成关卡
func complete_level(success: bool, result: Dictionary) -> void:
	"""完成关卡（成功或失败）"""
	print_debug("[GameManager] Level completed: %s" % success)

	# 统计游戏数据
	_update_game_statistics(result)

	# 改变游戏状态
	if success:
		change_state(GameState.COMPLETED)
	else:
		change_state(GameState.GAME_OVER)

	# 发送信号
	game_completed.emit(success, result)

	# 显示结果界面
	UIManager.show_result_screen(success, result)

## 重新开始
func restart_game() -> void:
	"""重新开始当前关卡"""
	print_debug("[GameManager] Restarting game...")
	start_game(current_level_config)

## 返回主菜单
func return_to_menu() -> void:
	"""返回主菜单"""
	print_debug("[GameManager] Returning to menu...")
	change_state(GameState.MENU)
	UIManager.show_main_menu()

# ============================================================
# 关卡管理
# ============================================================

## 生成地形序列
func _generate_terrain_sequence() -> void:
	"""生成关卡的地形序列（上坡下坡）"""
	terrain_history.clear()

	var target_elevation_gain: float = current_level_config.get("elevation_gain", 0.0)
	var layers: int = current_level_config.get("layers", 5)
	var avg_gain_per_layer: float = target_elevation_gain / float(layers)

	for i in range(layers):
		var terrain_type: String = _determine_terrain_type(i, layers, avg_gain_per_layer)
		terrain_history.append(terrain_type)

	print_debug("[GameManager] Terrain sequence generated: %s" % terrain_history)

## 确定地形类型
func _determine_terrain_type(
	layer_index: int,
	layer_count: int,
	avg_gain_per_layer: float
) -> String:
	"""确定特定层级的地形类型"""
	var rand = randf()

	# 最后一层总是上坡到山顶
	if layer_index == layer_count - 1:
		if avg_gain_per_layer < 100:
			return TerrainSystem.TERRAIN_GENTLE_UP
		return TerrainSystem.TERRAIN_STEEP_UP

	# 第一层通常是平坦道路
	if layer_index == 0:
		return TerrainSystem.TERRAIN_FLAT

	# 根据平均爬升确定地形
	var weights = balance_config.get("terrain_weights", {})
	if weights.is_empty():
		return TerrainSystem.TERRAIN_FLAT

	# 如果平均爬升很高，增加上坡权重
	if avg_gain_per_layer > 200:
		if weights.has(TerrainSystem.TERRAIN_GENTLE_UP): weights[TerrainSystem.TERRAIN_GENTLE_UP] *= 1.5
		if weights.has(TerrainSystem.TERRAIN_STEEP_UP): weights[TerrainSystem.TERRAIN_STEEP_UP] *= 2.0
		if weights.has(TerrainSystem.TERRAIN_STAIRS_UP): weights[TerrainSystem.TERRAIN_STAIRS_UP] *= 1.8
		if weights.has(TerrainSystem.TERRAIN_FLAT): weights[TerrainSystem.TERRAIN_FLAT] *= 0.7
		if weights.has(TerrainSystem.TERRAIN_GENTLE_DOWN): weights[TerrainSystem.TERRAIN_GENTLE_DOWN] *= 0.5
		if weights.has(TerrainSystem.TERRAIN_STEEP_DOWN): weights[TerrainSystem.TERRAIN_STEEP_DOWN] *= 0.3
	elif avg_gain_per_layer < 50:
		if weights.has(TerrainSystem.TERRAIN_GENTLE_UP): weights[TerrainSystem.TERRAIN_GENTLE_UP] *= 0.7
		if weights.has(TerrainSystem.TERRAIN_STEEP_UP): weights[TerrainSystem.TERRAIN_STEEP_UP] *= 0.3
		if weights.has(TerrainSystem.TERRAIN_STAIRS_UP): weights[TerrainSystem.TERRAIN_STAIRS_UP] *= 0.4
		if weights.has(TerrainSystem.TERRAIN_FLAT): weights[TerrainSystem.TERRAIN_FLAT] *= 1.5
		if weights.has(TerrainSystem.TERRAIN_GENTLE_DOWN): weights[TerrainSystem.TERRAIN_GENTLE_DOWN] *= 1.2
		if weights.has(TerrainSystem.TERRAIN_STEEP_DOWN): weights[TerrainSystem.TERRAIN_STEEP_DOWN] *= 0.8

	# 根据权重随机选择
	var total_weight = 0.0
	for weight in weights.values():
		total_weight += weight

	var random_value = rand * total_weight
	var cumulative_weight = 0.0

	for terrain_type in weights:
		cumulative_weight += weights[terrain_type]
		if random_value <= cumulative_weight:
			return terrain_type

	return "flat"

## 生成初始天气
func _generate_initial_weather() -> void:
	"""生成关卡初始天气"""
	var weights = balance_config.get("weather_weights", {})

	var total_weight = 0.0
	for weight in weights.values():
		total_weight += weight

	var random_value = randf() * total_weight
	var cumulative_weight = 0.0

	for weather_type in weights:
		cumulative_weight += weights[weather_type]
		if random_value <= cumulative_weight:
			current_weather = weather_type
			break

	weather_duration = randi_range(3, 6)
	var initial_weather_message = "[GameManager] Initial weather: %s (duration: %d)" % [
		current_weather,
		weather_duration
	]
	print_debug(initial_weather_message)

## 更新天气
func update_weather() -> void:
	"""每回合更新天气"""
	weather_duration -= 1

	if weather_duration <= 0:
		var weights = balance_config.get("weather_weights", {})

		# 相同天气有50%概率延续
		if randf() < 0.5:
			weather_duration = randi_range(3, 6)
			return

		# 否则随机更换
		var total_weight = 0.0
		for weight in weights.values():
			total_weight += weight

		var random_value = randf() * total_weight
		var cumulative_weight = 0.0

		for weather_type in weights:
			cumulative_weight += weights[weather_type]
			if random_value <= cumulative_weight:
				current_weather = weather_type
				break

		weather_duration = randi_range(3, 6)

	var weather_message = "[GameManager] Weather updated: %s (duration: %d)" % [
		current_weather,
		weather_duration
	]
	print_debug(weather_message)

## 进入下一层
func advance_to_next_layer() -> void:
	"""进入下一层级"""
	if current_layer_index < total_layers - 1:
		current_layer_index += 1
		current_terrain_type = terrain_history[current_layer_index]
		_apply_terrain_effects(current_terrain_type)

		# 检查是否到达山顶
		if current_layer_index == total_layers - 1:
			complete_level(true, _get_level_result())
		else:
			level_changed.emit(current_layer_index)

		print_debug("[GameManager] Advanced to layer %d/%d" % [current_layer_index, total_layers])

func _apply_terrain_effects(terrain_type: String) -> void:
	TerrainSystem.set_current_terrain(terrain_type)
	var distance: float = layer_distance_per
	var elevation_gain: float = TerrainSystem.get_elevation_gain(terrain_type, distance)
	if elevation_gain > 0.0:
		EconomySystem.add_elevation_gain(elevation_gain)
	TerrainSystem.calculate_knee_damage(terrain_type, distance)

func _on_knee_damage_taken(_amount: float, current_health: float) -> void:
	AttributeSystem.set_knee_injury(current_health <= 30.0)

## 获取当前层级信息
func get_current_layer_info() -> Dictionary:
	"""获取当前层级的详细信息"""
	var layer_index = current_layer_index

	return {
		"layer_index": layer_index,
		"total_layers": total_layers,
		"terrain_type": current_terrain_type,
		"distance_so_far": (layer_index + 1) * layer_distance_per,
		"total_distance": total_layers * layer_distance_per,
		"is_summit": layer_index == total_layers - 1,
		"is_start": layer_index == 0
	}

# ============================================================
# 游戏状态管理
# ============================================================

## 改变游戏状态
func change_state(new_state: GameState) -> void:
	"""改变游戏状态"""
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		game_state_changed.emit(new_state)
		var state_message = "[GameManager] State changed: %s -> %s" % [
			GameState.keys()[old_state],
			GameState.keys()[new_state]
		]
		print_debug(state_message)

## 获取当前状态
func get_current_state() -> GameState:
	"""获取当前游戏状态"""
	return current_state

## 检查是否在特定状态
func is_in_state(state: GameState) -> bool:
	"""检查游戏是否在特定状态"""
	return current_state == state

# ============================================================
# 游戏统计
# ============================================================

## 更新游戏统计
func _update_game_statistics(result: Dictionary) -> void:
	"""更新游戏统计数据"""
	# 更新总徒步距离
	var distance = result.get("distance", 0.0)
	total_hiking_distance += distance

	# 更新总累积爬升
	var elevation_gain = result.get("elevation_gain", 0.0)
	total_elevation_gain += elevation_gain

	# 更新总徒步数
	var hiking_points = result.get("hiking_points", 0)
	total_hiking_points += hiking_points

	# 更新总环保值
	var env_value = result.get("environmental_value", 0)
	total_environmental_value += env_value

	# 更新游玩次数
	current_play_count += 1

	# 保存统计数据
	SaveManager.save_player_data()
	var statistics_message = (
		"[GameManager] Game statistics updated: distance=%.2fkm, "
		+ "elevation=%.0fm, points=%d, env=%d"
	) % [
		total_hiking_distance,
		total_elevation_gain,
		total_hiking_points,
		total_environmental_value
	]
	print_debug(statistics_message)

## 获取关卡结果
func _get_level_result() -> Dictionary:
	"""获取关卡结果数据"""
	var hiking_points = int(
		current_level_index
		* layer_distance_per
		* game_config.get("hiking_points_per_km", 2000)
	)
	return {
		"level_id": current_level_index,
		"success": true,
		"distance": current_level_index * layer_distance_per,
		"elevation_gain": _calculate_total_elevation_gain(),
		"hiking_points": hiking_points,
		"environmental_value": EconomySystem.get_environmental_value(),
		"layers_completed": current_layer_index + 1,
		"total_layers": total_layers,
		"play_count": current_play_count
	}

## 计算总累积爬升
func _calculate_total_elevation_gain() -> float:
	"""计算当前关卡的总累积爬升"""
	var total_gain = 0.0

	for terrain_type in terrain_history:
		if terrain_type in ["gentle_up", "steep_up", "cliff"]:
			if terrain_type == "gentle_up":
				total_gain += 50.0
			elif terrain_type == "steep_up":
				total_gain += 150.0
			elif terrain_type == "cliff":
				total_gain += 300.0

	return total_gain

## 获取游戏统计数据
func get_game_statistics() -> Dictionary:
	"""获取游戏统计数据"""
	return {
		"total_hiking_distance": total_hiking_distance,
		"total_elevation_gain": total_elevation_gain,
		"total_hiking_points": total_hiking_points,
		"total_environmental_value": total_environmental_value,
		"current_play_count": current_play_count,
		"highest_level": SaveManager.get_highest_level()
	}

# ============================================================
# 工具函数
# ============================================================

## 获取配置
func get_game_config(key: String, default_value = null):
	"""获取游戏配置"""
	return game_config.get(key, default_value)

## 获取平衡配置
func get_balance_config(key: String, default_value = null):
	"""获取平衡配置"""
	return balance_config.get(key, default_value)

## 获取卡牌数据库
func get_card_database() -> Dictionary:
	"""获取卡牌数据库"""
	return card_database

## 获取特定卡牌信息
func get_card_info(card_id: String) -> Dictionary:
	"""获取特定卡牌的信息"""
	return card_database.get(card_id, {})

## 计算体能消耗
func calculate_energy_cost(distance: float, elevation_gain: float) -> float:
	"""根据徒步距离和累积爬升计算体能消耗"""
	var cost = (distance / 20.0) + (elevation_gain / 20.0)
	return max(cost, 0)

## 计算徒步数奖励
func calculate_hiking_points_reward(distance: float, elevation_gain: float) -> int:
	"""计算徒步数奖励"""
	var points_per_km = game_config.get("hiking_points_per_km", 2000)
	var distance_points = int(distance * points_per_km)
	var elevation_points = int(elevation_gain * 5)  # 每米爬升5点
	return distance_points + elevation_points

# ============================================================
# 进程
# ============================================================

func _process(_delta: float) -> void:
	frame_count += 1
	if frame_count % 60 == 0:
		# 每秒更新一次统计数据
		pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# 游戏关闭前保存
		SaveManager.save_player_data()
		get_tree().quit()

## 配置加载器（内部类）
class ConfigLoader:

	func load_config(file_path: String) -> Dictionary:
		"""加载配置文件"""
		if not FileAccess.file_exists(file_path):
			print_debug("[ConfigLoader] Config file not found: %s" % file_path)
			return {}

		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_text)

		if error != OK:
			print_debug("[ConfigLoader] JSON parse error: %s" % json.get_error_message())
			return {}

		return json.data
