# ============================================================
# 脚本名称：EconomySystem
# 功能描述：经济系统 - 管理三种货币（徒步数、累积爬升、环保值）
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node

## 信号定义
signal currency_changed(currency_type: String, amount: int)
signal environmental_value_changed(amount: int)
signal insufficient_environmental_value(required: int, current: int)

## 货币常量
const ENV_VALUE_PER_WATER = 25
const ENV_VALUE_PER_SPORTS_DRINK = 50
const ENV_VALUE_PER_CHOCOLATE = 75
const ENV_VALUE_PER_ENERGY_BAR = 100
const ENV_VALUE_PER_BANANA = 60
const ENV_VALUE_PER_ELECTROLYTE = 80
const ENV_VALUE_PER_SUPPLY_PACK = 150
const ENV_VALUE_PER_PHOTO_PACK = 200

## 玩保数据
var player_data: Dictionary = {}

## 局内数据
var current_environmental_value: int = 0
var current_hiking_points: int = 0
var current_elevation_gain: float = 0.0

## 商店数据
var shop_items: Array = []

## 购买历史
var purchase_history: Array = []

## 补给需求
var required_supplies: Dictionary = {
	"water": 0,
	"sports_drink": 0,
	"chocolate": 0
}

## 已消耗补给
var consumed_supplies: Dictionary = {
	"water": 0,
	"sports_drink": 0,
	"chocolate": 0
}

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[EconomySystem] Initializing economy system...")
	_initialize_shop()
	print_debug("[EconomySystem] Economy system initialized")

## 初始化经济系统
func initialize() -> void:
	"""初始化经济系统（游戏开始时调用）"""
	# 从存档加载玩家数据
	player_data = SaveManager.get_player_data()
	
	# 重置局内数据
	current_environmental_value = 0
	current_hiking_points = 0
	current_elevation_gain = 0.0
	
	# 重置补给需求
	required_supplies = {
		"water": 0,
		"sports_drink": 0,
		"chocolate": 0
	}
	
	# 重置已消耗补给
	consumed_supplies = {
		"water": 0,
		"sports_drink": 0,
		"chocolate": 0
	}
	
	print_debug("[EconomySystem] Economy initialized")

## 初始化商店
func _initialize_shop() -> void:
	"""初始化商店物品"""
	shop_items = [
		{
			"id": "water",
			"name": "矿泉水",
			"description": "恢复口渴+20",
			"price": ENV_VALUE_PER_WATER,
			"category": "drink",
			"effects": {"thirst": 20}
		},
		{
			"id": "sports_drink",
			"name": "运动饮料",
			"description": "口渴+15，疲劳-5",
			"price": ENV_VALUE_PER_SPORTS_DRINK,
			"category": "drink",
			"effects": {"thirst": 15, "fatigue": -5}
		},
		{
			"id": "chocolate",
			"name": "巧克力",
			"description": "体能+15，饥饿+20",
			"price": ENV_VALUE_PER_CHOCOLATE,
			"category": "food",
			"effects": {"energy": 15, "hunger": 20}
		},
		{
			"id": "energy_bar",
			"name": "能量棒",
			"description": "体能+20，饥饿+15",
			"price": ENV_VALUE_PER_ENERGY_BAR,
			"category": "food",
			"effects": {"energy": 20, "hunger": 15}
		},
		{
			"id": "banana",
			"name": "香蕉",
			"description": "体能+10，钾元素+20",
			"price": ENV_VALUE_PER_BANANA,
			"category": "food",
			"effects": {"energy": 10}
		},
		{
			"id": "electrolyte",
			"name": "电解质水",
			"description": "口渴+30，心率-10",
			"price": ENV_VALUE_PER_ELECTROLYTE,
			"category": "drink",
			"effects": {"thirst": 30, "heart_rate": -10}
		},
		{
			"id": "supply_pack",
			"name": "运动补给包",
			"description": "综合补给",
			"price": ENV_VALUE_PER_SUPPLY_PACK,
			"category": "pack",
			"effects": {"thirst": 25, "energy": 20, "fatigue": -10}
		}
	]

# ============================================================
# 局外货币（徒步数、累积爬升）
# ============================================================

## 获取总徒步数
func get_total_hiking_points() -> int:
	"""获取玩家总徒步数"""
	return player_data.get("hiking_points", 0)

## 获取总累积爬升
func get_total_elevation_gain() -> float:
	"""获取玩家总累积爬升"""
	return player_data.get("elevation_gain", 0.0)

## 添加徒步数
func add_hiking_points(amount: int) -> void:
	"""添加徒步数（局内）"""
	current_hiking_points += amount
	player_data["hiking_points"] = get_total_hiking_points() + amount
	currency_changed.emit("hiking_points", get_total_hiking_points())
	print_debug("[EconomySystem] Added %d hiking points" % amount)

## 添加累积爬升
func add_elevation_gain(amount: float) -> void:
	"""添加累积爬升（局内）"""
	current_elevation_gain += amount
	player_data["elevation_gain"] = get_total_elevation_gain() + amount
	currency_changed.emit("elevation_gain", int(get_total_elevation_gain()))
	print_debug("[EconomySystem] Added %.0fm elevation gain" % amount)

## 支付徒步数
func spend_hiking_points(amount: int) -> bool:
	"""支付徒步数，返回是否成功"""
	if get_total_hiking_points() < amount:
		return false
	
	player_data["hiking_points"] = get_total_hiking_points() - amount
	currency_changed.emit("hiking_points", get_total_hiking_points())
	return true

## 支付累积爬升
func spend_elevation_gain(amount: float) -> bool:
	"""支付累积爬升，返回是否成功"""
	if get_total_elevation_gain() < amount:
		return false
	
	player_data["elevation_gain"] = get_total_elevation_gain() - amount
	currency_changed.emit("elevation_gain", int(get_total_elevation_gain()))
	return true

# ============================================================
# 局内货币（环保值）
# ============================================================

## 获取当前环保值
func get_environmental_value() -> int:
	"""获取当前局内环保值"""
	return current_environmental_value

## 添加环保值
func add_environmental_value(amount: int) -> void:
	"""添加环保值"""
	current_environmental_value += amount
	environmental_value_changed.emit(current_environmental_value)
	print_debug("[EconomySystem] Added %d environmental value" % amount)

## 消耗环保值
func spend_environmental_value(amount: int) -> bool:
	"""消耗环保值，返回是否成功"""
	if current_environmental_value < amount:
		insufficient_environmental_value.emit(amount, current_environmental_value)
		return false
	
	current_environmental_value -= amount
	environmental_value_changed.emit(current_environmental_value)
	return true

## 检查环保值是否充足
func check_environmental_value(amount: int) -> bool:
	"""检查环保值是否充足"""
	return current_environmental_value >= amount

# ============================================================
# 商店系统
# ============================================================

## 获取商店物品列表
func get_shop_items() -> Array:
	"""获取所有商店物品"""
	return shop_items

## 购买物品
func purchase_item(item_id: String) -> bool:
	"""购买物品，返回是否成功"""
	# 查找物品
	var item_data = null
	for item in shop_items:
		if item["id"] == item_id:
			item_data = item
			break
	
	if item_data == null:
		push_error("[EconomySystem] Item not found: %s" % item_id)
		return false
	
	# 检查环保值
	if not spend_environmental_value(item_data["price"]):
		return false
	
	# 应用效果
	_apply_item_effects(item_data["effects"])
	
	# 记录购买历史
	purchase_history.append({
		"item_id": item_id,
		"price": item_data["price"],
		"timestamp": Time.get_unix_time_from_system()
	})
	
	print_debug("[EconomySystem] Purchased item: %s" % item_id)
	return true

## 应用物品效果
func _apply_item_effects(effects: Dictionary) -> void:
	"""应用物品效果到属性系统"""
	for effect_name in effects:
		var value = effects[effect_name]
		
		match effect_name:
			"thirst":
				AttributeSystem.recover_thirst(float(value))
			"hunger":
				AttributeSystem.recover_hunger(float(value))
			"energy":
				AttributeSystem.recover_energy(float(value))
			"fatigue":
				AttributeSystem.reduce_fatigue(float(abs(value)) if value < 0 else -float(value))
			"heart_rate":
				AttributeSystem.decrease_heart_rate(int(abs(value)) if value < 0 else -int(value))

# ============================================================
# 补给系统
# ============================================================

## 更新补给需求
func update_supply_requirements(distance: float) -> void:
	"""根据徒步距离更新补给需求"""
	# 每10公里需要2水+1运动饮料+1巧克力
	required_supplies["water"] = int(distance / 5.0)
	required_supplies["sports_drink"] = int(distance / 10.0)
	required_supplies["chocolate"] = int(distance / 10.0)
	
	print_debug("[EconomySystem] Supply requirements updated: %s" % required_supplies)

## 检查补给是否充足
func check_supply_adequacy() -> Dictionary:
	"""检查补给是否充足"""
	return {
		"water": {
			"required": required_supplies["water"],
			"consumed": consumed_supplies["water"],
			"adequate": consumed_supplies["water"] >= required_supplies["water"]
		},
		"sports_drink": {
			"required": required_supplies["sports_drink"],
			"consumed": consumed_supplies["sports_drink"],
			"adequate": consumed_supplies["sports_drink"] >= required_supplies["sports_drink"]
		},
		"chocolate": {
			"required": required_supplies["chocolate"],
			"consumed": consumed_supplies["chocolate"],
			"adequate": consumed_supplies["chocolate"] >= required_supplies["chocolate"]
		}
	}

## 记录消耗补给
func record_consumed_supply(item_id: String) -> void:
	"""记录消耗的补给"""
	match item_id:
		"water":
			consumed_supplies["water"] += 1
		"sports_drink":
			consumed_supplies["sports_drink"] += 1
		"chocolate", "energy_bar":
			consumed_supplies["chocolate"] += 1

## 获取补给不足警告
func get_supply_warning() -> String:
	"""获取补给不足警告信息"""
	var supply_status = check_supply_adequacy()
	var warnings = []
	
	if not supply_status["water"]["adequate"]:
		warnings.append("水不足（需要%d瓶，已消耗%d瓶）" % [
			supply_status["water"]["required"],
			supply_status["water"]["consumed"]
		])
	
	if not supply_status["sports_drink"]["adequate"]:
		warnings.append("运动饮料不足（需要%d瓶，已消耗%d瓶）" % [
			supply_status["sports_drink"]["required"],
			supply_status["sports_drink"]["consumed"]
		])
	
	if not supply_status["chocolate"]["adequate"]:
		warnings.append("巧克力不足（需要%d次，已消耗%d次）" % [
			supply_status["chocolate"]["required"],
			supply_status["chocolate"]["consumed"]
		])
	
	return "\n".join(warnings)

# ============================================================
# 局内统计
# ============================================================

## 获取局内统计
func get_session_statistics() -> Dictionary:
	"""获取当前局内统计数据"""
	return {
		"hiking_points": current_hiking_points,
		"elevation_gain": current_elevation_gain,
		"environmental_value": current_environmental_value,
		"supplies_consumed": consumed_supplies.duplicate(),
		"purchase_count": purchase_history.size()
	}

## 重置局内数据
func reset_session() -> void:
	"""重置局内数据"""
	current_environmental_value = 0
	current_hiking_points = 0
	current_elevation_gain = 0.0
	required_supplies = {"water": 0, "sports_drink": 0, "chocolate": 0}
	consumed_supplies = {"water": 0, "sports_drink": 0, "chocolate": 0}
	purchase_history.clear()
