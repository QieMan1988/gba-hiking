extends Node

var failed: bool = false

func _ready() -> void:
	print("Starting Interaction Logic Test...")
	
	# Wait a frame to ensure Autoloads are ready
	await get_tree().process_frame
	
	_initialize()

func _initialize() -> void:
	# Initialize Managers (already loaded by Autoloads, but let's ensure config)
	ConfigManager.load_all_configs()
	GameManager.load_game_configs()
	
	# Test 1: Verify Interaction Types in Card Data
	_test_interaction_types()
	
	# Test 2: Simulate Click Interaction
	_test_click_interaction()
	
	# Test 3: Simulate Long Press Interaction Logic
	_test_long_press_logic()
	
	if failed:
		print("Test Failed!")
		get_tree().quit(1)
	else:
		print("Test Passed!")
		get_tree().quit(0)

func _test_interaction_types() -> void:
	print("Testing Interaction Types...")
	
	# Ensure level config is loaded and valid
	if GameManager.current_level_config.is_empty():
		# Manually set a mock level config if empty
		GameManager.current_level_config = {
			"id": 999,
			"name": "Test Level",
			"total_layers": 1,
			"layers": [{
				"layer_index": 0,
				"card_count": 4,
				"altitude": 100
			}]
		}
		GameManager.total_layers = 1
	
	# Generate cards
	CardSystem._generate_all_layers_cards()
	
	# Check if generated cards have interaction_type
	var cards = CardSystem.get_current_layer_cards()
	if cards.is_empty():
		_fail("No cards generated")
		return
		
	for card in cards:
		if not card["effects"].has("interaction_type"):
			_fail("Card missing interaction_type: " + card["name"])
			
	print("Interaction Types OK")

func _test_click_interaction() -> void:
	print("Testing Click Interaction...")
	
	# Mock a card with 'click' type
	var mock_card = {
		"id": "mock_click_card",
		"type": "scenery",
		"effects": {
			"interaction_type": "click",
			"environmental_value": 10
		}
	}
	
	# Manually inject into CardSystem for testing
	CardSystem.current_cards[0] = [mock_card]
	GameManager.current_layer_index = 0
	
	# Attempt traverse
	var success = CardSystem.attempt_traverse_card("mock_click_card")
	if not success:
		_fail("Failed to traverse click card")
		
	# Wait for timer (simulation) - In unit test we might need to mock or just check state
	# Since CardSystem uses a Timer node, we can't easily wait in a script without yielding.
	# But attempt_traverse_card returns true if started.
	
	if not CardSystem.is_traversing:
		_fail("CardSystem should be traversing")
		
	# Force finish traversal
	CardSystem._on_traverse_completed()
	
	if CardSystem.is_traversing:
		_fail("CardSystem should not be traversing after completion")
		
	print("Click Interaction OK")

func _test_long_press_logic() -> void:
	print("Testing Long Press Logic...")
	
	# Note: Long press logic is primarily in Battle_UI (frontend), 
	# but CardSystem supports it via attempt_traverse_card.
	# We verify that CardSystem accepts the call regardless of interaction type 
	# (it's UI's job to filter).
	
	var mock_card = {
		"id": "mock_hold_card",
		"type": "terrain",
		"terrain_type": "steep_up",
		"effects": {
			"interaction_type": "long_press",
			"energy_cost": 10
		}
	}
	
	CardSystem.current_cards[0] = [mock_card]
	
	var success = CardSystem.attempt_traverse_card("mock_hold_card")
	if not success:
		_fail("Failed to traverse hold card")
		
	CardSystem._on_traverse_completed()
	print("Long Press Logic OK")

func _fail(message: String) -> void:
	push_error(message)
	failed = true
