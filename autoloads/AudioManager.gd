# ============================================================
# 脚本名称：AudioManager
# 功能描述：音频管理器 - 管理背景音乐、音效、音量控制
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node
class_name AudioManager

## 音频播放器
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

## 音频资源
var bgm_resources: Dictionary = {}
var sfx_resources: Dictionary = {}

## 音量设置
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0
var master_volume: float = 1.0

## 当前播放的BGM
var current_bgm_name: String = ""

## 音频总线
var master_bus: int
var bgm_bus: int
var sfx_bus: int

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[AudioManager] Initializing audio manager...")
	_setup_audio_players()
	_setup_audio_buses()
	_load_audio_resources()
	_load_volume_settings()
	print_debug("[AudioManager] Audio manager initialized")

## 设置音频播放器
func _setup_audio_players() -> void:
	"""设置音频播放器"""
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
	bgm_player.volume_db = linear_to_db(bgm_volume)
	add_child(bgm_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	sfx_player.volume_db = linear_to_db(sfx_volume)
	add_child(sfx_player)

## 设置音频总线
func _setup_audio_buses() -> void:
	"""设置音频总线"""
	var idx = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, "Master")
	master_bus = idx
	
	idx = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, "BGM")
	AudioServer.set_bus_volume_db(idx, linear_to_db(bgm_volume))
	bgm_bus = idx
	
	idx = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, "SFX")
	AudioServer.set_bus_volume_db(idx, linear_to_db(sfx_volume))
	sfx_bus = idx

## 加载音频资源
func _load_audio_resources() -> void:
	"""加载音频资源"""
	# BGM资源
	bgm_resources = {
		"main_menu": preload("res://assets/audio/bgm/main_menu.ogg"),
		"battle": preload("res://assets/audio/bgm/battle.ogg"),
		"result": preload("res://assets/audio/bgm/result.ogg"),
		"shop": preload("res://assets/audio/bgm/shop.ogg")
	}
	
	# SFX资源
	sfx_resources = {
		"card_click": preload("res://assets/audio/sfx/card_click.ogg"),
		"card_cross": preload("res://assets/audio/sfx/card_cross.ogg"),
		"combo": preload("res://assets/audio/sfx/combo.ogg"),
		"terrain_flat": preload("res://assets/audio/sfx/terrain_flat.ogg"),
		"terrain_slope": preload("res://assets/audio/sfx/terrain_slope.ogg"),
		"terrain_cliff": preload("res://assets/audio/sfx/terrain_cliff.ogg"),
		"rest": preload("res://assets/audio/sfx/rest.ogg"),
		"shop_buy": preload("res://assets/audio/sfx/shop_buy.ogg"),
		"error": preload("res://assets/audio/sfx/error.ogg"),
		"game_over": preload("res://assets/audio/sfx/game_over.ogg"),
		"victory": preload("res://assets/audio/sfx/victory.ogg")
	}

## 加载音量设置
func _load_volume_settings() -> void:
	"""从存档加载音量设置"""
	var player_data = SaveManager.get_player_data()
	var settings = player_data.get("settings", {})
	
	master_volume = settings.get("master_volume", 1.0)
	bgm_volume = settings.get("bgm_volume", 0.8)
	sfx_volume = settings.get("sfx_volume", 1.0)
	
	_update_bus_volumes()

# ============================================================
# BGM控制
# ============================================================

## 播放BGM
func play_bgm(bgm_name: String, fade_in: bool = true) -> void:
	"""播放背景音乐"""
	if bgm_name == current_bgm_name and bgm_player.playing:
		return
	
	if not bgm_resources.has(bgm_name):
		push_error("[AudioManager] BGM not found: %s" % bgm_name)
		return
	
	bgm_player.stream = bgm_resources[bgm_name]
	
	if fade_in:
		bgm_player.volume_db = -80.0
		bgm_player.play()
		_fade_in_bgm()
	else:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
		bgm_player.play()
	
	current_bgm_name = bgm_name
	
	print_debug("[AudioManager] Playing BGM: %s" % bgm_name)

## 停止BGM
func stop_bgm(fade_out: bool = true) -> void:
	"""停止背景音乐"""
	if fade_out:
		_fade_out_bgm()
	else:
		bgm_player.stop()
		current_bgm_name = ""

## 淡入BGM
func _fade_in_bgm() -> void:
	"""淡入背景音乐"""
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", linear_to_db(bgm_volume * master_volume), 1.0)

## 淡出BGM
func _fade_out_bgm() -> void:
	"""淡出背景音乐"""
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -80.0, 0.5)
	tween.tween_callback(bgm_player.stop)

## 暂停BGM
func pause_bgm() -> void:
	"""暂停背景音乐"""
	bgm_player.paused = true

## 恢复BGM
func resume_bgm() -> void:
	"""恢复背景音乐"""
	bgm_player.paused = false

# ============================================================
# SFX控制
# ============================================================

## 播放音效
func play_sfx(sfx_name: String, pitch_scale: float = 1.0) -> void:
	"""播放音效"""
	if not sfx_resources.has(sfx_name):
		push_error("[AudioManager] SFX not found: %s" % sfx_name)
		return
	
	# 如果有音效正在播放，创建新的播放器
	if sfx_player.playing:
		var new_player = AudioStreamPlayer.new()
		new_player.bus = "SFX"
		new_player.volume_db = linear_to_db(sfx_volume * master_volume)
		new_player.stream = sfx_resources[sfx_name]
		new_player.pitch_scale = pitch_scale
		add_child(new_player)
		new_player.play()
		new_player.finished.connect(new_player.queue_free)
	else:
		sfx_player.stream = sfx_resources[sfx_name]
		sfx_player.pitch_scale = pitch_scale
		sfx_player.play()

## 停止音效
func stop_sfx() -> void:
	"""停止音效"""
	sfx_player.stop()

# ============================================================
# 音量控制
# ============================================================

## 设置主音量
func set_master_volume(volume: float) -> void:
	"""设置主音量（0.0-1.0）"""
	master_volume = clampf(volume, 0.0, 1.0)
	_update_bus_volumes()
	_save_volume_settings()

## 设置BGM音量
func set_bgm_volume(volume: float) -> void:
	"""设置BGM音量（0.0-1.0）"""
	bgm_volume = clampf(volume, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	_save_volume_settings()

## 设置SFX音量
func set_sfx_volume(volume: float) -> void:
	"""设置SFX音量（0.0-1.0）"""
	sfx_volume = clampf(volume, 0.0, 1.0)
	sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
	_save_volume_settings()

## 更新总线音量
func _update_bus_volumes() -> void:
	"""更新所有总线音量"""
	AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(bgm_volume * master_volume))
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume * master_volume))
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)

## 保存音量设置
func _save_volume_settings() -> void:
	"""保存音量设置到存档"""
	var player_data = SaveManager.get_player_data()
	var settings = player_data.get("settings", {})
	
	settings["master_volume"] = master_volume
	settings["bgm_volume"] = bgm_volume
	settings["sfx_volume"] = sfx_volume
	
	player_data["settings"] = settings
	SaveManager.save_player_data()

## 获取主音量
func get_master_volume() -> float:
	"""获取主音量"""
	return master_volume

## 获取BGM音量
func get_bgm_volume() -> float:
	"""获取BGM音量"""
	return bgm_volume

## 获取SFX音量
func get_sfx_volume() -> float:
	"""获取SFX音量"""
	return sfx_volume

# ============================================================
# 快捷音效播放
# ============================================================

## 播放卡牌点击音效
func play_card_click() -> void:
	"""播放卡牌点击音效"""
	play_sfx("card_click")

## 播放卡牌穿越音效
func play_card_cross() -> void:
	"""播放卡牌穿越音效"""
	play_sfx("card_cross")

## 播放连击音效
func play_combo(combo_count: int) -> void:
	"""播放连击音效（根据连击数调整音调）"""
	var pitch = 1.0 + (combo_count * 0.1)
	play_sfx("combo", pitch)

## 播放地形音效
func play_terrain_sound(terrain_type: String) -> void:
	"""播放地形音效"""
	match terrain_type:
		"flat":
			play_sfx("terrain_flat")
		"gentle_up", "gentle_down":
			play_sfx("terrain_slope")
		"steep_up", "steep_down", "cliff":
			play_sfx("terrain_cliff")

## 播放休息音效
func play_rest() -> void:
	"""播放休息音效"""
	play_sfx("rest")

## 播放商店购买音效
func play_shop_buy() -> void:
	"""播放商店购买音效"""
	play_sfx("shop_buy")

## 播放错误音效
func play_error() -> void:
	"""播放错误音效"""
	play_sfx("error")

## 播放游戏结束音效
func play_game_over() -> void:
	"""播放游戏结束音效"""
	play_sfx("game_over")

## 播放胜利音效
func play_victory() -> void:
	"""播放胜利音效"""
	play_sfx("victory")
