# ============================================================
# 脚本名称：FatigueSystem
# 功能描述：疲劳系统 - 负责疲劳值管理、休息机制
# 版本号：v1.0
# 创建日期：2026年2月1日
# ============================================================

extends Node
class_name FatigueSystem

## 信号定义
signal fatigue_updated(current: float, max_val: float)
signal rest_taken(recovered_amount: float)
signal exhausted()

## 属性
var current_fatigue: float = 0.0
var max_fatigue: float = 100.0
var fatigue_threshold: float = 80.0 # 疲劳警告阈值

## 初始化
func _ready() -> void:
	print_debug("[FatigueSystem] Initialized")

## 增加疲劳
func add_fatigue(amount: float) -> void:
	current_fatigue = min(max_fatigue, current_fatigue + amount)
	fatigue_updated.emit(current_fatigue, max_fatigue)
	
	if current_fatigue >= max_fatigue:
		exhausted.emit()
		print_debug("[FatigueSystem] Player is EXHAUSTED!")
	elif current_fatigue >= fatigue_threshold:
		print_debug("[FatigueSystem] Warning: High fatigue!")

## 休息
func rest(hours: float) -> void:
	# 假设每小时休息恢复15点疲劳
	var recovery_rate = 15.0
	var recovered = hours * recovery_rate
	
	current_fatigue = max(0.0, current_fatigue - recovered)
	rest_taken.emit(recovered)
	fatigue_updated.emit(current_fatigue, max_fatigue)
	print_debug("[FatigueSystem] Rested for %.1f hours, Recovered %.1f fatigue" % [hours, recovered])

## 获取当前疲劳比例
func get_fatigue_ratio() -> float:
	return current_fatigue / max_fatigue if max_fatigue > 0 else 0.0
