# ============================================================
# 脚本名称：Battle_Scene
# 功能描述：战斗场景逻辑控制
# 版本号：v1.1
# 创建日期：2026年2月3日
# ============================================================

class_name BattleScene
extends Node2D

func _ready() -> void:
	print("[BattleScene] Scene Ready")
	
	# 初始化游戏系统
	# 确保 GameManager 知道战斗已经开始
	if GameManager.has_method("start_level"):
		# 如果是直接运行此场景（测试用），提供默认关卡ID
		var level_id = "level_001" 
		if GameManager.current_level_config.has("id"):
			level_id = GameManager.current_level_config["id"]
		
		# 开始关卡逻辑
		GameManager.start_level(level_id)
	else:
		# Fallback: 手动触发卡牌系统初始化
		print("[BattleScene] Initializing CardSystem manually")
		CardSystem.initialize_level("level_001")
	
	# 播放背景音乐
	if AudioManager:
		AudioManager.play_music("battle_theme")
