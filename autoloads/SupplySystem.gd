# ============================================================
# 脚本名称：SupplySystem
# 功能描述：补给系统 - 负责补给品管理、消耗与获取
# 版本号：v1.0
# 创建日期：2026年2月1日
# ============================================================

extends Node

## 信号定义
signal supplies_updated(supply_type: String, amount: int)
signal supply_consumed(supply_type: String, effect: Dictionary)

## 补给类型
const SUPPLY_WATER = "water"
const SUPPLY_SPORTS_DRINK = "sports_drink"
const SUPPLY_CHOCOLATE = "chocolate"

## 当前补给库存
var supplies: Dictionary = {
	SUPPLY_WATER: 0,
	SUPPLY_SPORTS_DRINK: 0,
	SUPPLY_CHOCOLATE: 0
}

## 补给效果配置
var supply_effects: Dictionary = {
	SUPPLY_WATER: {"thirst": -30, "fatigue": -5},
	SUPPLY_SPORTS_DRINK: {"thirst": -20, "energy": 10, "fatigue": -10},
	SUPPLY_CHOCOLATE: {"hunger": -20, "energy": 30}
}

## 初始化
func _ready() -> void:
	print_debug("[SupplySystem] Initialized")

## 添加补给
func add_supply(type: String, amount: int) -> void:
	if type in supplies:
		supplies[type] += amount
		supplies_updated.emit(type, supplies[type])
		print_debug("[SupplySystem] Added %d %s, New total: %d" % [amount, type, supplies[type]])

## 消耗补给
func consume_supply(type: String) -> bool:
	if type in supplies and supplies[type] > 0:
		supplies[type] -= 1
		var effect = supply_effects.get(type, {})
		
		# 这里需要调用AttributeSystem应用效果，暂时只发送信号
		supply_consumed.emit(type, effect)
		supplies_updated.emit(type, supplies[type])
		
		print_debug("[SupplySystem] Consumed %s, Effect: %s" % [type, effect])
		return true
	return false

## 获取补给数量
func get_supply_count(type: String) -> int:
	return supplies.get(type, 0)
