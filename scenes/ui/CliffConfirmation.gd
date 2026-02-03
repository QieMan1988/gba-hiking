extends Control

signal confirmed
signal cancelled

@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/Label
@onready var confirm_button: Button = $Panel/HBoxContainer/ConfirmButton
@onready var cancel_button: Button = $Panel/HBoxContainer/CancelButton

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	hide()

func show_confirmation(message: String = "前方是悬崖，确定要跳下吗？") -> void:
	label.text = message
	show()
	# Ensure it's on top
	move_to_front()

func _on_confirm_pressed() -> void:
	confirmed.emit()
	hide()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide()
