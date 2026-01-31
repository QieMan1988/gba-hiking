# ============================================================
# 脚本名称：TerrainSystem
# 功能描述：地形系统 - 负责地形管理、坡度计算、膝盖损伤机制
# 版本号：v1.0
# 创建日期：2026年2月1日
# ============================================================

extends Node

## 信号定义
signal terrain_changed(new_terrain: String)
signal knee_damage_taken(amount: float, current_health: float)

## 地形类型常量
const TERRAIN_FLAT = "flat"
const TERRAIN_GENTLE_UP = "gentle_up"
const TERRAIN_STEEP_UP = "steep_up"
const TERRAIN_GENTLE_DOWN = "gentle_down"
const TERRAIN_STEEP_DOWN = "steep_down"
const TERRAIN_CLIFF = "cliff"

## 膝盖健康度
var max_knee_health: float = 100.0
var current_knee_health: float = 100.0

## 初始化
func _ready() -> void:
	print_debug("[TerrainSystem] Initialized")

## 计算地形对移动速度的影响
func get_speed_modifier(terrain_type: String) -> float:
	match terrain_type:
		TERRAIN_FLAT: return 1.0
		TERRAIN_GENTLE_UP: return 0.8
		TERRAIN_STEEP_UP: return 0.5
		TERRAIN_GENTLE_DOWN: return 1.2
		TERRAIN_STEEP_DOWN: return 0.7 # 下坡太陡需要小心
		TERRAIN_CLIFF: return 0.2
		_: return 1.0

## 计算膝盖损伤
func calculate_knee_damage(terrain_type: String, distance: float) -> float:
	var damage_per_km = 0.0
	match terrain_type:
		TERRAIN_GENTLE_DOWN: damage_per_km = 2.0
		TERRAIN_STEEP_DOWN: damage_per_km = 5.0
		TERRAIN_CLIFF: damage_per_km = 10.0 # 假设悬崖下行
		_: damage_per_km = 0.0
	
	var damage = damage_per_km * distance
	apply_knee_damage(damage)
	return damage

## 应用膝盖损伤
func apply_knee_damage(amount: float) -> void:
	if amount <= 0: return
	current_knee_health = max(0.0, current_knee_health - amount)
	knee_damage_taken.emit(amount, current_knee_health)
	print_debug("[TerrainSystem] Knee damage taken: %.1f, Current: %.1f" % [amount, current_knee_health])
