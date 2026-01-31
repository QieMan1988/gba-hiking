# ============================================================
# 脚本名称：SteamManager
# 功能描述：Steam管理器 - 管理Steam集成、成就、排行榜
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node
# class_name SteamManager  <-- Commented out to avoid "hides autoload singleton" error

## Steam初始化状态
var is_steam_initialized: bool = false
var is_steam_available: bool = false

## Steam用户信息
var steam_id: int = 0
var steam_name: String = ""
var language: String = ""

## 成就系统
var achievements: Dictionary = {}

## 排行榜系统
var leaderboards: Dictionary = {}

## 云存档
var cloud_save_enabled: bool = false

## DLC检查
var dlcs: Dictionary = {}

## 信号
signal steam_initialized(success: bool)
signal achievement_achievement_unlocked(achievement_id: String)
signal leaderboard_score_submitted(leaderboard_name: String, success: bool)

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[SteamManager] Initializing Steam manager...")
	
	# 延迟初始化Steam（等待Godot启动完成）
	await get_tree().process_frame
	call_deferred("_initialize_steam")

## 初始化Steam
func _initialize_steam() -> void:
	"""初始化Steam API"""
	print_debug("[SteamManager] Attempting to initialize Steam...")
	
	# 检查Steam是否可用（通过Steamworks API）
	if not OS.has_feature("steam"):
		print_debug("[SteamManager] Steam not available (running without Steam)")
		is_steam_available = false
		steam_initialized.emit(false)
		return
	
	# 注意：这里需要集成Steamworks API
	# 由于Godot 4需要使用GDExtension或Steamworks.gd插件
	# 以下是示例代码，实际使用时需要替换为真实的Steam API调用
	
	# 模拟初始化（实际应该调用Steam API）
	_simulate_steam_initialization()
	
	print_debug("[SteamManager] Steam initialized: %s" % is_steam_initialized)

## 模拟Steam初始化（占位符）
func _simulate_steam_initialization() -> void:
	"""模拟Steam初始化（占位符，实际应该调用Steam API）"""
	# TODO: 集成真实的Steamworks API
	# 以下是示例代码结构：
	# 
	# if Steam.is_steam_running():
	#     is_steam_initialized = Steam.init()
	#     if is_steam_initialized:
	#         steam_id = Steam.get_steam_id()
	#         steam_name = Steam.get_persona_name()
	#         language = Steam.get_current_game_language()
	#         is_steam_available = true
	#         _load_achievements()
	#         _setup_leaderboards()
	#     else:
	#         print_debug("[SteamManager] Failed to initialize Steam")
	# else:
	#     print_debug("[SteamManager] Steam is not running")
	
	# 模拟成功初始化
	is_steam_initialized = true
	is_steam_available = true
	steam_id = 76561198000000000 + randi() % 1000000
	steam_name = "SteamUser"
	language = "schinese"
	
	steam_initialized.emit(true)

# ============================================================
# Steam状态查询
# ============================================================

## 检查Steam是否可用
func is_steam_enabled() -> bool:
	"""检查Steam是否可用"""
	return is_steam_initialized and is_steam_available

## 获取Steam ID
func get_steam_id() -> int:
	"""获取Steam ID"""
	return steam_id

## 获取Steam用户名
func get_steam_name() -> String:
	"""获取Steam用户名"""
	return steam_name

## 获取Steam语言
func get_steam_language() -> String:
	"""获取Steam语言"""
	return language

## 检查是否在Steam Deck上运行
func is_steam_deck() -> bool:
	"""检查是否在Steam Deck上运行"""
	return OS.has_feature("steam_deck")

# ============================================================
# 成就系统
# ============================================================

## 加载成就
func _load_achievements() -> void:
	"""加载成就列表"""
	# TODO: 通过Steam API加载成就
	achievements = {
		"first_step": {
			"name": "第一步",
			"description": "完成第一次徒步",
			"unlocked": false,
			"progress": 0,
			"target": 1
		},
		"distance_10km": {
			"name": "健行者",
			"description": "累计徒步10公里",
			"unlocked": false,
			"progress": 0,
			"target": 10
		},
		"distance_100km": {
			"name": "远足专家",
			"description": "累计徒步100公里",
			"unlocked": false,
			"progress": 0,
			"target": 100
		},
		"elevation_1000m": {
			"name": "登高望远",
			"description": "累计爬升1000米",
			"unlocked": false,
			"progress": 0,
			"target": 1000
		},
		"combo_10": {
			"name": "连击大师",
			"description": "达成10连击",
			"unlocked": false,
			"progress": 0,
			"target": 10
		},
		"environmentalist": {
			"name": "环保先锋",
			"description": "获得1000环保值",
			"unlocked": false,
			"progress": 0,
			"target": 1000
		},
		"completionist": {
			"name": "全图鉴",
			"description": "收集所有照片卡",
			"unlocked": false,
			"progress": 0,
			"target": 100
		}
	}
	
	# TODO: 同步Steam成就状态
	# for achievement_id in achievements:
	#     if Steam.get_achievement(achievement_id):
	#         achievements[achievement_id]["unlocked"] = true

## 解锁成就
func unlock_achievement(achievement_id: String) -> bool:
	"""解锁成就"""
	if not is_steam_available:
		return false
	
	if not achievements.has(achievement_id):
		push_error("[SteamManager] Achievement not found: %s" % achievement_id)
		return false
	
	if achievements[achievement_id]["unlocked"]:
		return false
	
	# TODO: 通过Steam API解锁成就
	# Steam.set_achievement(achievement_id)
	
	achievements[achievement_id]["unlocked"] = true
	achievement_achievement_unlocked.emit(achievement_id)
	
	print_debug("[SteamManager] Achievement unlocked: %s" % achievement_id)
	return true

## 更新成就进度
func update_achievement_progress(achievement_id: String, progress: int) -> void:
	"""更新成就进度"""
	if not achievements.has(achievement_id):
		return
	
	achievements[achievement_id]["progress"] = progress
	
	# 检查是否达到目标
	var target = achievements[achievement_id]["target"]
	if progress >= target and not achievements[achievement_id]["unlocked"]:
		unlock_achievement(achievement_id)

## 获取成就列表
func get_achievements() -> Dictionary:
	"""获取成就列表"""
	return achievements.duplicate()

## 获取成就状态
func get_achievement_status(achievement_id: String) -> Dictionary:
	"""获取特定成就状态"""
	if achievements.has(achievement_id):
		return achievements[achievement_id].duplicate()
	return {}

# ============================================================
# 排行榜系统
# ============================================================

## 设置排行榜
func _setup_leaderboards() -> void:
	"""设置排行榜"""
	leaderboards = {
		"total_distance": {
			"name": "总徒步距离",
			"sort_method": "descending"
		},
		"total_elevation": {
			"name": "总累积爬升",
			"sort_method": "descending"
		},
		"total_games_won": {
			"name": "通关次数",
			"sort_method": "descending"
		},
		"max_combo": {
			"name": "最高连击",
			"sort_method": "descending"
		},
		"fastest_time": {
			"name": "最快通关",
			"sort_method": "ascending"
		}
	}

## 提交分数到排行榜
func submit_leaderboard_score(leaderboard_name: String, score: float) -> void:
	"""提交分数到排行榜"""
	if not is_steam_available:
		return
	
	if not leaderboards.has(leaderboard_name):
		push_error("[SteamManager] Leaderboard not found: %s" % leaderboard_name)
		return
	
	# TODO: 通过Steam API提交分数
	# Steam.upload_leaderboard_score(leaderboard_name, score)
	
	leaderboard_score_submitted.emit(leaderboard_name, true)
	
	print_debug("[SteamManager] Submitted score %.2f to leaderboard: %s" % [score, leaderboard_name])

## 获取排行榜分数
func get_leaderboard_scores(leaderboard_name: String, start: int = 0, count: int = 10) -> Array:
	"""获取排行榜分数"""
	# TODO: 通过Steam API获取排行榜分数
	# Steam.download_leaderboard_entries(leaderboard_name, start, count)
	return []

# ============================================================
# 云存档系统
# ============================================================

## 启用云存档
func enable_cloud_save(enable: bool) -> void:
	"""启用云存档"""
	cloud_save_enabled = enable
	
	# TODO: 通过Steam API设置云存档
	# Steam.set_cloud_enabled(enable)

## 检查云存档是否可用
func is_cloud_save_available() -> bool:
	"""检查云存档是否可用"""
	if not is_steam_available:
		return false
	
	# TODO: 通过Steam API检查云存档可用性
	# return Steam.is_cloud_enabled()
	return cloud_save_enabled

## 同步存档到云
func sync_save_to_cloud(save_data: Dictionary) -> bool:
	"""同步存档到云"""
	if not is_cloud_save_available():
		return false
	
	# TODO: 通过Steam API同步存档
	# var json_string = JSON.stringify(save_data)
	# Steam.file_write("save_data.json", json_string.to_ascii_buffer())
	
	return true

## 从云同步存档
func sync_save_from_cloud() -> Dictionary:
	"""从云同步存档"""
	if not is_cloud_save_available():
		return {}
	
	# TODO: 通过Steam API同步存档
	# var data = Steam.file_read("save_data.json")
	# var json_string = data.get_string_from_ascii()
	# var json = JSON.new()
	# json.parse(json_string)
	# return json.data
	
	return {}

# ============================================================
# DLC系统
# ============================================================

## 检查DLC
func check_dlc() -> void:
	"""检查DLC"""
	# TODO: 通过Steam API检查DLC
	# dlcs["expansion_pack"] = Steam.is_dlc_installed("EXPANSION_DLC_ID")
	# dlcs["skin_pack"] = Steam.is_dlc_installed("SKIN_PACK_ID")

## 检查DLC是否已安装
func is_dlc_installed(dlc_id: String) -> bool:
	"""检查DLC是否已安装"""
	# TODO: 通过Steam API检查DLC
	# return Steam.is_dlc_installed(dlc_id)
	return dlcs.get(dlc_id, false)

## 获取已安装DLC列表
func get_installed_dlcs() -> Array:
	"""获取已安装DLC列表"""
	var installed = []
	for dlc_id in dlcs:
		if dlcs[dlc_id]:
			installed.append(dlc_id)
	return installed

# ============================================================
# Steam商店
# ============================================================

## 打开Steam商店页面
func open_store_page(app_id: int = 0) -> void:
	"""打开Steam商店页面"""
	if not is_steam_available:
		return
	
	# TODO: 通过Steam API打开商店页面
	# Steam.activate_overlay_to_web_page("https://store.steampowered.com/app/%d" % app_id)
	
	# 备用方案：使用OS打开浏览器
	OS.shell_open("https://store.steampowered.com/app/%d" % app_id)

## 打开Steam社区页面
func open_community_page(app_id: int = 0) -> void:
	"""打开Steam社区页面"""
	if not is_steam_available:
		return
	
	# TODO: 通过Steam API打开社区页面
	# Steam.activate_overlay_to_web_page("https://steamcommunity.com/app/%d" % app_id)
	
	# 备用方案：使用OS打开浏览器
	OS.shell_open("https://steamcommunity.com/app/%d" % app_id)

# ============================================================
# Steam Overlay
# ============================================================

## 检查Steam Overlay是否可用
func is_overlay_available() -> bool:
	"""检查Steam Overlay是否可用"""
	if not is_steam_available:
		return false
	
	# TODO: 通过Steam API检查Overlay可用性
	# return Steam.is_overlay_enabled()
	return true

## 激活Steam Overlay
func activate_overlay() -> void:
	"""激活Steam Overlay"""
	if not is_overlay_available():
		return
	
	# TODO: 通过Steam API激活Overlay
	# Steam.activate_overlay()

## 打开Steam Overlay中的特定页面
func open_overlay_url(url: String) -> void:
	"""打开Steam Overlay中的URL"""
	if not is_overlay_available():
		return
	
	# TODO: 通过Steam API打开Overlay URL
	# Steam.activate_overlay_to_web_page(url)
	
	# 备用方案：使用OS打开浏览器
	OS.shell_open(url)

# ============================================================
# 统计数据
# ============================================================

## 上传统计数据
func upload_statistic(stat_name: String, value: float) -> void:
	"""上传统计数据到Steam"""
	if not is_steam_available:
		return
	
	# TODO: 通过Steam API上传统计数据
	# Steam.set_stat(stat_name, value)
	
	print_debug("[SteamManager] Uploaded statistic: %s = %.2f" % [stat_name, value])

## 下载统计数据
func download_statistic(stat_name: String) -> float:
	"""从Steam下载统计数据"""
	if not is_steam_available:
		return 0.0
	
	# TODO: 通过Steam API下载统计数据
	# return Steam.get_stat(stat_name)
	
	return 0.0

# ============================================================
# 游戏事件集成
# ============================================================

## 游戏启动
func on_game_started() -> void:
	"""游戏启动事件"""
	if is_steam_available:
		# TODO: 通过Steam API设置游戏状态
		# Steam.set_rich_presence("status", "正在徒步大湾区")
		print_debug("[SteamManager] Game started")

## 游戏暂停
func on_game_paused() -> void:
	"""游戏暂停事件"""
	if is_steam_available:
		# TODO: 通过Steam API设置游戏状态
		# Steam.set_rich_presence("status", "休息中")
		print_debug("[SteamManager] Game paused")

## 游戏结束
func on_game_ended(success: bool, result: Dictionary) -> void:
	"""游戏结束事件"""
	if is_steam_available:
		# 上传统计数据
		if result.has("distance"):
			upload_statistic("total_distance", result["distance"])
		if result.has("elevation_gain"):
			upload_statistic("total_elevation", result["elevation_gain"])
		
		# 提交排行榜
		if result.has("distance"):
			submit_leaderboard_score("total_distance", result["distance"])
		if result.has("elevation_gain"):
			submit_leaderboard_score("total_elevation", result["elevation_gain"])
		
		# 检查成就
		if success:
			_check_achievements(result)
		
		# TODO: 通过Steam API设置游戏状态
		# Steam.set_rich_presence("status", "已完成徒步")
		
		print_debug("[SteamManager] Game ended: %s" % ("Success" if success else "Failed"))

## 检查成就
func _check_achievements(result: Dictionary) -> void:
	"""检查并解锁成就"""
	# 第一次完成
	if SaveManager.get_player_data().get("total_games_won", 0) == 0:
		unlock_achievement("first_step")
	
	# 距离成就
	var total_distance = SaveManager.get_player_data().get("hiking_points", 0) / 2000.0
	update_achievement_progress("distance_10km", int(total_distance))
	update_achievement_progress("distance_100km", int(total_distance))
	
	# 爬升成就
	var total_elevation = SaveManager.get_player_data().get("elevation_gain", 0)
	update_achievement_progress("elevation_1000m", int(total_elevation))
	
	# 连击成就
	var max_combo = result.get("max_combo", 0)
	update_achievement_progress("combo_10", max_combo)
	
	# 环保成就
	var env_value = result.get("environmental_value", 0)
	update_achievement_progress("environmentalist", env_value)
