# ============================================================
# 脚本名称：CardSystem
# 功能描述：卡牌系统 - 管理卡牌生成、穿越、效果
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node

## 信号定义
signal card_spawned(card_data: Dictionary, layer_index: int, position: int)
signal card_crossed(card_data: Dictionary, combo_count: int)
signal card_effect_triggered(card_data: Dictionary, effect_type: String)
signal layer_completed(layer_index: int)

## 卡牌数据
var current_cards: Dictionary = {}  # {layer_index: [card_data, ...]}
var current_combo_count: int = 0
var current_combo_chain: Array = []

## 翻越定时器
var traverse_timer: Timer

## 穿越状态
var is_traversing: bool = false

## 上次穿越卡牌类型
var last_crossed_card_type: String = ""

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[CardSystem] Initializing card system...")
	_setup_traverse_timer()
	print_debug("[CardSystem] Card system initialized")

## 初始化卡牌系统
func initialize() -> void:
	"""初始化卡牌系统（游戏开始时调用）"""
	current_cards.clear()
	current_combo_count = 0
	current_combo_chain.clear()
	is_traversing = false
	last_crossed_card_type = ""

	# 生成所有层级的卡牌
	_generate_all_layers_cards()

	print_debug("[CardSystem] Cards generated for %d layers" % current_cards.size())

## 设置翻越定时器
func _setup_traverse_timer() -> void:
	"""设置翻越定时器"""
	traverse_timer = Timer.new()
	traverse_timer.wait_time = 1.5  # 默认翻越时间
	traverse_timer.one_shot = true
	traverse_timer.timeout.connect(_on_traverse_completed)
	add_child(traverse_timer)

# ============================================================
# 卡牌生成
# ============================================================

## 生成所有层级的卡牌
func _generate_all_layers_cards() -> void:
	"""生成所有层级的卡牌"""
	var total_layers = GameManager.total_layers
	var layers_config = GameManager.current_level_config.get("layers", [])

	for layer_index in range(total_layers):
		var layer_config = {}
		if layer_index < layers_config.size():
			layer_config = layers_config[layer_index]
		_generate_layer_cards(layer_index, total_layers, layer_config)

## 生成单层卡牌
func _generate_layer_cards(
	layer_index: int,
	total_layers: int,
	layer_config: Dictionary = {}
) -> void:
	"""生成特定层级的卡牌"""
	var is_last_layer = layer_index == total_layers - 1

	var card_count = _get_card_count_for_layer(layer_index, layer_config)
	var cards = []

	for i in range(card_count):
		var card_data = _generate_single_card(layer_index, i, is_last_layer, layer_config)
		cards.append(card_data)
		card_spawned.emit(card_data, layer_index, i)

	current_cards[layer_index] = cards

	print_debug("[CardSystem] Generated %d cards for layer %d" % [card_count, layer_index])

## 获取层级卡牌数量
func _get_card_count_for_layer(layer_index: int, layer_config: Dictionary = {}) -> int:
	"""获取特定层级的卡牌数量"""
	if layer_config.has("card_count"):
		return int(layer_config["card_count"])

	# 倒金字塔：底部多，顶部少
	var base_count = 4
	var decrease = layer_index * 0.5
	return maxi(1, int(base_count - decrease))

## 生成单张卡牌
func _generate_single_card(
	layer_index: int,
	position: int,
	is_last_layer: bool,
	layer_config: Dictionary = {}
) -> Dictionary:
	"""生成单张卡牌数据"""
	var card_type = _determine_card_type(position, is_last_layer)
	var card_data = _create_card_data(card_type, layer_index, layer_config)

	return card_data

## 确定卡牌类型
func _determine_card_type(position: int, is_last_layer: bool) -> String:
	"""确定卡牌类型"""
	var weights = {
		"scenery": 0.4,
		"terrain": 0.3,
		"resource": 0.2,
		"environment": 0.1
	}

	# 顶层必须是风景卡（山顶奖励卡）
	if is_last_layer:
		return "scenery_summit"

	# 确保至少一张风景卡
	if position == 0:
		return "scenery"

	# 避免连续3张同类型卡
	if current_combo_chain.size() >= 2:
		var last_type = current_combo_chain[current_combo_chain.size() - 1]
		var prev_type = current_combo_chain[current_combo_chain.size() - 2]
		if last_type == prev_type:
			weights[last_type] *= 0.2  # 降低重复类型权重

	# 根据权重随机选择
	var total_weight = 0.0
	for weight in weights.values():
		total_weight += weight

	var random_value = randf() * total_weight
	var cumulative_weight = 0.0

	for card_type in weights:
		cumulative_weight += weights[card_type]
		if random_value <= cumulative_weight:
			return card_type

	return "scenery"

## 创建卡牌数据
func _create_card_data(
	card_type: String,
	layer_index: int,
	layer_config: Dictionary = {}
) -> Dictionary:
	"""创建卡牌数据"""
	var terrain_type = GameManager.current_terrain_type
	var card_data = {
		"id": "%s_%d_%d" % [card_type, layer_index, randi()],
		"type": card_type,
		"layer_index": layer_index,
		"terrain_type": terrain_type,
		"effects": {}
	}

	# 存储层级元数据（海拔等）
	if layer_config.has("altitude"):
		card_data["altitude"] = layer_config["altitude"]

	# 根据类型设置效果
	match card_type:
		"scenery", "scenery_summit":
			card_data["name"] = "风景卡" if card_type != "scenery_summit" else "山顶奖励卡"
			card_data["description"] = "风景优美" if card_type != "scenery_summit" else "到达山顶！"
			card_data["effects"]["environmental_value"] = 25 if card_type != "scenery_summit" else 100
			card_data["effects"]["interaction_type"] = "click"
		"terrain":
			var terrain_info = _get_terrain_info(terrain_type)
			card_data["name"] = terrain_info["name"]
			card_data["description"] = terrain_info["description"]
			card_data["effects"]["energy_cost"] = terrain_info["energy_cost"]
			card_data["effects"]["fatigue_gain"] = terrain_info.get("fatigue_gain", 0)
			card_data["effects"]["elevation_gain"] = terrain_info.get("elevation_gain", 0)
			card_data["effects"]["traverse_time"] = terrain_info.get("traverse_time", 1.5)
			card_data["effects"]["heart_rate_increase"] = terrain_info.get("heart_rate_increase", 0)
			if terrain_info.has("interaction_type"):
				card_data["effects"]["interaction_type"] = terrain_info["interaction_type"]
			else:
				card_data["effects"]["interaction_type"] = "click"
		"resource":
			var resource_id = _random_resource()
			var resource_data = _get_resource_data(resource_id)
			card_data["name"] = resource_data["name"]
			card_data["description"] = resource_data["description"]
			card_data["resource_id"] = resource_id
			card_data["effects"] = resource_data["effects"]
			card_data["effects"]["interaction_type"] = "click"
		"environment":
			var env_id = _random_environment()
			var env_data = _get_environment_data(env_id)
			card_data["name"] = env_data["name"]
			card_data["description"] = env_data["description"]
			card_data["effects"] = env_data["effects"]
			card_data["effects"]["interaction_type"] = "click"

	return card_data

## 获取地形信息
func _get_terrain_info(terrain_type: String) -> Dictionary:
	"""获取地形信息"""
	var terrain_info = {
		"flat": {
			"name": "平坦道路",
			"description": "轻松通过",
			"energy_cost": 5.0,
			"fatigue_gain": 0.5,
			"elevation_gain": 0.0,
			"traverse_time": 0.5,
			"heart_rate_increase": 0
		},
		"gentle_up": {
			"name": "缓坡上坡",
			"description": "略微费力",
			"energy_cost": 10.5,
			"fatigue_gain": 1.5,
			"elevation_gain": 50.0,
			"traverse_time": 1.5,
			"heart_rate_increase": 5
		},
		"steep_up": {
			"name": "陡坡",
			"description": "费力",
			"energy_cost": 22.5,
			"fatigue_gain": 3.0,
			"elevation_gain": 150.0,
			"traverse_time": 2.5,
			"heart_rate_increase": 10,
			"interaction_type": "long_press"
		},
		"cliff": {
			"name": "悬崖栈道",
			"description": "小心脚下",
			"energy_cost": 35.0,
			"fatigue_gain": 5.0,
			"elevation_gain": 300.0,
			"traverse_time": 3.0,
			"heart_rate_increase": 15,
			"requires_confirmation": true,
			"interaction_type": "confirm"
		},
		"gentle_down": {
			"name": "缓坡下坡",
			"description": "轻松",
			"energy_cost": 4.0,
			"fatigue_gain": 0.0,
			"elevation_gain": 0.0,
			"traverse_time": 0.3,
			"heart_rate_increase": 0
		},
		"steep_down": {
			"name": "陡坡下坡",
			"description": "注意膝盖",
			"energy_cost": 3.0,
			"fatigue_gain": 0.0,
			"elevation_gain": 0.0,
			"traverse_time": 0.5,
			"heart_rate_increase": 0,
			"knee_injury_risk": 0.1
		}
	}

	return terrain_info.get(terrain_type, terrain_info["flat"])

## 随机资源
func _random_resource() -> String:
	"""随机选择一种资源"""
	var resources = ["water", "energy_bar", "banana"]
	return resources[randi() % resources.size()]

## 获取资源数据
func _get_resource_data(resource_id: String) -> Dictionary:
	"""获取资源数据"""
	var resource_data = {
		"water": {
			"name": "矿泉水",
			"description": "恢复口渴+20",
			"effects": {"thirst_recovery": 20}
		},
		"energy_bar": {
			"name": "能量棒",
			"description": "恢复体能+20，饥饿+15",
			"effects": {"energy_recovery": 20, "hunger_recovery": 15}
		},
		"banana": {
			"name": "香蕉",
			"description": "恢复体能+10",
			"effects": {"energy_recovery": 10}
		}
	}

	return resource_data.get(resource_id, resource_data["water"])

## 随机环境事件
func _random_environment() -> String:
	"""随机选择一种环境事件"""
	var environments = ["trash", "recycling", "nature"]
	return environments[randi() % environments.size()]

## 获取环境事件数据
func _get_environment_data(env_id: String) -> Dictionary:
	"""获取环境事件数据"""
	var env_data = {
		"trash": {
			"name": "清理垃圾",
			"description": "环保行动",
			"effects": {"environmental_value": 15, "energy_cost": 2}
		},
		"recycling": {
			"name": "垃圾分类",
			"description": "环保行动",
			"effects": {"environmental_value": 20, "energy_cost": 1}
		},
		"nature": {
			"name": "保护自然",
			"description": "环保行动",
			"effects": {"environmental_value": 25, "energy_cost": 3}
		}
	}

	return env_data.get(env_id, env_data["trash"])

# ============================================================
# 卡牌穿越
# ============================================================

## 尝试穿越卡牌
func attempt_traverse_card(card_id: String) -> bool:
	"""尝试穿越卡牌，返回是否成功"""
	if is_traversing:
		print_debug("[CardSystem] Already traversing")
		return false

	# 查找卡牌
	var card_data = _find_card_by_id(card_id)
	if card_data == null:
		push_error("[CardSystem] Card not found: %s" % card_id)
		return false

	# 检查是否需要确认
	if card_data["effects"].get("requires_confirmation", false):
		# 显示确认对话框
		UIManager.show_confirmation_dialog(
			"确认翻越悬崖栈道？\n\n这可能比较危险...",
			_card_confirmation_callback.bind(card_id)
		)
		return false

	# 开始穿越
	_start_traverse(card_data)
	return true

## 卡牌确认回调
func _card_confirmation_callback(card_id: String, confirmed: bool) -> void:
	"""卡牌确认回调"""
	if not confirmed:
		return

	var card_data = _find_card_by_id(card_id)
	if card_data != null:
		_start_traverse(card_data)

## 开始穿越
func _start_traverse(card_data: Dictionary) -> void:
	"""开始穿越卡牌"""
	is_traversing = true

	# 设置恐惧状态（悬崖栈道）
	if card_data["type"] == "terrain" and card_data["terrain_type"] == "cliff":
		AttributeSystem.set_fear_state(true, 3.0)

	# 设置翻越时间
	var traverse_time = card_data["effects"].get("traverse_time", 1.5)
	traverse_timer.wait_time = traverse_time
	traverse_timer.start()

	# 播放穿越动画
	UIManager.play_traverse_animation(card_data)
	var traverse_message = "[CardSystem] Started traversing card: %s (time: %.1fs)" % [
		card_data["id"],
		traverse_time
	]
	print_debug(traverse_message)

## 穿越完成回调
func _on_traverse_completed() -> void:
	"""穿越完成回调"""
	if not is_traversing:
		return

	# 获取当前穿越的卡牌（简化处理）
	var current_layer = GameManager.current_layer_index
	var cards = current_cards.get(current_layer, [])
	if cards.is_empty():
		is_traversing = false
		return

	var card_data = cards[0]  # 假设穿越第一张卡牌

	# 应用卡牌效果
	_apply_card_effects(card_data)

	# 更新连击
	_update_combo(card_data)

	# 发送信号
	card_crossed.emit(card_data, current_combo_count)

	# 移除卡牌
	_remove_card_from_layer(current_layer, card_data["id"])

	# 检查层级是否完成
	if current_cards.get(current_layer, []).is_empty():
		layer_completed.emit(current_layer)
		GameManager.advance_to_next_layer()

	is_traversing = false

	print_debug("[CardSystem] Traversed card: %s, combo: %d" % [card_data["id"], current_combo_count])

## 应用卡牌效果
func _apply_card_effects(card_data: Dictionary) -> void:
	"""应用卡牌效果"""
	var effects = card_data["effects"]

	# 消耗体能
	if effects.has("energy_cost"):
		var success = AttributeSystem.apply_attribute_delta(
			"energy",
			-float(effects["energy_cost"])
		)
		if not success:
			return

	# 增加疲劳
	if effects.has("fatigue_gain"):
		AttributeSystem.apply_attribute_delta(
			"fatigue",
			float(effects["fatigue_gain"])
		)

	# 增加累积爬升
	if effects.has("elevation_gain"):
		var elevation_gain = effects["elevation_gain"]
		EconomySystem.add_elevation_gain(elevation_gain)

	# 增加心率
	if effects.has("heart_rate_increase"):
		AttributeSystem.apply_attribute_delta(
			"heart_rate",
			float(effects["heart_rate_increase"])
		)

	# 恢复属性
	if effects.has("energy_recovery"):
		AttributeSystem.apply_attribute_delta(
			"energy",
			float(effects["energy_recovery"])
		)
	if effects.has("thirst_recovery"):
		AttributeSystem.apply_attribute_delta(
			"thirst",
			-float(effects["thirst_recovery"])
		)
	if effects.has("hunger_recovery"):
		AttributeSystem.apply_attribute_delta(
			"hunger",
			-float(effects["hunger_recovery"])
		)

	# 环保值
	if effects.has("environmental_value"):
		EconomySystem.add_environmental_value(effects["environmental_value"])

	# 膝盖受伤检查
	if effects.has("knee_injury_risk"):
		var risk = effects["knee_injury_risk"]
		if randf() < risk:
			AttributeSystem.set_knee_injury(true)

	# 发送效果触发信号
	for effect_type in effects:
		card_effect_triggered.emit(card_data, effect_type)

## 更新连击
func _update_combo(card_data: Dictionary) -> void:
	"""更新连击计数"""
	var card_type = card_data["type"]

	# 风景卡连击
	if card_type == "scenery" or card_type == "scenery_summit":
		if last_crossed_card_type == "scenery" or last_crossed_card_type == "scenery_summit":
			current_combo_count += 1
		else:
			current_combo_count = 1
	else:
		current_combo_count = 0

	last_crossed_card_type = card_type
	current_combo_chain.append(card_type)

	if current_combo_chain.size() > 5:
		current_combo_chain.pop_front()

## 从层级移除卡牌
func _remove_card_from_layer(layer_index: int, card_id: String) -> void:
	"""从层级移除卡牌"""
	var cards = current_cards.get(layer_index, [])
	for i in range(cards.size()):
		if cards[i]["id"] == card_id:
			cards.remove_at(i)
			break

## 查找卡牌
func _find_card_by_id(card_id: String) -> Variant:
	"""根据ID查找卡牌"""
	for layer_index in current_cards:
		for card_data in current_cards[layer_index]:
			if card_data["id"] == card_id:
				return card_data
	return null

# ============================================================
# 获取数据
# ============================================================

## 获取当前层级卡牌
func get_current_layer_cards() -> Array:
	"""获取当前层级的所有卡牌"""
	var layer_index = GameManager.current_layer_index
	return current_cards.get(layer_index, [])

## 获取指定层级卡牌
func get_layer_cards(layer_index: int) -> Array:
	"""获取指定层级的所有卡牌"""
	return current_cards.get(layer_index, [])

## 获取当前连击数
func get_combo_count() -> int:
	"""获取当前连击数"""
	return current_combo_count
