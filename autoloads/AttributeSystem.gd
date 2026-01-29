# ============================================================
# 脚本名称：AttributeSystem
# 功能描述：属性系统 - 管理五维属性（体能、疲劳、饥饿、口渴、心率）
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node

## 信号定义
signal attribute_changed(attribute_name: String, current_value: float, max_value: float)
signal energy_changed(current_energy: float, max_energy: float)
signal fatigue_changed(current_fatigue: float, max_fatigue: float)
signal hunger_changed(current_hunger: float, max_hunger: float)
signal thirst_changed(current_thirst: float, max_thirst: float)
signal heart_rate_changed(current_heart_rate: float)
signal game_over(reason: String)

## 属性常量
const MAX_ENERGY: float = 100.0
const MIN_ENERGY: float = 0.0
const MAX_FATIGUE: float = 20.0
const MAX_HUNGER: float = 100.0
const MAX_THIRST: float = 100.0
const MIN_HEART_RATE: int = 80
const MAX_HEART_RATE: int = 180
const RESTING_HEART_RATE: int = 110

## 当前属性值
var current_energy: float = 100.0
var current_fatigue: float = 0.0
var current_hunger: float = 100.0
var current_thirst: float = 100.0
var current_heart_rate: int = 110

## 属性恢复速率
var energy_recovery_rate: float = 1.0
var hunger_recovery_rate: float = 1.0
var thirst_recovery_rate: float = 1.0
var heart_rate_recovery_rate: float = 1.0

## 属性消耗速率
var energy_cost_rate: float = 1.0
var fatigue_gain_rate: float = 1.0
var hunger_loss_rate: float = 1.0
var thirst_loss_rate: float = 1.0
var heart_rate_gain_rate: float = 1.0

## 负重系统
var base_carry_capacity: float = 20.0
var current_carry_weight: float = 0.0
var max_carry_capacity: float = 20.0

## 状态标记
var is_resting: bool = false
var is_fear_state: bool = false
var is_knee_injured: bool = false
var is_breathing_difficult: bool = false

## 定时器
var recovery_timer: Timer
var attribute_update_timer: Timer

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[AttributeSystem] Initializing attribute system...")
	_setup_timers()
	print_debug("[AttributeSystem] Attribute system initialized")

## 初始化属性系统
func initialize() -> void:
	"""初始化属性系统（游戏开始时调用）"""
	current_energy = GameManager.get_game_config("initial_energy", 100.0)
	current_fatigue = GameManager.get_game_config("initial_fatigue", 0.0)
	current_hunger = GameManager.get_game_config("initial_hunger", 100.0)
	current_thirst = GameManager.get_game_config("initial_thirst", 100.0)
	current_heart_rate = RESTING_HEART_RATE
	
	# 更新最大负重
	_update_max_carry_capacity()
	
	print_debug("[AttributeSystem] Attributes initialized: E=%d, F=%.1f, H=%d, T=%d, HR=%d" % [
		current_energy, current_fatigue, current_hunger, current_thirst, current_heart_rate
	])

## 设置定时器
func _setup_timers() -> void:
	"""设置属性更新定时器"""
	# 属性恢复定时器
	recovery_timer = Timer.new()
	recovery_timer.wait_time = 1.0  # 每秒更新
	recovery_timer.autostart = false
	recovery_timer.timeout.connect(_on_recovery_timer_timeout)
	add_child(recovery_timer)
	
	# 属性变化定时器（用于检查状态变化）
	attribute_update_timer = Timer.new()
	attribute_update_timer.wait_time = 0.5  # 每0.5秒检查
	attribute_update_timer.autostart = false
	attribute_update_timer.timeout.connect(_on_attribute_update_timeout)
	add_child(attribute_update_timer)

## 启动属性恢复
func start_recovery() -> void:
	"""启动属性恢复定时器"""
	if not recovery_timer.time_left > 0:
		recovery_timer.start()
		attribute_update_timer.start()

## 停止属性恢复
func stop_recovery() -> void:
	"""停止属性恢复定时器"""
	recovery_timer.stop()
	attribute_update_timer.stop()

# ============================================================
# 体力系统
# ============================================================

## 获取当前体力
func get_energy() -> float:
	"""获取当前体力"""
	return current_energy

## 获取最大体力
func get_max_energy() -> float:
	"""获取最大体力"""
	return MAX_ENERGY

## 消耗体力
func consume_energy(amount: float) -> bool:
	"""消耗体力，返回是否成功（体力不足返回false）"""
	var actual_cost = amount * energy_cost_rate
	
	# 体力为0时游戏结束
	if current_energy <= MIN_ENERGY:
		_trigger_game_over("体力耗尽")
		return false
	
	current_energy -= actual_cost
	
	# 检查是否耗尽
	if current_energy <= MIN_ENERGY:
		current_energy = MIN_ENERGY
		_trigger_game_over("体力耗尽")
		return false
	
	# 限制在范围内
	current_energy = clampf(current_energy, MIN_ENERGY, MAX_ENERGY)
	
	# 信号
	energy_changed.emit(current_energy, MAX_ENERGY)
	attribute_changed.emit("energy", current_energy, MAX_ENERGY)
	
	return true

## 恢复体力
func recover_energy(amount: float) -> void:
	"""恢复体力"""
	var actual_recovery = amount * energy_recovery_rate
	
	# 根据饥饿和口渴调整恢复速率
	actual_recovery *= _get_recovery_multiplier()
	
	current_energy += actual_recovery
	
	# 限制在范围内
	current_energy = clampf(current_energy, MIN_ENERGY, MAX_ENERGY)
	
	# 信号
	energy_changed.emit(current_energy, MAX_ENERGY)
	attribute_changed.emit("energy", current_energy, MAX_ENERGY)

## 检查体力是否充足
func is_energy_sufficient(required_amount: float) -> bool:
	"""检查体力是否充足"""
	return current_energy >= required_amount

# ============================================================
# 疲劳系统
# ============================================================

## 获取当前疲劳
func get_fatigue() -> float:
	"""获取当前疲劳值"""
	return current_fatigue

## 获取最大疲劳
func get_max_fatigue() -> float:
	"""获取最大疲劳值"""
	return MAX_FATIGUE

## 增加疲劳
func add_fatigue(amount: float) -> void:
	"""增加疲劳值"""
	var actual_gain = amount * fatigue_gain_rate
	
	# 根据心率调整疲劳增长速率
	if current_heart_rate > 140:
		actual_gain *= 1.5
	elif current_heart_rate > 120:
		actual_gain *= 1.2
	
	current_fatigue += actual_gain
	
	# 限制在范围内
	current_fatigue = clampf(current_fatigue, 0.0, MAX_FATIGUE)
	
	# 信号
	fatigue_changed.emit(current_fatigue, MAX_FATIGUE)
	attribute_changed.emit("fatigue", current_fatigue, MAX_FATIGUE)

## 减少疲劳
func reduce_fatigue(amount: float) -> void:
	"""减少疲劳值（通过休息）"""
	current_fatigue -= amount
	
	# 限制在范围内
	current_fatigue = clampf(current_fatigue, 0.0, MAX_FATIGUE)
	
	# 信号
	fatigue_changed.emit(current_fatigue, MAX_FATIGUE)
	attribute_changed.emit("fatigue", current_fatigue, MAX_FATIGUE)

## 重置疲劳
func reset_fatigue() -> void:
	"""重置疲劳值（深度休息后）"""
	current_fatigue = 0.0
	fatigue_changed.emit(current_fatigue, MAX_FATIGUE)
	attribute_changed.emit("fatigue", current_fatigue, MAX_FATIGUE)

## 计算疲劳积累
func calculate_fatigue_accumulation(distance: float, elevation_gain: float) -> float:
	"""根据徒步距离和累积爬升计算疲劳积累"""
	var fatigue_from_distance = distance / 5.0
	var fatigue_from_elevation = elevation_gain / 250.0
	
	return fatigue_from_distance + fatigue_from_elevation

# ============================================================
# 饥饿系统
# ============================================================

## 获取当前饥饿
func get_hunger() -> float:
	"""获取当前饥饿值"""
	return current_hunger

## 获取最大饥饿
func get_max_hunger() -> float:
	"""获取最大饥饿值"""
	return MAX_HUNGER

## 消耗饥饿
func consume_hunger(amount: float) -> void:
	"""消耗饥饿值"""
	var actual_loss = amount * hunger_loss_rate
	
	current_hunger -= actual_loss
	
	# 限制在范围内
	current_hunger = clampf(current_hunger, 0.0, MAX_HUNGER)
	
	# 信号
	hunger_changed.emit(current_hunger, MAX_HUNGER)
	attribute_changed.emit("hunger", current_hunger, MAX_HUNGER)

## 恢复饥饿
func recover_hunger(amount: float) -> void:
	"""恢复饥饿值（通过进食）"""
	var actual_recovery = amount * hunger_recovery_rate
	
	current_hunger += actual_recovery
	
	# 限制在范围内
	current_hunger = clampf(current_hunger, 0.0, MAX_HUNGER)
	
	# 信号
	hunger_changed.emit(current_hunger, MAX_HUNGER)
	attribute_changed.emit("hunger", current_hunger, MAX_HUNGER)

## 检查饥饿状态
func get_hunger_status() -> String:
	"""获取饥饿状态"""
	if current_hunger >= 80:
		return "satiated"
	elif current_hunger >= 50:
		return "normal"
	elif current_hunger >= 30:
		return "hungry"
	elif current_hunger >= 15:
		return "very_hungry"
	else:
		return "starving"

# ============================================================
# 口渴系统
# ============================================================

## 获取当前口渴
func get_thirst() -> float:
	"""获取当前口渴值"""
	return current_thirst

## 获取最大口渴
func get_max_thirst() -> float:
	"""获取最大口渴值"""
	return MAX_THIRST

## 消耗口渴
func consume_thirst(amount: float) -> void:
	"""消耗口渴值"""
	var actual_loss = amount * thirst_loss_rate
	
	# 高温天气口渴消耗加倍
	if GameManager.current_weather == "hot":
		actual_loss *= 1.5
	elif GameManager.current_weather == "typhoon":
		actual_loss *= 1.3
	
	current_thirst -= actual_loss
	
	# 限制在范围内
	current_thirst = clampf(current_thirst, 0.0, MAX_THIRST)
	
	# 信号
	thirst_changed.emit(current_thirst, MAX_THIRST)
	attribute_changed.emit("thirst", current_thirst, MAX_THIRST)

## 恢复口渴
func recover_thirst(amount: float) -> void:
	"""恢复口渴值（通过饮水）"""
	var actual_recovery = amount * thirst_recovery_rate
	
	current_thirst += actual_recovery
	
	# 限制在范围内
	current_thirst = clampf(current_thirst, 0.0, MAX_THIRST)
	
	# 信号
	thirst_changed.emit(current_thirst, MAX_THIRST)
	attribute_changed.emit("thirst", current_thirst, MAX_THIRST)

## 检查口渴状态
func get_thirst_status() -> String:
	"""获取口渴状态"""
	if current_thirst >= 80:
		return "well_hydrated"
	elif current_thirst >= 50:
		return "normal"
	elif current_thirst >= 30:
		return "thirsty"
	elif current_thirst >= 15:
		return "very_thirsty"
	else:
		return "dehydrated"

# ============================================================
# 心率系统
# ============================================================

## 获取当前心率
func get_heart_rate() -> int:
	"""获取当前心率"""
	return current_heart_rate

## 增加心率
func increase_heart_rate(amount: int) -> void:
	"""增加心率（运动时）"""
	var actual_gain = float(amount) * heart_rate_gain_rate
	
	current_heart_rate += int(actual_gain)
	
	# 限制在范围内
	current_heart_rate = clampi(current_heart_rate, MIN_HEART_RATE, MAX_HEART_RATE)
	
	# 信号
	heart_rate_changed.emit(current_heart_rate)
	attribute_changed.emit("heart_rate", float(current_heart_rate), float(MAX_HEART_RATE))

## 减少心率
func decrease_heart_rate(amount: int) -> void:
	"""减少心率（休息时）"""
	var actual_reduction = float(amount) * heart_rate_recovery_rate
	
	current_heart_rate -= int(actual_reduction)
	
	# 限制在范围内
	current_heart_rate = clampi(current_heart_rate, MIN_HEART_RATE, MAX_HEART_RATE)
	
	# 信号
	heart_rate_changed.emit(current_heart_rate)
	attribute_changed.emit("heart_rate", float(current_heart_rate), float(MAX_HEART_RATE))

## 检查心率状态
func get_heart_rate_status() -> String:
	"""获取心率状态"""
	if current_heart_rate < 100:
		return "resting"
	elif current_heart_rate < 130:
		return "light_exercise"
	elif current_heart_rate < 150:
		return "moderate_exercise"
	elif current_heart_rate < 170:
		return "intense_exercise"
	else:
		return "extreme_exercise"

## 计算心率影响
func calculate_heart_rate_effect() -> Dictionary:
	"""计算心率对其他属性的影响"""
	var effect = {
		"energy_recovery_multiplier": 1.0,
		"fatigue_gain_multiplier": 1.0,
		"operation_efficiency": 1.0
	}
	
	if current_heart_rate < 100:
		# 休息状态，恢复快
		effect["energy_recovery_multiplier"] = 1.5
		effect["fatigue_gain_multiplier"] = 0.8
	elif current_heart_rate < 130:
		# 轻度运动
		effect["energy_recovery_multiplier"] = 1.2
		effect["fatigue_gain_multiplier"] = 1.0
		effect["operation_efficiency"] = 1.0
	elif current_heart_rate < 150:
		# 中度运动
		effect["energy_recovery_multiplier"] = 1.0
		effect["fatigue_gain_multiplier"] = 1.2
		effect["operation_efficiency"] = 0.95
	elif current_heart_rate < 170:
		# 高强度运动
		effect["energy_recovery_multiplier"] = 0.8
		effect["fatigue_gain_multiplier"] = 1.5
		effect["operation_efficiency"] = 0.85
	else:
		# 极限运动
		effect["energy_recovery_multiplier"] = 0.5
		effect["fatigue_gain_multiplier"] = 2.0
		effect["operation_efficiency"] = 0.7
	
	return effect

# ============================================================
# 负重系统
# ============================================================

## 获取当前负重
func get_carry_weight() -> float:
	"""获取当前负重"""
	return current_carry_weight

## 获取最大负重
func get_max_carry_capacity() -> float:
	"""获取最大负重能力"""
	return max_carry_capacity

## 增加负重
func add_carry_weight(weight: float) -> bool:
	"""增加负重，返回是否成功"""
	current_carry_weight += weight
	
	# 限制在最大范围内
	if current_carry_weight > max_carry_capacity:
		return false
	
	return true

## 减少负重
func remove_carry_weight(weight: float) -> void:
	"""减少负重"""
	current_carry_weight -= weight
	current_carry_weight = maxf(current_carry_weight, 0.0)

## 计算负重影响
func calculate_carry_load_effect() -> float:
	"""计算负重对疲劳的影响"""
	var carry_load_ratio = current_carry_weight / max_carry_capacity
	
	if carry_load_ratio < 0.5:
		return 1.0
	elif carry_load_ratio < 0.8:
		return 1.2
	else:
		return 1.5

## 更新最大负重
func _update_max_carry_capacity() -> void:
	"""更新最大负重（根据体力）"""
	max_carry_capacity = base_carry_capacity + (current_energy * 0.1)

# ============================================================
# 状态系统
# ============================================================

## 设置恐惧状态
func set_fear_state(is_fear: bool, duration: float = 3.0) -> void:
	"""设置恐惧状态"""
	is_fear_state = is_fear
	
	if is_fear:
		# 恐惧状态下心率大幅上升
		increase_heart_rate(30)
		print_debug("[AttributeSystem] Fear state activated")
		
		# 定时器自动解除
		var timer = Timer.new()
		timer.wait_time = duration
		timer.timeout.connect(func(): set_fear_state(false))
		add_child(timer)
		timer.start()
	else:
		print_debug("[AttributeSystem] Fear state deactivated")

## 设置膝盖受伤状态
func set_knee_injury(is_injured: bool) -> void:
	"""设置膝盖受伤状态"""
	is_knee_injured = is_injured
	
	if is_injured:
		# 膝盖受伤时疲劳增加
		add_fatigue(10.0)
		print_debug("[AttributeSystem] Knee injury activated")
	else:
		print_debug("[AttributeSystem] Knee injury deactivated")

## 设置呼吸困难状态
func set_breathing_difficulty(is_difficult: bool) -> void:
	"""设置呼吸困难状态"""
	is_breathing_difficult = is_difficult
	
	if is_difficult:
		# 呼吸困难时心率上升，体能消耗增加
		increase_heart_rate(15)
		energy_cost_rate *= 1.2
		print_debug("[AttributeSystem] Breathing difficulty activated")
	else:
		energy_cost_rate /= 1.2
		print_debug("[AttributeSystem] Breathing difficulty deactivated")

## 开始休息
func start_resting() -> void:
	"""开始休息"""
	is_resting = true
	# 休息时心率下降
	decrease_heart_rate(20)
	print_debug("[AttributeSystem] Started resting")

## 结束休息
func stop_resting() -> void:
	"""结束休息"""
	is_resting = false
	print_debug("[AttributeSystem] Stopped resting")

# ============================================================
# 工具函数
# ============================================================

## 获取恢复速率乘数
func _get_recovery_multiplier() -> float:
	"""计算饥饿和口渴对恢复速率的影响"""
	var multiplier = 1.0
	
	# 饥饿影响
	var hunger_status = get_hunger_status()
	if hunger_status == "hungry":
		multiplier *= 0.8
	elif hunger_status == "very_hungry":
		multiplier *= 0.5
	elif hunger_status == "starving":
		multiplier *= 0.1
	
	# 口渴影响（影响更大）
	var thirst_status = get_thirst_status()
	if thirst_status == "thirsty":
		multiplier *= 0.7
	elif thirst_status == "very_thirsty":
		multiplier *= 0.3
	elif thirst_status == "dehydrated":
		multiplier *= 0.05
	
	return multiplier

## 触发游戏结束
func _trigger_game_over(reason: String) -> void:
	"""触发游戏结束"""
	print_debug("[AttributeSystem] Game over triggered: %s" % reason)
	stop_recovery()
	game_over.emit(reason)

## 获取所有属性状态
func get_all_attributes() -> Dictionary:
	"""获取所有属性的当前状态"""
	return {
		"energy": {
			"current": current_energy,
			"max": MAX_ENERGY,
			"status": "normal" if current_energy > 50 else "low" if current_energy > 20 else "critical"
		},
		"fatigue": {
			"current": current_fatigue,
			"max": MAX_FATIGUE,
			"status": "normal" if current_fatigue < 10 else "high" if current_fatigue < 15 else "critical"
		},
		"hunger": {
			"current": current_hunger,
			"max": MAX_HUNGER,
			"status": get_hunger_status()
		},
		"thirst": {
			"current": current_thirst,
			"max": MAX_THIRST,
			"status": get_thirst_status()
		},
		"heart_rate": {
			"current": current_heart_rate,
			"min": MIN_HEART_RATE,
			"max": MAX_HEART_RATE,
			"status": get_heart_rate_status()
		},
		"carry": {
			"current": current_carry_weight,
			"max": max_carry_capacity,
			"ratio": current_carry_weight / max_carry_capacity
		}
	}

# ============================================================
# 定时器回调
# ============================================================

## 恢复定时器回调
func _on_recovery_timer_timeout() -> void:
	"""每秒调用一次，处理属性恢复"""
	if is_resting:
		# 休息时恢复体力
		recover_energy(2.0)
		# 休息时减少疲劳
		reduce_fatigue(0.5)
	else:
		# 不休息时自然消耗
		consume_hunger(0.1)
		consume_thirst(0.15)
		# 体力自然恢复（根据饥饿口渴状态）
		recover_energy(0.5)
		
		# 自然心率恢复
		if current_heart_rate > RESTING_HEART_RATE:
			decrease_heart_rate(2)
		
		# 负重影响疲劳
		var carry_effect = calculate_carry_load_effect()
		add_fatigue(0.05 * carry_effect)

## 属性更新定时器回调
func _on_attribute_update_timeout() -> void:
	"""每0.5秒检查一次属性状态变化"""
	# 检查是否需要触发特殊状态
	
	# 饥饿严重
	if current_hunger < 15:
		print_debug("[AttributeSystem] Warning: Severe hunger!")
	
	# 口渴严重
	if current_thirst < 15:
		print_debug("[AttributeSystem] Warning: Severe thirst!")
	
	# 心率过高
	if current_heart_rate > 170:
		print_debug("[AttributeSystem] Warning: Heart rate critical!")
