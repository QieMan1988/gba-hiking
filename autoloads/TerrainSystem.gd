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
const TERRAIN_STAIRS_UP = "stairs_up"
const TERRAIN_STAIRS_DOWN = "stairs_down"
const TERRAIN_CLIFF = "cliff"

## 膝盖健康度
var max_knee_health: float = 100.0
var current_knee_health: float = 100.0

## 当前地形
var current_terrain_type: String = TERRAIN_FLAT

## 初始化
func _ready() -> void:
	print_debug("[TerrainSystem] Initialized")

func set_current_terrain(terrain_type: String) -> void:
	if current_terrain_type == terrain_type:
		return
	current_terrain_type = terrain_type
	terrain_changed.emit(current_terrain_type)
	print_debug("[TerrainSystem] Terrain changed: %s" % current_terrain_type)

func get_current_terrain() -> String:
	return current_terrain_type

## 计算地形对移动速度的影响
func get_speed_modifier(terrain_type: String) -> float:
	var modifier: float = 1.0
	match terrain_type:
		TERRAIN_FLAT:
			modifier = 1.0
		TERRAIN_GENTLE_UP:
			modifier = 0.8
		TERRAIN_STEEP_UP:
			modifier = 0.5
		TERRAIN_GENTLE_DOWN:
			modifier = 1.2
		TERRAIN_STEEP_DOWN:
			modifier = 0.7
		TERRAIN_STAIRS_UP:
			modifier = 0.6
		TERRAIN_STAIRS_DOWN:
			modifier = 0.8
		TERRAIN_CLIFF:
			modifier = 0.2
		_:
			modifier = 1.0
	return modifier

func get_elevation_gain(terrain_type: String, distance: float) -> float:
	var gain_per_km = 0.0
	match terrain_type:
		TERRAIN_GENTLE_UP: gain_per_km = 50.0
		TERRAIN_STEEP_UP: gain_per_km = 150.0
		TERRAIN_STAIRS_UP: gain_per_km = 200.0
		TERRAIN_CLIFF: gain_per_km = 300.0
		_: gain_per_km = 0.0
	return gain_per_km * distance

## 计算膝盖损伤
func calculate_knee_damage(terrain_type: String, distance: float) -> float:
	var damage_per_km = 0.0
	match terrain_type:
		TERRAIN_GENTLE_DOWN: damage_per_km = 2.0
		TERRAIN_STEEP_DOWN: damage_per_km = 5.0
		TERRAIN_STAIRS_DOWN: damage_per_km = 8.0
		TERRAIN_STAIRS_UP: damage_per_km = 3.0
		TERRAIN_CLIFF: damage_per_km = 10.0
		_: damage_per_km = 0.0

	var damage = damage_per_km * distance
	apply_knee_damage(damage)
	return damage

## 应用膝盖损伤
func apply_knee_damage(amount: float) -> void:
	if amount <= 0: return
	current_knee_health = max(0.0, current_knee_health - amount)
	knee_damage_taken.emit(amount, current_knee_health)
	var message = "[TerrainSystem] Knee damage taken: %.1f, Current: %.1f" % [
		amount,
		current_knee_health
	]
	print_debug(message)
