extends Node

var failed: bool = false

func _ready() -> void:
	print("Starting Terrain Generation Test...")
	
	# Wait a frame to ensure Autoloads are ready (though they should be before this scene)
	await get_tree().process_frame
	
	_initialize()

func _initialize() -> void:
	# Autoloads (ConfigManager, GameManager, TerrainSystem) should already be loaded by Godot
	
	# Test 1: Check if TerrainSystem has 8 types
	_test_terrain_constants()
	
	# Test 2: Verify Real Route Level Config
	_test_real_route_config()
	
	# Test 3: Test Terrain Generation Logic
	_test_terrain_generation()
	
	if failed:
		print("Test Failed!")
		get_tree().quit(1)
	else:
		print("Test Passed!")
		get_tree().quit(0)

func _test_terrain_constants() -> void:
	print("Testing Terrain Constants...")
	# Note: We must access TerrainSystem via the global singleton name
	var types = [
		TerrainSystem.TERRAIN_FLAT,
		TerrainSystem.TERRAIN_GENTLE_UP,
		TerrainSystem.TERRAIN_STEEP_UP,
		TerrainSystem.TERRAIN_GENTLE_DOWN,
		TerrainSystem.TERRAIN_STEEP_DOWN,
		TerrainSystem.TERRAIN_STAIRS_UP,
		TerrainSystem.TERRAIN_STAIRS_DOWN,
		TerrainSystem.TERRAIN_CLIFF
	]
	
	for type in types:
		if type == null or type == "":
			_fail("Invalid terrain constant")
	
	# Verify speed modifiers
	if TerrainSystem.get_speed_modifier(TerrainSystem.TERRAIN_STAIRS_UP) != 0.6:
		_fail("Incorrect speed modifier for stairs_up")
		
	# Verify elevation gain
	if TerrainSystem.get_elevation_gain(TerrainSystem.TERRAIN_STAIRS_UP, 1.0) != 200.0:
		_fail("Incorrect elevation gain for stairs_up")
		
	print("Terrain Constants OK")

func _test_real_route_config() -> void:
	print("Testing Real Route Config...")
	var levels = ConfigManager.get_all_levels()
	
	# Check for MacLehose Trail (ID 11)
	if not levels.has("11"):
		_fail("MacLehose Trail (ID 11) missing in level_config")
	else:
		var level = levels["11"]
		if level["name"] != "麦理浩径第一段":
			_fail("MacLehose Trail name incorrect")
			
	# Check for Macau Coloane (ID 12)
	if not levels.has("12"):
		_fail("Macau Coloane Trail (ID 12) missing in level_config")
		
	print("Real Route Config OK")

func _test_terrain_generation() -> void:
	print("Testing Terrain Generation...")
	
	var balance_config = ConfigManager.get_config("balance_config")
	var weights = balance_config.get("terrain_weights", {})
	
	if not weights.has("stairs_up"):
		_fail("stairs_up missing in terrain_weights")
	if not weights.has("stairs_down"):
		_fail("stairs_down missing in terrain_weights")
		
	print("Terrain Generation Weights OK")

func _fail(message: String) -> void:
	push_error(message)
	failed = true
