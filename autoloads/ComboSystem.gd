# ============================================================
# 脚本名称：ComboSystem
# 功能描述：连击系统 - 管理连击计算、奖励、视觉效果
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node
class_name ComboSystem

## 信号定义
signal combo_count_changed(count: int)
signal combo_reward_activated(reward_type: String, amount: float)

## 连击数据
var current_combo: int = 0
var max_combo: int = 0
var combo_chain: Array = []  # 记录连击历史

## 连击奖励阈值
const COMBO_REWARDS = {
	3: {"type": "environmental_value", "amount": 50},
	5: {"type": "energy", "amount": 10},
	7: {"type": "fatigue", "amount": -5},
	10: {"type": "environmental_value", "amount": 100, "energy": 20}
}

## 连击效果持续时间
var combo_effect_timer: Timer

## 连击状态
var is_combo_active: bool = false

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[ComboSystem] Initializing combo system...")
	_setup_timers()
	print_debug("[ComboSystem] Combo system initialized")

## 初始化连击系统
func initialize() -> void:
	"""初始化连击系统"""
	current_combo = 0
	max_combo = 0
	combo_chain.clear()
	is_combo_active = false
	print_debug("[ComboSystem] Combo system initialized")

## 设置定时器
func _setup_timers() -> void:
	"""设置连击效果定时器"""
	combo_effect_timer = Timer.new()
	combo_effect_timer.wait_time = 5.0  # 连击效果持续5秒
	combo_effect_timer.one_shot = true
	combo_effect_timer.timeout.connect(_on_combo_effect_timeout)
	add_child(combo_effect_timer)

# ============================================================
# 连击管理
# ============================================================

## 增加连击
func add_combo(card_type: String) -> void:
	"""增加连击数"""
	if card_type == "scenery" or card_type == "scenery_summit":
		current_combo += 1
		combo_chain.append(card_type)
		
		# 更新最大连击
		if current_combo > max_combo:
			max_combo = current_combo
		
		# 检查奖励
		_check_combo_rewards()
		
		# 发送信号
		combo_count_changed.emit(current_combo)
		
		# 显示连击效果
		_show_combo_effect()
		
		# 重置效果定时器
		if combo_effect_timer.time_left > 0:
			combo_effect_timer.stop()
		combo_effect_timer.start()
		
		print_debug("[ComboSystem] Combo increased to %d" % current_combo)
	else:
		# 非风景卡，重置连击
		reset_combo()

## 重置连击
func reset_combo() -> void:
	"""重置连击"""
	current_combo = 0
	combo_chain.clear()
	is_combo_active = false
	combo_count_changed.emit(current_combo)
	print_debug("[ComboSystem] Combo reset")

## 检查连击奖励
func _check_combo_rewards() -> void:
	"""检查是否触发连击奖励"""
	for threshold in COMBO_REWARDS:
		if current_combo == int(threshold):
			_activate_combo_reward(COMBO_REWARDS[threshold])

## 激活连击奖励
func _activate_combo_reward(reward: Dictionary) -> void:
	"""激活连击奖励"""
	var reward_type = reward["type"]
	var amount = reward["amount"]
	
	match reward_type:
		"environmental_value":
			EconomySystem.add_environmental_value(amount)
		"energy":
			AttributeSystem.recover_energy(amount)
		"fatigue":
			AttributeSystem.reduce_fatigue(abs(amount))
	
	combo_reward_activated.emit(reward_type, amount)
	print_debug("[ComboSystem] Combo reward activated: %s x%d" % [reward_type, amount])

## 显示连击效果
func _show_combo_effect() -> void:
	"""显示连击视觉效果"""
	is_combo_active = true
	UIManager.show_combo_effect(current_combo)

## 连击效果超时
func _on_combo_effect_timeout() -> void:
	"""连击效果超时"""
	is_combo_active = false
	UIManager.hide_combo_effect()

# ============================================================
# 连击查询
# ============================================================

## 获取当前连击
func get_current_combo() -> int:
	"""获取当前连击数"""
	return current_combo

## 获取最大连击
func get_max_combo() -> int:
	"""获取最大连击数"""
	return max_combo

## 检查连击是否活跃
func is_combo_active() -> bool:
	"""检查连击是否活跃"""
	return is_combo_active

## 获取连击倍率
func get_combo_multiplier() -> float:
	"""获取连击倍率（用于奖励计算）"""
	if current_combo < 3:
		return 1.0
	elif current_combo < 5:
		return 1.5
	elif current_combo < 7:
		return 2.0
	elif current_combo < 10:
		return 3.0
	else:
		return 5.0
