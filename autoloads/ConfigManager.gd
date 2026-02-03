extends Node

signal config_loaded(config_name: String)
signal config_reloaded(config_name: String)
signal config_validation_failed(config_name: String, errors: Array)

const CONFIG_PATHS: Dictionary = {
	"game_config": "res://config/game_config.json",
	"balance_config": "res://config/balance_config.json",
	"card_database": "res://config/card_database.json",
	"level_config": "res://config/level_config.json"
}

const REQUIRED_CONFIG_VERSIONS: Dictionary = {
	"game_config": "1.0.0",
	"balance_config": "1.0",
	"card_database": "1.0",
	"level_config": "1.0"
}

var configs: Dictionary = {}
var config_versions: Dictionary = {}
var config_last_updated: Dictionary = {}

func _ready() -> void:
	load_all_configs()

func load_all_configs() -> void:
	for config_name in CONFIG_PATHS.keys():
		load_config(config_name)

func load_config(config_name: String) -> Dictionary:
	var path = CONFIG_PATHS.get(config_name, "")
	if path.is_empty():
		return {}
	var data = _load_json(path)
	if data.is_empty():
		return {}
	var errors = _validate_config(config_name, data)
	if not errors.is_empty():
		config_validation_failed.emit(config_name, errors)
		return {}
	configs[config_name] = data
	config_versions[config_name] = str(data.get("version", "unknown"))
	config_last_updated[config_name] = str(data.get("last_updated", "unknown"))
	config_loaded.emit(config_name)
	return data

func reload_config(config_name: String) -> bool:
	var data = load_config(config_name)
	if data.is_empty():
		return false
	config_reloaded.emit(config_name)
	return true

func get_config(config_name: String) -> Dictionary:
	return configs.get(config_name, {})

func get_config_value(config_name: String, key: String, default_value = null):
	var data = get_config(config_name)
	return data.get(key, default_value)

func get_config_version(config_name: String) -> String:
	return str(config_versions.get(config_name, "unknown"))

func get_config_last_updated(config_name: String) -> String:
	return str(config_last_updated.get(config_name, "unknown"))

func get_level_config(level_id: int) -> Dictionary:
	var level_config = get_config("level_config")
	var levels = level_config.get("levels", {})
	return levels.get(str(level_id), {})

func get_all_levels() -> Dictionary:
	var level_config = get_config("level_config")
	return level_config.get("levels", {})

func get_card_database() -> Dictionary:
	var card_config = get_config("card_database")
	return card_config.get("cards", {})

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[ConfigManager] Config file not found: %s" % path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("[ConfigManager] JSON parse error: %s" % json.get_error_message())
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("[ConfigManager] Config root is not a Dictionary: %s" % path)
		return {}
	return json.data

func _validate_config(config_name: String, data: Dictionary) -> Array:
	var errors: Array = []
	_validate_meta(config_name, data, errors)
	match config_name:
		"game_config":
			_validate_game_config(data, errors)
		"balance_config":
			_validate_balance_config(data, errors)
		"card_database":
			_validate_card_database(data, errors)
		"level_config":
			_validate_level_config(data, errors)
		_:
			pass
	return errors

func _validate_meta(config_name: String, data: Dictionary, errors: Array) -> void:
	if _require_key(data, "version", TYPE_STRING, errors):
		var version = str(data.get("version", ""))
		if not _is_version_supported(config_name, version):
			errors.append("unsupported_version_%s" % config_name)
	_require_key(data, "last_updated", TYPE_STRING, errors)

func _validate_game_config(data: Dictionary, errors: Array) -> void:
	_require_key(data, "game_info", TYPE_DICTIONARY, errors)
	_require_key(data, "system", TYPE_DICTIONARY, errors)
	_require_key(data, "display", TYPE_DICTIONARY, errors)
	_require_key(data, "audio", TYPE_DICTIONARY, errors)
	_require_key(data, "gameplay", TYPE_DICTIONARY, errors)
	_require_key(data, "controls", TYPE_DICTIONARY, errors)

func _validate_balance_config(data: Dictionary, errors: Array) -> void:
	_require_key(data, "attributes", TYPE_DICTIONARY, errors)
	_require_key(data, "card_balance", TYPE_DICTIONARY, errors)
	_require_key(data, "combo_balance", TYPE_DICTIONARY, errors)
	_require_key(data, "level_balance", TYPE_DICTIONARY, errors)
	_require_key(data, "economy_balance", TYPE_DICTIONARY, errors)

func _validate_card_database(data: Dictionary, errors: Array) -> void:
	if not _require_key(data, "cards", TYPE_DICTIONARY, errors):
		return
	var cards: Dictionary = data.get("cards", {})
	for card_key in cards.keys():
		var card = cards[card_key]
		var prefix = "cards.%s" % str(card_key)
		if typeof(card) != TYPE_DICTIONARY:
			errors.append("invalid_%s" % prefix)
			continue
		_require_number_key(card, "id", errors, prefix)
		_require_key(card, "name", TYPE_STRING, errors, prefix)
		_require_key(card, "type", TYPE_STRING, errors, prefix)
		_require_number_key(card, "tier", errors, prefix)
		_require_key(card, "icon_path", TYPE_STRING, errors, prefix)
		_require_key(card, "description", TYPE_STRING, errors, prefix)
		if _require_key(card, "effects", TYPE_ARRAY, errors, prefix):
			var effects: Array = card.get("effects", [])
			for effect_index in range(effects.size()):
				var effect = effects[effect_index]
				var effect_prefix = "%s.effects.%d" % [prefix, effect_index]
				if typeof(effect) != TYPE_DICTIONARY:
					errors.append("invalid_%s" % effect_prefix)
					continue
				_require_key(effect, "type", TYPE_STRING, errors, effect_prefix)
				_require_number_key(effect, "value", errors, effect_prefix)
		if _require_key(card, "combo_bonus", TYPE_DICTIONARY, errors, prefix):
			var combo_bonus: Dictionary = card.get("combo_bonus", {})
			if not combo_bonus.is_empty():
				_require_key(combo_bonus, "type", TYPE_STRING, errors, "%s.combo_bonus" % prefix)
				_require_number_key(combo_bonus, "value", errors, "%s.combo_bonus" % prefix)

func _validate_level_config(data: Dictionary, errors: Array) -> void:
	if not _require_key(data, "levels", TYPE_DICTIONARY, errors):
		return
	var levels: Dictionary = data.get("levels", {})
	for level_key in levels.keys():
		var level = levels[level_key]
		var prefix = "levels.%s" % str(level_key)
		if typeof(level) != TYPE_DICTIONARY:
			errors.append("invalid_%s" % prefix)
			continue
		_require_number_key(level, "id", errors, prefix)
		_require_key(level, "name", TYPE_STRING, errors, prefix)
		_require_key(level, "phase", TYPE_STRING, errors, prefix)
		_require_number_key(level, "total_layers", errors, prefix)
		_require_number_key(level, "terrain_obstacle_rate", errors, prefix)
		_require_number_key(level, "required_energy", errors, prefix)
		if _require_key(level, "layers", TYPE_ARRAY, errors, prefix):
			var layers: Array = level.get("layers", [])
			if level.has("total_layers") and int(level.get("total_layers", 0)) != layers.size():
				errors.append("mismatch_%s.total_layers" % prefix)
			for layer_index in range(layers.size()):
				var layer = layers[layer_index]
				var layer_prefix = "%s.layers.%d" % [prefix, layer_index]
				if typeof(layer) != TYPE_DICTIONARY:
					errors.append("invalid_%s" % layer_prefix)
					continue
				_require_number_key(layer, "layer_index", errors, layer_prefix)
				_require_number_key(layer, "card_count", errors, layer_prefix)
				_require_number_key(layer, "altitude", errors, layer_prefix)
				if layer.has("background"):
					_require_key(layer, "background", TYPE_STRING, errors, layer_prefix)
				if layer.has("reward_card_id"):
					_require_number_key(layer, "reward_card_id", errors, layer_prefix)
		if level.has("weather"):
			if typeof(level["weather"]) != TYPE_DICTIONARY:
				errors.append("invalid_%s.weather" % prefix)
			else:
				var weather: Dictionary = level["weather"]
				_require_key(weather, "type", TYPE_STRING, errors, "%s.weather" % prefix)
				if weather.has("effects") and typeof(weather["effects"]) != TYPE_DICTIONARY:
					errors.append("invalid_%s.weather.effects" % prefix)

func _is_version_supported(config_name: String, version: String) -> bool:
	var required = str(REQUIRED_CONFIG_VERSIONS.get(config_name, ""))
	if required.is_empty():
		return true
	return _compare_versions(version, required) >= 0

func _compare_versions(left: String, right: String) -> int:
	var left_parts: Array = _parse_version(left)
	var right_parts: Array = _parse_version(right)
	var max_len = max(left_parts.size(), right_parts.size())
	for index in range(max_len):
		var left_value = left_parts[index] if index < left_parts.size() else 0
		var right_value = right_parts[index] if index < right_parts.size() else 0
		if left_value > right_value:
			return 1
		if left_value < right_value:
			return -1
	return 0

func _parse_version(version: String) -> Array:
	var parts: Array = []
	for segment in version.split("."):
		if segment.is_empty():
			parts.append(0)
		else:
			parts.append(int(segment))
	return parts

func _require_key(
	data: Dictionary,
	key: String,
	expected_type: int,
	errors: Array,
	prefix: String = ""
) -> bool:
	var error_key = key if prefix.is_empty() else "%s.%s" % [prefix, key]
	if not data.has(key):
		errors.append("missing_%s" % error_key)
		return false
	if typeof(data[key]) != expected_type:
		errors.append("invalid_%s" % error_key)
		return false
	return true

func _require_number_key(data: Dictionary, key: String, errors: Array, prefix: String = "") -> bool:
	var error_key = key if prefix.is_empty() else "%s.%s" % [prefix, key]
	if not data.has(key):
		errors.append("missing_%s" % error_key)
		return false
	var value_type = typeof(data[key])
	if value_type != TYPE_INT and value_type != TYPE_FLOAT:
		errors.append("invalid_%s" % error_key)
		return false
	return true
