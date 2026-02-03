extends Control

@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton

func _ready() -> void:
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

func set_result(success: bool, result_data: Dictionary) -> void:
	if success:
		title_label.text = "挑战成功！"
		title_label.modulate = Color.GREEN
	else:
		title_label.text = "挑战失败"
		title_label.modulate = Color.RED
		
	var score = result_data.get("score", 0)
	score_label.text = "最终得分: %d" % score

func _on_main_menu_pressed() -> void:
	UIManager.show_main_menu()

func _on_restart_pressed() -> void:
	# 重新加载当前关卡
	# 这里假设 GameManager 有 restart_level 方法，或者重新 start_game
	UIManager.show_battle_scene()
