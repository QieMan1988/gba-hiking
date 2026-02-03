extends SceneTree

var failed: bool = false

func _initialize() -> void:
	GameManager.load_game_configs()
	AttributeSystem.initialize()
	EconomySystem.initialize()
	_prepare_attributes()
	_test_sports_drink()
	_test_chocolate()
	if failed:
		quit(1)
	else:
		quit(0)

func _prepare_attributes() -> void:
	AttributeSystem.apply_attribute_delta("energy", -40.0)
	AttributeSystem.apply_attribute_delta("hunger", 40.0)
	AttributeSystem.apply_attribute_delta("thirst", 40.0)
	AttributeSystem.apply_attribute_delta("fatigue", 10.0)

func _test_sports_drink() -> void:
	SupplySystem.add_supply("sports_drink", 1)
	var before_thirst: float = AttributeSystem.get_attribute("thirst")
	var before_energy: float = AttributeSystem.get_attribute("energy")
	var before_fatigue: float = AttributeSystem.get_attribute("fatigue")
	var consumed: bool = SupplySystem.consume_supply("sports_drink")
	_assert_true(consumed, "sports_drink 消耗失败")
	var after_thirst: float = AttributeSystem.get_attribute("thirst")
	var after_energy: float = AttributeSystem.get_attribute("energy")
	var after_fatigue: float = AttributeSystem.get_attribute("fatigue")
	_assert_true(after_thirst > before_thirst, "sports_drink 未恢复口渴")
	_assert_true(after_energy > before_energy, "sports_drink 未恢复体能")
	_assert_true(after_fatigue < before_fatigue, "sports_drink 未降低疲劳")
	var stats: Dictionary = EconomySystem.get_session_statistics()
	var consumed_supplies: Dictionary = stats.get("supplies_consumed", {})
	_assert_true(int(consumed_supplies.get("sports_drink", 0)) == 1, "sports_drink 消耗未记录")

func _test_chocolate() -> void:
	SupplySystem.add_supply("chocolate", 1)
	var before_hunger: float = AttributeSystem.get_attribute("hunger")
	var before_energy: float = AttributeSystem.get_attribute("energy")
	var consumed: bool = SupplySystem.consume_supply("chocolate")
	_assert_true(consumed, "chocolate 消耗失败")
	var after_hunger: float = AttributeSystem.get_attribute("hunger")
	var after_energy: float = AttributeSystem.get_attribute("energy")
	_assert_true(after_hunger > before_hunger, "chocolate 未恢复饥饿")
	_assert_true(after_energy > before_energy, "chocolate 未恢复体能")
	var stats: Dictionary = EconomySystem.get_session_statistics()
	var consumed_supplies: Dictionary = stats.get("supplies_consumed", {})
	_assert_true(int(consumed_supplies.get("chocolate", 0)) == 1, "chocolate 消耗未记录")

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
