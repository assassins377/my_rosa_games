extends Node

signal size_changed
signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "screen"
const SETTINGS_RESOLUTION_KEY := "resolution_index"
const SETTINGS_FULLSCREEN_KEY := "fullscreen"
const DEFAULT_RESOLUTION_INDEX := 2
const SCREEN_MODE_WINDOWED := 0
const SCREEN_MODE_FULLSCREEN := 1
const MIN_WINDOW_SIZE := Vector2i(800, 450)
const RESOLUTIONS := [
	Vector2i(800, 450),
	Vector2i(1024, 576),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

var selected_resolution_index := DEFAULT_RESOLUTION_INDEX


func _ready() -> void:
	get_window().min_size = MIN_WINDOW_SIZE
	_ensure_key_action("fullscreen", [KEY_F11])
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_load_settings()
	_apply_screen_settings(false)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		toggle_fullscreen()


func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())


func set_fullscreen(is_enabled: bool) -> void:
	var window := get_window()

	if is_enabled:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		_apply_windowed_resolution()

	settings_changed.emit()
	_save_settings()


func is_fullscreen() -> bool:
	var mode := get_window().mode
	return mode == Window.MODE_FULLSCREEN or mode == Window.MODE_EXCLUSIVE_FULLSCREEN


func screen_mode_count() -> int:
	return 2


func current_screen_mode_index() -> int:
	return SCREEN_MODE_FULLSCREEN if is_fullscreen() else SCREEN_MODE_WINDOWED


func set_screen_mode(mode_index: int) -> void:
	set_fullscreen(mode_index == SCREEN_MODE_FULLSCREEN)


func resolution_count() -> int:
	return RESOLUTIONS.size()


func resolution_label(index: int) -> String:
	var resolution: Vector2i = RESOLUTIONS[clamp(index, 0, RESOLUTIONS.size() - 1)]
	return "%dx%d" % [resolution.x, resolution.y]


func set_resolution_index(index: int) -> void:
	selected_resolution_index = clamp(index, 0, RESOLUTIONS.size() - 1)
	get_window().mode = Window.MODE_WINDOWED
	_apply_windowed_resolution()

	settings_changed.emit()
	_save_settings()


func current_resolution_label() -> String:
	return resolution_label(selected_resolution_index)


func save_settings() -> void:
	_save_settings()


func reset_settings() -> void:
	selected_resolution_index = DEFAULT_RESOLUTION_INDEX
	get_window().mode = Window.MODE_WINDOWED
	_apply_windowed_resolution()
	_save_settings()
	settings_changed.emit()


func _apply_screen_settings(should_emit: bool) -> void:
	if is_fullscreen():
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		_apply_windowed_resolution()

	if should_emit:
		settings_changed.emit()


func _apply_windowed_resolution() -> void:
	var window := get_window()
	var resolution: Vector2i = RESOLUTIONS[selected_resolution_index]

	window.mode = Window.MODE_WINDOWED
	window.size = resolution


func _load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)

	if error != OK:
		return

	selected_resolution_index = int(config.get_value(
		SETTINGS_SECTION,
		SETTINGS_RESOLUTION_KEY,
		selected_resolution_index
	))
	selected_resolution_index = clamp(selected_resolution_index, 0, RESOLUTIONS.size() - 1)

	if bool(config.get_value(SETTINGS_SECTION, SETTINGS_FULLSCREEN_KEY, false)):
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_RESOLUTION_KEY, selected_resolution_index)
	config.set_value(SETTINGS_SECTION, SETTINGS_FULLSCREEN_KEY, is_fullscreen())
	config.save(SETTINGS_PATH)


func _on_viewport_size_changed() -> void:
	size_changed.emit()


func _ensure_key_action(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keycodes:
		var action_has_key := false

		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.keycode == keycode:
				action_has_key = true
				break

		if action_has_key:
			continue

		var key_event := InputEventKey.new()
		key_event.keycode = keycode
		InputMap.action_add_event(action_name, key_event)
