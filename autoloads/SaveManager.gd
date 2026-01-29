# ============================================================
# 脚本名称：SaveManager
# 功能描述：存档管理器 - 管理游戏存档、读取、删除
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node

## 存档文件路径
const SAVE_FILE_PATH = "user://save_data.json"
const SETTINGS_FILE_PATH = "user://settings.json"
const BACKUP_FILE_PATH = "user://save_data_backup.json"

## 存档数据
var player_data: Dictionary = {}
var settings_data: Dictionary = {}

## 存档版本
const SAVE_VERSION = "1.0.0"

## 自动保存定时器
var auto_save_timer: Timer

## 存档状态
var is_saving: bool = false
var is_loading: bool = false

## 信号
signal save_completed(success: bool)
signal load_completed(success: bool)
signal save_failed(error: String)

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[SaveManager] Initializing save manager...")
	_setup_auto_save()
	load_all_data()
	print_debug("[SaveManager] Save manager initialized")

## 设置自动保存
func _setup_auto_save() -> void:
	"""设置自动保存定时器"""
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 60.0  # 每60秒自动保存
	auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(_on_auto_save)
	add_child(auto_save_timer)

## 加载所有数据
func load_all_data() -> void:
	"""加载所有存档数据"""
	load_player_data()
	load_settings()

# ============================================================
# 玩家数据管理
# ============================================================

## 获取玩家数据
func get_player_data() -> Dictionary:
	"""获取玩家数据"""
	if player_data.is_empty():
		_create_default_player_data()
	return player_data.duplicate()

## 创建默认玩家数据
func _create_default_player_data() -> void:
	"""创建默认玩家数据"""
	player_data = {
		"version": SAVE_VERSION,
		"player_id": generate_player_id(),
		"player_name": "徒步者",
		"created_at": Time.get_unix_time_from_system(),
		"last_played": Time.get_unix_time_from_system(),
		"total_play_time": 0,
		"hiking_points": 0,
		"elevation_gain": 0.0,
		"total_environmental_value": 0,
		"highest_level": 0,
		"total_games_played": 0,
		"total_games_won": 0,
		"max_combo": 0,
		"photo_collection": [],
		"equipment": [],
		"unlocked_levels": [1, 1.5, 1.8],  # 新手关和澳门新手关
		"settings": {}
	}
	
	print_debug("[SaveManager] Created default player data")

## 生成玩家ID
func generate_player_id() -> String:
	"""生成唯一玩家ID"""
	var timestamp = Time.get_unix_time_from_system()
	var random = randi() % 1000000
	return "PLAYER_%d_%d" % [timestamp, random]

## 保存玩家数据
func save_player_data() -> void:
	"""保存玩家数据"""
	if is_saving:
		return
	
	is_saving = true
	
	# 更新最后游玩时间
	player_data["last_played"] = Time.get_unix_time_from_system()
	player_data["version"] = SAVE_VERSION
	
	var json_string = JSON.stringify(player_data, "\t")
	
	# 创建备份
	_create_backup()
	
	# 保存主存档
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		save_failed.emit("Failed to open save file: %d" % error)
		is_saving = false
		return
	
	file.store_string(json_string)
	file.close()
	
	save_completed.emit(true)
	is_saving = false
	
	print_debug("[SaveManager] Player data saved successfully")

## 加载玩家数据
func load_player_data() -> bool:
	"""加载玩家数据"""
	if is_loading:
		return false
	
	is_loading = true
	
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		_create_default_player_data()
		save_player_data()
		is_loading = false
		return true
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		save_failed.emit("Failed to open save file: %d" % error)
		is_loading = false
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		print_debug("[SaveManager] JSON parse error: %s" % json.get_error_message())
		_load_backup()  # 尝试加载备份
		is_loading = false
		return false
	
	player_data = json.data
	
	# 检查版本兼容性
	_check_version_compatibility()
	
	load_completed.emit(true)
	is_loading = false
	
	print_debug("[SaveManager] Player data loaded successfully")
	return true

## 创建备份
func _create_backup() -> void:
	"""创建存档备份"""
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var source_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var content = source_file.get_as_text()
		source_file.close()
		
		var backup_file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.WRITE)
		backup_file.store_string(content)
		backup_file.close()

## 加载备份
func _load_backup() -> bool:
	"""加载存档备份"""
	if not FileAccess.file_exists(BACKUP_FILE_PATH):
		_create_default_player_data()
		return false
	
	var file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		_create_default_player_data()
		return false
	
	player_data = json.data
	return true

## 检查版本兼容性
func _check_version_compatibility() -> void:
	"""检查存档版本兼容性"""
	var version = player_data.get("version", "")
	if version != SAVE_VERSION:
		print_debug("[SaveManager] Save version mismatch: %s (expected: %s)" % [version, SAVE_VERSION])
		_migrate_save_data(version)

## 迁移存档数据
func _migrate_save_data(old_version: String) -> void:
	"""迁移存档数据到新版本"""
	print_debug("[SaveManager] Migrating save data from version %s" % old_version)
	# 这里添加版本迁移逻辑
	player_data["version"] = SAVE_VERSION

# ============================================================
# 设置管理
# ============================================================

## 保存设置
func save_settings() -> void:
	"""保存游戏设置"""
	var json_string = JSON.stringify(settings_data, "\t")
	
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Failed to save settings")
		return
	
	file.store_string(json_string)
	file.close()
	
	print_debug("[SaveManager] Settings saved")

## 加载设置
func load_settings() -> void:
	"""加载游戏设置"""
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		_create_default_settings()
		return
	
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if file == null:
		_create_default_settings()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		_create_default_settings()
		return
	
	settings_data = json.data

## 创建默认设置
func _create_default_settings() -> void:
	"""创建默认设置"""
	settings_data = {
		"master_volume": 1.0,
		"bgm_volume": 0.8,
		"sfx_volume": 1.0,
		"language": "zh_CN",
		"graphics_quality": 2,
		"show_tutorial": true,
		"auto_save": true,
		"confirm_traverse": true
	}

# ============================================================
# 游戏数据更新
# ============================================================

## 更新最高关卡
func update_highest_level(level_id: float) -> void:
	"""更新最高关卡"""
	if level_id > player_data.get("highest_level", 0):
		player_data["highest_level"] = level_id
		save_player_data()

## 添加解锁关卡
func add_unlocked_level(level_id: float) -> void:
	"""添加解锁关卡"""
	var unlocked_levels = player_data.get("unlocked_levels", [])
	if not level_id in unlocked_levels:
		unlocked_levels.append(level_id)
		player_data["unlocked_levels"] = unlocked_levels
		save_player_data()

## 添加照片卡
func add_photo_card(photo_id: String) -> void:
	"""添加照片卡到收藏"""
	var collection = player_data.get("photo_collection", [])
	if not photo_id in collection:
		collection.append(photo_id)
		player_data["photo_collection"] = collection
		save_player_data()

## 更新统计数据
func update_statistics(stats: Dictionary) -> void:
	"""更新游戏统计数据"""
	if stats.has("hiking_points"):
		player_data["hiking_points"] += stats["hiking_points"]
	if stats.has("elevation_gain"):
		player_data["elevation_gain"] += stats["elevation_gain"]
	if stats.has("environmental_value"):
		player_data["total_environmental_value"] += stats["environmental_value"]
	if stats.has("games_played"):
		player_data["total_games_played"] += stats["games_played"]
	if stats.has("games_won"):
		player_data["total_games_won"] += stats["games_won"]
	if stats.has("max_combo"):
		if stats["max_combo"] > player_data.get("max_combo", 0):
			player_data["max_combo"] = stats["max_combo"]
	
	save_player_data()

## 获取最高关卡
func get_highest_level() -> float:
	"""获取最高关卡"""
	return player_data.get("highest_level", 0)

## 获取已解锁关卡
func get_unlocked_levels() -> Array:
	"""获取已解锁关卡列表"""
	return player_data.get("unlocked_levels", [1, 1.5, 1.8])

## 获取照片卡收藏
func get_photo_collection() -> Array:
	"""获取照片卡收藏"""
	return player_data.get("photo_collection", [])

# ============================================================
# 存档管理
# ============================================================

## 删除存档
func delete_save_data() -> bool:
	"""删除存档数据"""
	var result = DirAccess.remove_absolute(SAVE_FILE_PATH)
	if result != OK:
		return false
	
	DirAccess.remove_absolute(BACKUP_FILE_PATH)
	_create_default_player_data()
	return true

## 导出存档
func export_save_data(file_path: String) -> bool:
	"""导出存档数据"""
	var json_string = JSON.stringify(player_data, "\t")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false
	
	file.store_string(json_string)
	file.close()
	return true

## 导入存档
func import_save_data(file_path: String) -> bool:
	"""导入存档数据"""
	if not FileAccess.file_exists(file_path):
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		return false
	
	player_data = json.data
	save_player_data()
	return true

## 获取存档信息
func get_save_info() -> Dictionary:
	"""获取存档信息"""
	return {
		"player_name": player_data.get("player_name", "徒步者"),
		"player_id": player_data.get("player_id", ""),
		"level": player_data.get("highest_level", 0),
		"hiking_points": player_data.get("hiking_points", 0),
		"elevation_gain": player_data.get("elevation_gain", 0),
		"games_played": player_data.get("total_games_played", 0),
		"games_won": player_data.get("total_games_won", 0),
		"created_at": player_data.get("created_at", 0),
		"last_played": player_data.get("last_played", 0)
	}

# ============================================================
# 定时器回调
# ============================================================

## 自动保存回调
func _on_auto_save() -> void:
	"""自动保存回调"""
	if GameManager.get_current_state() == GameManager.GameState.PLAYING:
		save_player_data()
		print_debug("[SaveManager] Auto saved")
