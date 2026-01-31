# ============================================================
# 脚本名称：Main_Menu
# 功能描述：主菜单逻辑控制
# 版本号：v1.0
# 创建日期：2026年2月1日
# ============================================================

extends Control
class_name MainMenu

func _ready() -> void:
	pass

func _on_start_game_pressed() -> void:
	# TODO: Transition to BattleScene or CharacterSelection
	pass

func _on_load_game_pressed() -> void:
	pass

func _on_settings_pressed() -> void:
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()
