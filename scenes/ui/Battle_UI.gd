# ============================================================
# 脚本名称：Battle_UI
# 功能描述：战斗UI界面控制
# 版本号：v1.1
# 创建日期：2026年2月1日
# ============================================================

class_name BattleUI
extends Control

# Preload Card Scene
const CardScene = preload("res://scenes/ui/Card.tscn")

## 节点引用
@onready var cards_container: HBoxContainer = %CardsContainer
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var fatigue_bar: ProgressBar = %FatigueBar
@onready var hunger_bar: ProgressBar = %HungerBar
@onready var thirst_bar: ProgressBar = %ThirstBar
@onready var heart_rate_label: Label = %HeartRateLabel
@onready var combo_label: Label = %ComboLabel
@onready var environmental_value_label: Label = %EnvironmentalValueLabel
@onready var distance_label: Label = %DistanceLabel
@onready var elevation_label: Label = %ElevationLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 确认弹窗引用 (动态创建或查找)
var cliff_confirm_panel: Panel
var cliff_confirm_btn: Button
var cliff_cancel_btn: Button

## 交互状态
var long_press_card_id: String = ""
var long_press_start_time: float = 0.0
var long_press_duration: float = 1.5  # 长按所需时间
var is_long_pressing: bool = false
var pending_confirm_card_id: String = ""

## 信号
# signal interaction_completed(card_id: String)

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[BattleUI] Initializing...")
	
	# 初始化确认弹窗
	_setup_cliff_confirmation_ui()
	
	# 连接系统信号
	_connect_signals()
	
	# 初始化UI
	_update_all_ui()
	
	# 生成初始卡牌
	_spawn_initial_cards()
	
	set_process(false) # 默认不处理每帧逻辑，长按时开启

func _setup_cliff_confirmation_ui() -> void:
	# 检查是否存在，如果不存在则创建
	if has_node("CliffConfirmationPanel"):
		cliff_confirm_panel = get_node("CliffConfirmationPanel")
		cliff_confirm_btn = cliff_confirm_panel.get_node("ConfirmButton")
		cliff_cancel_btn = cliff_confirm_panel.get_node("CancelButton")
	else:
		_create_cliff_confirmation_ui()
	
	# 连接按钮信号
	if not cliff_confirm_btn.pressed.is_connected(_on_confirm_pressed):
		cliff_confirm_btn.pressed.connect(_on_confirm_pressed)
	if not cliff_cancel_btn.pressed.is_connected(_on_cancel_pressed):
		cliff_cancel_btn.pressed.connect(_on_cancel_pressed)
		
	cliff_confirm_panel.visible = false

func _create_cliff_confirmation_ui() -> void:
	# 动态创建UI (如果场景中没有)
	cliff_confirm_panel = Panel.new()
	cliff_confirm_panel.name = "CliffConfirmationPanel"
	cliff_confirm_panel.visible = false
	cliff_confirm_panel.layout_mode = 1 # LayoutMode.LAYOUT_MODE_ANCHORS
	cliff_confirm_panel.anchors_preset = 8 # Center
	cliff_confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	cliff_confirm_panel.size = Vector2(300, 200)
	cliff_confirm_panel.position = size / 2 - cliff_confirm_panel.size / 2 # Center manually to be safe
	add_child(cliff_confirm_panel)
	
	var label = Label.new()
	label.text = "前方是悬崖，确定要跳下吗？"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.layout_mode = 1 # LayoutMode.LAYOUT_MODE_ANCHORS
	label.anchors_preset = 10 # Top wide
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.size.y = 120
	cliff_confirm_panel.add_child(label)
	
	cliff_confirm_btn = Button.new()
	cliff_confirm_btn.name = "ConfirmButton"
	cliff_confirm_btn.text = "确定"
	cliff_confirm_btn.size = Vector2(100, 40)
	cliff_confirm_btn.position = Vector2(20, 140)
	cliff_confirm_panel.add_child(cliff_confirm_btn)
	
	cliff_cancel_btn = Button.new()
	cliff_cancel_btn.name = "CancelButton"
	cliff_cancel_btn.text = "取消"
	cliff_cancel_btn.size = Vector2(100, 40)
	cliff_cancel_btn.position = Vector2(180, 140)
	cliff_confirm_panel.add_child(cliff_cancel_btn)

func _connect_signals() -> void:
	# 属性系统
	AttributeSystem.attribute_changed.connect(_on_attribute_changed)
	
	# 连击系统
	ComboSystem.combo_count_changed.connect(_on_combo_changed)
	
	# 经济系统
	EconomySystem.environmental_value_changed.connect(_on_environmental_value_changed)
	
	# 卡牌系统
	CardSystem.card_spawned.connect(_on_card_spawned)
	CardSystem.card_crossed.connect(_on_card_crossed)
	CardSystem.layer_completed.connect(_on_layer_completed)

func _process(_delta: float) -> void:
	if is_long_pressing:
		_update_long_press_progress()

# ============================================================
# 卡牌渲染
# ============================================================

func _spawn_initial_cards() -> void:
	"""生成初始卡牌"""
	# 清空容器
	for child in cards_container.get_children():
		child.queue_free()
		
	# 获取当前层级卡牌
	var cards = CardSystem.get_current_layer_cards()
	for card_data in cards:
		_create_card_node(card_data)

func _create_card_node(card_data: Dictionary) -> void:
	"""创建卡牌节点"""
	var card_node = CardScene.instantiate()
	card_node.name = card_data["id"]
	
	# 连接信号
	card_node.card_pressed.connect(_handle_card_pressed)
	card_node.card_released.connect(_handle_card_released)
	
	cards_container.add_child(card_node)
	
	# Setup must be called after adding to tree or ensuring ready, but usually fine.
	card_node.setup(card_data)

func _remove_card_node(card_id: String) -> void:
	"""移除卡牌节点"""
	var node = cards_container.get_node_or_null(card_id)
	if node:
		node.queue_free()

# ============================================================
# 输入处理 (分级翻越)
# ============================================================

func _handle_card_pressed(card_data: Dictionary) -> void:
	"""处理卡牌按下"""
	var interaction_type = card_data["effects"].get("interaction_type", "click")
	
	if interaction_type == "long_press":
		_start_long_press(card_data)
	elif interaction_type == "click" or interaction_type == "confirm":
		# 点击类型在释放时触发
		pass

func _handle_card_released(card_data: Dictionary) -> void:
	"""处理卡牌释放"""
	var interaction_type = card_data["effects"].get("interaction_type", "click")
	
	if interaction_type == "long_press":
		_stop_long_press()
	elif interaction_type == "click":
		CardSystem.attempt_traverse_card(card_data["id"])
	elif interaction_type == "confirm":
		_show_cliff_confirm_dialog(card_data)

# ============================================================
# 长按逻辑
# ============================================================

func _start_long_press(card_data: Dictionary) -> void:
	"""开始长按"""
	long_press_card_id = card_data["id"]
	long_press_start_time = Time.get_ticks_msec() / 1000.0
	is_long_pressing = true
	set_process(true)
	
	# 视觉反馈
	var node = cards_container.get_node_or_null(long_press_card_id)
	if node and node.has_method("start_long_press_visual"):
		node.start_long_press_visual()
	
	print_debug("[BattleUI] Started long press on %s" % card_data["name"])

func _stop_long_press() -> void:
	"""停止长按"""
	if not is_long_pressing: return
	
	# 视觉反馈清理
	var node = cards_container.get_node_or_null(long_press_card_id)
	if node and node.has_method("start_long_press_visual"):
		node.stop_long_press_visual()
	
	is_long_pressing = false
	set_process(false)
	long_press_card_id = ""

func _update_long_press_progress() -> void:
	"""更新长按进度"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - long_press_start_time
	var progress = clamp(elapsed / long_press_duration, 0.0, 1.0)
	
	# 更新UI
	var node = cards_container.get_node_or_null(long_press_card_id)
	if node and node.has_method("update_long_press_visual"):
		node.update_long_press_visual(progress)
	
	if progress >= 1.0:
		_complete_long_press()

func _complete_long_press() -> void:
	"""完成长按"""
	print_debug("[BattleUI] Long press completed!")
	CardSystem.attempt_traverse_card(long_press_card_id)
	
	# 停止长按状态
	_stop_long_press()

# ============================================================
# 确认弹窗逻辑
# ============================================================

func _show_cliff_confirm_dialog(card_data: Dictionary) -> void:
	pending_confirm_card_id = card_data["id"]
	cliff_confirm_panel.visible = true

func _on_confirm_pressed() -> void:
	if pending_confirm_card_id != "":
		CardSystem.attempt_traverse_card(pending_confirm_card_id)
		pending_confirm_card_id = ""
	cliff_confirm_panel.visible = false

func _on_cancel_pressed() -> void:
	pending_confirm_card_id = ""
	cliff_confirm_panel.visible = false

# ============================================================
# 信号回调
# ============================================================

func _on_attribute_changed(attr_name: String, current: float, max_val: float) -> void:
	"""属性变化回调"""
	_update_attribute_bars()

func _on_combo_changed(count: int) -> void:
	if combo_label:
		combo_label.text = "连击: %d" % count

func _on_environmental_value_changed(value: int) -> void:
	if environmental_value_label:
		environmental_value_label.text = "环保值: %d" % value

func _on_card_spawned(card_data: Dictionary, _layer_index: int, _position: int) -> void:
	"""新卡牌生成回调"""
	_create_card_node(card_data)

func _on_card_crossed(card_data: Dictionary, _combo_count: int) -> void:
	"""卡牌穿越回调"""
	_remove_card_node(card_data["id"])

func _on_layer_completed(layer_index: int) -> void:
	"""层级完成回调"""
	print_debug("[BattleUI] Layer %d completed" % layer_index)

# ============================================================
# UI更新
# ============================================================

func _update_all_ui() -> void:
	"""更新所有UI"""
	_update_attribute_bars()
	if combo_label: combo_label.text = "连击: %d" % ComboSystem.get_current_combo()
	if environmental_value_label: environmental_value_label.text = "环保值: %d" % EconomySystem.get_environmental_value()

func _update_attribute_bars() -> void:
	"""更新属性条"""
	if energy_bar:
		energy_bar.value = AttributeSystem.get_attribute("energy")
		energy_bar.max_value = AttributeSystem.get_attribute_max("energy")
	if fatigue_bar:
		fatigue_bar.value = AttributeSystem.get_attribute("fatigue")
		fatigue_bar.max_value = AttributeSystem.get_attribute_max("fatigue")
	if hunger_bar:
		hunger_bar.value = AttributeSystem.get_attribute("hunger")
		hunger_bar.max_value = AttributeSystem.get_attribute_max("hunger")
	if thirst_bar:
		thirst_bar.value = AttributeSystem.get_attribute("thirst")
		thirst_bar.max_value = AttributeSystem.get_attribute_max("thirst")
	if heart_rate_label:
		heart_rate_label.text = "心率: %d BPM" % int(AttributeSystem.get_attribute("heart_rate"))
