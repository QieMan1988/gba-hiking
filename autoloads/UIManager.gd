# ============================================================
# 脚本名称：UIManager
# 功能描述：UI管理器 - 管理所有UI场景、交互、反馈
# 版本号：v1.0
# 创建日期：2026年1月30日
# ============================================================

extends Node
class_name UIManager

## UI场景引用
var main_menu_scene: Node
var level_select_scene: Node
var battle_scene: Node
var result_scene: Node
var shop_scene: Node

## 当前活动场景
var current_scene: Node

## UI元素引用
var energy_bar: ProgressBar
var fatigue_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var heart_rate_label: Label
var combo_label: Label
var environmental_value_label: Label
var distance_label: Label
var elevation_label: Label

## 动画播放器
var animation_player: AnimationPlayer

## 确认对话框回调
var confirmation_callback: Callable

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print_debug("[UIManager] Initializing UI manager...")
	_load_ui_scenes()
	_connect_signals()
	print_debug("[UIManager] UI manager initialized")

## 加载UI场景
func _load_ui_scenes() -> void:
	"""加载所有UI场景"""
	# 注意：这里使用load()而不是preload()以延迟加载
	pass

## 连接信号
func _connect_signals() -> void:
	"""连接管理器信号"""
	AttributeSystem.attribute_changed.connect(_on_attribute_changed)
	ComboSystem.combo_count_changed.connect(_on_combo_changed)
	EconomySystem.environmental_value_changed.connect(_on_environmental_value_changed)
	GameManager.level_changed.connect(_on_level_changed)

# ============================================================
# 场景管理
# ============================================================

## 显示主菜单
func show_main_menu() -> void:
	"""显示主菜单"""
	if current_scene:
		current_scene.queue_free()
	
	# 加载主菜单场景
	main_menu_scene = load("res://scenes/MainMenu.tscn").instantiate()
	get_tree().current_scene.add_child(main_menu_scene)
	current_scene = main_menu_scene
	
	print_debug("[UIManager] Showing main menu")

## 显示关卡选择
func show_level_select() -> void:
	"""显示关卡选择"""
	if current_scene:
		current_scene.queue_free()
	
	level_select_scene = load("res://scenes/LevelSelect.tscn").instantiate()
	get_tree().current_scene.add_child(level_select_scene)
	current_scene = level_select_scene
	
	print_debug("[UIManager] Showing level select")

## 显示战斗场景
func show_battle_scene() -> void:
	"""显示战斗场景"""
	if current_scene:
		current_scene.queue_free()
	
	battle_scene = load("res://scenes/BattleScene.tscn").instantiate()
	get_tree().current_scene.add_child(battle_scene)
	current_scene = battle_scene
	
	# 初始化UI元素
	_initialize_battle_ui()
	
	print_debug("[UIManager] Showing battle scene")

## 显示结果界面
func show_result_screen(success: bool, result: Dictionary) -> void:
	"""显示结果界面"""
	if current_scene:
		current_scene.queue_free()
	
	result_scene = load("res://scenes/ResultScreen.tscn").instantiate()
	result_scene.set_result(success, result)
	get_tree().current_scene.add_child(result_scene)
	current_scene = result_scene
	
	print_debug("[UIManager] Showing result screen: %s" % ("Success" if success else "Failed"))

## 显示商店
func show_shop() -> void:
	"""显示商店"""
	shop_scene = load("res://scenes/Shop.tscn").instantiate()
	get_tree().current_scene.add_child(shop_scene)
	current_scene = shop_scene
	
	print_debug("[UIManager] Showing shop")

## 隐藏商店
func hide_shop() -> void:
	"""隐藏商店"""
	if shop_scene:
		shop_scene.queue_free()
		shop_scene = null

# ============================================================
# UI元素管理
# ============================================================

## 初始化战斗UI
func _initialize_battle_ui() -> void:
	"""初始化战斗场景的UI元素"""
	if not battle_scene:
		return
	
	# 获取UI元素引用
	energy_bar = battle_scene.get_node("%EnergyBar")
	fatigue_bar = battle_scene.get_node("%FatigueBar")
	hunger_bar = battle_scene.get_node("%HungerBar")
	thirst_bar = battle_scene.get_node("%ThirstBar")
	heart_rate_label = battle_scene.get_node("%HeartRateLabel")
	combo_label = battle_scene.get_node("%ComboLabel")
	environmental_value_label = battle_scene.get_node("%EnvironmentalValueLabel")
	distance_label = battle_scene.get_node("%DistanceLabel")
	elevation_label = battle_scene.get_node("%ElevationLabel")
	animation_player = battle_scene.get_node("AnimationPlayer")
	
	# 初始化UI显示
	_update_all_ui()

## 更新所有UI
func _update_all_ui() -> void:
	"""更新所有UI元素"""
	if not battle_scene:
		return
	
	# 更新属性条
	_update_attribute_bars()
	
	# 更新标签
	_update_labels()

## 更新属性条
func _update_attribute_bars() -> void:
	"""更新属性条"""
	if energy_bar:
		energy_bar.value = AttributeSystem.get_energy()
		energy_bar.max_value = AttributeSystem.get_max_energy()
	
	if fatigue_bar:
		fatigue_bar.value = AttributeSystem.get_fatigue()
		fatigue_bar.max_value = AttributeSystem.get_max_fatigue()
	
	if hunger_bar:
		hunger_bar.value = AttributeSystem.get_hunger()
		hunger_bar.max_value = AttributeSystem.get_max_hunger()
	
	if thirst_bar:
		thirst_bar.value = AttributeSystem.get_thirst()
		thirst_bar.max_value = AttributeSystem.get_max_thirst()

## 更新标签
func _update_labels() -> void:
	"""更新标签文本"""
	if heart_rate_label:
		heart_rate_label.text = "心率: %d BPM" % AttributeSystem.get_heart_rate()
	
	if combo_label:
		combo_label.text = "连击: %d" % ComboSystem.get_current_combo()
	
	if environmental_value_label:
		environmental_value_label.text = "环保值: %d" % EconomySystem.get_environmental_value()
	
	if distance_label:
		var layer_info = GameManager.get_current_layer_info()
		distance_label.text = "徒步: %.1f / %.1f km" % [layer_info["distance_so_far"], layer_info["total_distance"]]
	
	if elevation_label:
		elevation_label.text = "爬升: %.0f / %.0f m" % [
			EconomySystem.get_total_elevation_gain(),
			GameManager.current_level_config.get("elevation_gain", 0)
		]

# ============================================================
# 特殊UI效果
# ============================================================

## 显示连击效果
func show_combo_effect(combo_count: int) -> void:
	"""显示连击视觉效果"""
	if animation_player and animation_player.has_animation("combo_effect"):
		animation_player.play("combo_effect")

## 隐藏连击效果
func hide_combo_effect() -> void:
	"""隐藏连击视觉效果"""
	if animation_player and animation_player.is_playing():
		animation_player.stop()

## 播放穿越动画
func play_traverse_animation(card_data: Dictionary) -> void:
	"""播放卡牌穿越动画"""
	if animation_player:
		var animation_name = "traverse_" + card_data["type"]
		if animation_player.has_animation(animation_name):
			animation_player.play(animation_name)
		elif animation_player.has_animation("traverse"):
			animation_player.play("traverse")

## 显示确认对话框
func show_confirmation_dialog(message: String, callback: Callable) -> void:
	"""显示确认对话框"""
	confirmation_callback = callback
	
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.confirmed.connect(_on_confirmation_dialog_confirmed)
	
	battle_scene.add_child(dialog)
	dialog.popup_centered()

## 确认对话框回调
func _on_confirmation_dialog_confirmed() -> void:
	"""确认对话框确认回调"""
	if confirmation_callback.is_valid():
		confirmation_callback.call(true)

## 显示警告对话框
func show_warning_dialog(message: String) -> void:
	"""显示警告对话框"""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	
	battle_scene.add_child(dialog)
	dialog.popup_centered()

# ============================================================
# 信号回调
# ============================================================

## 属性变化回调
func _on_attribute_changed(attribute_name: String, current_value: float, max_value: float) -> void:
	"""属性变化回调"""
	_update_attribute_bars()

## 连击变化回调
func _on_combo_changed(count: int) -> void:
	"""连击变化回调"""
	if combo_label:
		combo_label.text = "连击: %d" % count

## 环保值变化回调
func _on_environmental_value_changed(amount: int) -> void:
	"""环保值变化回调"""
	if environmental_value_label:
		environmental_value_label.text = "环保值: %d" % amount

## 层级变化回调
func _on_level_changed(level_index: int) -> void:
	"""层级变化回调"""
	_update_labels()
