# ============================================================
# 脚本名称：Main_Menu
# 功能描述：主菜单逻辑控制
# 版本号：v1.0
# 创建日期：2026年2月1日
# ============================================================

class_name MainMenu
extends Control

const BATTLE_SCENE_PATH = "res://scenes/battle/Battle_Scene.tscn"

@onready var start_game_button: Button = $VBoxContainer/StartGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

func _ready() -> void:
	print("Buttons found:")
	print("StartGameButton: ", start_game_button)
	
	if start_game_button:
		var res = start_game_button.pressed.connect(_on_start_game_pressed)
		print("StartGameButton connection result: ", res)
	else:
		printerr("StartGameButton is null!")
		
	if load_game_button:
		load_game_button.pressed.connect(_on_load_game_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
		
	print("[MainMenu] Initialized")
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Mouse Click at: ", event.position)
		# Check what is under the mouse
		# var control = get_viewport().gui_get_focus_owner() # Focus might not be set yet

func _on_start_game_pressed() -> void:
	print("[MainMenu] Starting Game -> " + BATTLE_SCENE_PATH)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)

func _on_load_game_pressed() -> void:
	print("[MainMenu] Load Game not implemented")

func _on_settings_pressed() -> void:
	print("[MainMenu] Settings not implemented")

func _on_exit_pressed() -> void:
	print("[MainMenu] Exiting Game")
	get_tree().quit()
