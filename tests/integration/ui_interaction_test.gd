extends Node

var battle_ui: BattleUI
var failed: bool = false

func _ready() -> void:
	print("Starting UI Interaction Test...")
	
	# Wait for autoloads
	await get_tree().process_frame
	
	_setup_ui()
	await _test_long_press_visuals()
	await _test_cliff_confirmation()
	
	if failed:
		print("UI Test Failed!")
		get_tree().quit(1)
	else:
		print("UI Test Passed!")
		get_tree().quit(0)

func _setup_ui() -> void:
	battle_ui = preload("res://scenes/ui/Battle_UI.tscn").instantiate()
	add_child(battle_ui)
	# Force _ready to run immediately if not already (add_child does it)
	await get_tree().process_frame

func _test_long_press_visuals() -> void:
	print("Testing Long Press Visuals...")
	
	# Mock a long press card
	var card_data = {
		"id": "test_lp",
		"name": "Long Press Card",
		"description": "Hold me",
		"effects": {"interaction_type": "long_press"}
	}
	
	# Manually trigger spawn in UI
	battle_ui._create_card_node(card_data)
	await get_tree().process_frame
	
	# Find the card node
	var card_node = battle_ui.cards_container.get_node_or_null("test_lp")
	if not card_node:
		_fail("Card node not created")
		return
		
	# Trigger press
	battle_ui._handle_card_pressed(card_data)
	
	if not battle_ui.is_long_pressing:
		_fail("Long press state not started")
		return
		
	# Check if progress bar is visible
	if not card_node.progress_bar.visible:
		_fail("Progress bar should be visible")
	
	# Simulate process frame for progress update
	# We can't rely on real-time in headless easily without waiting, 
	# but we can verify the state was set.
	
	battle_ui._stop_long_press()
	if battle_ui.is_long_pressing:
		_fail("Long press should stop")
		
	if card_node.progress_bar.visible:
		_fail("Progress bar should hide after stop")

	print("Long Press Visuals OK")

func _test_cliff_confirmation() -> void:
	print("Testing Cliff Confirmation...")
	
	var card_data = {
		"id": "test_cliff",
		"name": "Cliff",
		"description": "Jump?",
		"effects": {"interaction_type": "confirm"}
	}
	
	battle_ui._create_card_node(card_data)
	await get_tree().process_frame
	
	# Trigger release (confirm type triggers on release)
	battle_ui._handle_card_released(card_data)
	
	if not battle_ui.cliff_confirm_panel.visible:
		_fail("Confirmation panel should be visible")
		
	# Test Cancel
	battle_ui._on_cancel_pressed()
	if battle_ui.cliff_confirm_panel.visible:
		_fail("Panel should hide on cancel")
		
	print("Cliff Confirmation OK")

func _fail(msg: String) -> void:
	print("FAIL: " + msg)
	failed = true
