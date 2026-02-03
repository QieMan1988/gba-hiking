class_name CardUI
extends Control

signal card_pressed(card_data: Dictionary)
signal card_released(card_data: Dictionary)

@onready var background: Panel = $Background
@onready var name_label: Label = $Content/NameLabel
@onready var desc_label: Label = $Content/DescriptionLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var button: Button = $Button # Overlay button for input

var _card_data: Dictionary = {}
var _visual_tween: Tween
var _shake_tween: Tween

func _ready() -> void:
	# Ensure pivots are center for scaling
	pivot_offset = size / 2

func setup(data: Dictionary) -> void:
	_card_data = data
	if name_label: name_label.text = data.get("name", "Unknown")
	if desc_label: desc_label.text = data.get("description", "")
	
	# Reset state
	if progress_bar:
		progress_bar.value = 0
		progress_bar.visible = false
	scale = Vector2.ONE
	rotation_degrees = 0
	
	# Kill existing tweens
	if _visual_tween and _visual_tween.is_valid(): _visual_tween.kill()
	if _shake_tween and _shake_tween.is_valid(): _shake_tween.kill()
	
	# Update pivot on setup as size might have settled
	pivot_offset = size / 2

func start_long_press_visual() -> void:
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	
	# Kill existing tweens
	if _visual_tween and _visual_tween.is_valid(): _visual_tween.kill()
	if _shake_tween and _shake_tween.is_valid(): _shake_tween.kill()
		
	# Scale animation
	_visual_tween = create_tween()
	_visual_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_SINE)
	
	# Shake effect (looping)
	_shake_tween = create_tween()
	_shake_tween.set_loops()
	_shake_tween.tween_property(self, "rotation_degrees", 2.0, 0.05)
	_shake_tween.tween_property(self, "rotation_degrees", -2.0, 0.05)

func update_long_press_visual(progress: float) -> void:
	if progress_bar:
		progress_bar.value = progress * 100

func stop_long_press_visual() -> void:
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0
	
	# Kill tweens
	if _visual_tween and _visual_tween.is_valid(): _visual_tween.kill()
	if _shake_tween and _shake_tween.is_valid(): _shake_tween.kill()
	
	# Reset transform
	var reset_tween = create_tween()
	reset_tween.set_parallel(true)
	reset_tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)
	reset_tween.tween_property(self, "rotation_degrees", 0.0, 0.1)

func _on_button_button_down() -> void:
	card_pressed.emit(_card_data)

func _on_button_button_up() -> void:
	card_released.emit(_card_data)
