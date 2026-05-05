extends Node

signal controls_changed

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "controls"
const SETTINGS_KEY_PREFIX := "action_"
const ACTIONS := [
	{"name": &"move_up", "label": "control_move_up", "keys": [KEY_W, KEY_UP]},
	{"name": &"move_down", "label": "control_move_down", "keys": [KEY_S, KEY_DOWN]},
	{"name": &"move_left", "label": "control_move_left", "keys": [KEY_A, KEY_LEFT]},
	{"name": &"move_right", "label": "control_move_right", "keys": [KEY_D, KEY_RIGHT]},
	{"name": &"dash", "label": "control_dash", "keys": [KEY_SHIFT]},
	{"name": &"build_factory", "label": "control_build_factory", "keys": [KEY_B]},
	{"name": &"build_battery", "label": "control_build_battery", "keys": [KEY_G]},
	{"name": &"build_wire", "label": "control_build_wire", "keys": [KEY_V]},
	{"name": &"pause", "label": "control_pause", "keys": [KEY_ESCAPE]},
	{"name": &"restart", "label": "control_restart", "keys": [KEY_R]},
]


func _ready() -> void:
	reset_to_defaults(false)
	_load_settings()


func action_count() -> int:
	return ACTIONS.size()


func action_name(index: int) -> StringName:
	var action: Dictionary = ACTIONS[clamp(index, 0, ACTIONS.size() - 1)]
	return action["name"]


func action_label_key(action_name: StringName) -> String:
	for action in ACTIONS:
		if action["name"] == action_name:
			return action["label"]

	return str(action_name)


func action_key_text(action_name: StringName) -> String:
	if not InputMap.has_action(action_name):
		return ""

	var key_names: Array[String] = []

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode

			if keycode != KEY_NONE:
				key_names.append(OS.get_keycode_string(keycode))

	return " / ".join(key_names)


func set_action_key(action_name: StringName, keycode: Key) -> void:
	if keycode == KEY_NONE or not _is_known_action(action_name):
		return

	_set_action_keys(action_name, [keycode])
	save_settings()
	controls_changed.emit()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)

	for action in ACTIONS:
		var action_name: StringName = action["name"]
		config.set_value(SETTINGS_SECTION, SETTINGS_KEY_PREFIX + str(action_name), _action_keycodes(action_name))

	config.save(SETTINGS_PATH)


func reset_settings() -> void:
	reset_to_defaults(true)
	save_settings()
	controls_changed.emit()


func reset_to_defaults(should_clear_saved := true) -> void:
	for action in ACTIONS:
		_set_action_keys(action["name"], action["keys"])

	if should_clear_saved:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)

		for action in ACTIONS:
			config.erase_section_key(SETTINGS_SECTION, SETTINGS_KEY_PREFIX + str(action["name"]))

		config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)

	if error != OK:
		return

	for action in ACTIONS:
		var action_name: StringName = action["name"]
		var saved_value = config.get_value(SETTINGS_SECTION, SETTINGS_KEY_PREFIX + str(action_name), [])
		var keycodes: Array[Key] = []

		if saved_value is Array:
			for value in saved_value:
				var keycode := int(value) as Key

				if keycode != KEY_NONE:
					keycodes.append(keycode)

		if not keycodes.is_empty():
			_set_action_keys(action_name, keycodes)

	controls_changed.emit()


func _set_action_keys(action_name: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	InputMap.action_erase_events(action_name)

	for keycode in keycodes:
		var key_event := InputEventKey.new()
		key_event.keycode = keycode
		InputMap.action_add_event(action_name, key_event)


func _action_keycodes(action_name: StringName) -> Array[int]:
	var keycodes: Array[int] = []

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode

			if keycode != KEY_NONE:
				keycodes.append(keycode)

	return keycodes


func _is_known_action(action_name: StringName) -> bool:
	for action in ACTIONS:
		if action["name"] == action_name:
			return true

	return false
