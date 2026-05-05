class_name MobileControls
extends Control

signal movement_changed(direction: Vector2)
signal dash_changed(is_pressed: bool)
signal build_factory_pressed
signal build_battery_pressed
signal build_wire_pressed
signal place_pressed
signal cancel_pressed
signal pause_pressed

@onready var joystick_area: Control = $JoystickRoot/TouchArea
@onready var joystick_root: Control = $JoystickRoot
@onready var joystick_knob: Control = $JoystickRoot/TouchArea/Knob
@onready var action_panel: VBoxContainer = $ActionPanel
@onready var dash_button: Button = $ActionPanel/DashButton
@onready var build_row: HBoxContainer = $ActionPanel/BuildRow
@onready var factory_button: Button = $ActionPanel/BuildRow/FactoryButton
@onready var battery_button: Button = $ActionPanel/BuildRow/BatteryButton
@onready var wire_button: Button = $ActionPanel/BuildRow/WireButton
@onready var place_row: HBoxContainer = $ActionPanel/PlaceRow
@onready var place_button: Button = $ActionPanel/PlaceRow/PlaceButton
@onready var cancel_button: Button = $ActionPanel/PlaceRow/CancelButton
@onready var pause_button: Button = $PauseButton

var _active_touch_index := -1
var _direction := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_area.gui_input.connect(_on_joystick_input)
	dash_button.button_down.connect(func(): dash_changed.emit(true))
	dash_button.button_up.connect(func(): dash_changed.emit(false))
	factory_button.pressed.connect(func(): build_factory_pressed.emit())
	battery_button.pressed.connect(func(): build_battery_pressed.emit())
	wire_button.pressed.connect(func(): build_wire_pressed.emit())
	place_button.pressed.connect(func(): place_pressed.emit())
	cancel_button.pressed.connect(func(): cancel_pressed.emit())
	pause_button.pressed.connect(func(): pause_pressed.emit())
	battery_button.text = ""
	set_build_mode(false)
	fit_to_screen(get_viewport_rect().size)
	call_deferred("_reset_joystick")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		fit_to_screen(get_viewport_rect().size)
		_reset_joystick()


func set_build_mode(is_enabled: bool) -> void:
	place_button.visible = is_enabled
	cancel_button.visible = is_enabled
	place_row.visible = is_enabled


func fit_to_screen(viewport_size: Vector2) -> void:
	if joystick_root == null or action_panel == null:
		return

	var compact := viewport_size.x < 720.0 or viewport_size.y < 520.0
	var margin := 12.0 if compact else 22.0
	var joystick_size := clampf(min(viewport_size.x, viewport_size.y) * 0.24, 116.0, 172.0)
	var knob_size := clampf(joystick_size * 0.36, 44.0, 62.0)
	var action_width := clampf(viewport_size.x * (0.34 if compact else 0.24), 178.0, 230.0)
	var action_height := 162.0 if compact else 226.0
	var action_font_size := 12 if compact else 14
	var dash_height := 46.0 if compact else 58.0
	var build_height := 44.0 if compact else 54.0
	var place_height := 44.0 if compact else 54.0
	var pause_width := 76.0 if compact else 94.0
	var pause_height := 38.0 if compact else 44.0

	joystick_root.offset_left = margin
	joystick_root.offset_right = margin + joystick_size
	joystick_root.offset_top = -margin - joystick_size
	joystick_root.offset_bottom = -margin

	joystick_knob.offset_left = (joystick_size - knob_size) * 0.5
	joystick_knob.offset_top = (joystick_size - knob_size) * 0.5
	joystick_knob.offset_right = joystick_knob.offset_left + knob_size
	joystick_knob.offset_bottom = joystick_knob.offset_top + knob_size
	joystick_knob.custom_minimum_size = Vector2(knob_size, knob_size)

	action_panel.offset_left = -margin - action_width
	action_panel.offset_right = -margin
	action_panel.offset_top = -margin - action_height
	action_panel.offset_bottom = -margin
	action_panel.add_theme_constant_override("separation", 6 if compact else 8)

	dash_button.custom_minimum_size = Vector2(action_width, dash_height)
	dash_button.add_theme_font_size_override("font_size", 16 if compact else 18)
	build_row.add_theme_constant_override("separation", 6 if compact else 8)
	place_row.add_theme_constant_override("separation", 6 if compact else 8)

	for button in [factory_button, battery_button, wire_button]:
		button.custom_minimum_size = Vector2(0.0, build_height)
		button.add_theme_font_size_override("font_size", action_font_size)

	place_button.custom_minimum_size = Vector2(action_width * 0.66, place_height)
	cancel_button.custom_minimum_size = Vector2(action_width * 0.28, place_height)
	place_button.add_theme_font_size_override("font_size", action_font_size + 1)
	cancel_button.add_theme_font_size_override("font_size", action_font_size + 1)

	pause_button.offset_left = -margin - pause_width
	pause_button.offset_right = -margin
	pause_button.offset_top = margin
	pause_button.offset_bottom = margin + pause_height
	pause_button.custom_minimum_size = Vector2(pause_width, pause_height)
	pause_button.add_theme_font_size_override("font_size", 14 if compact else 16)
	_reset_joystick()


func set_texts(
	dash_text: String,
	factory_text: String,
	battery_text: String,
	wire_text: String,
	place_text: String,
	cancel_text: String,
	pause_text: String
) -> void:
	dash_button.text = dash_text
	factory_button.text = factory_text
	battery_button.text = ""
	battery_button.tooltip_text = battery_text
	wire_button.text = wire_text
	place_button.text = place_text
	cancel_button.text = cancel_text
	pause_button.text = pause_text


func release_all() -> void:
	_active_touch_index = -1
	dash_changed.emit(false)
	_set_direction(Vector2.ZERO)
	_reset_joystick()


func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_touch_index == -1:
			_active_touch_index = event.index
			_update_joystick(event.position)
		elif not event.pressed and event.index == _active_touch_index:
			_active_touch_index = -1
			_set_direction(Vector2.ZERO)
			_reset_joystick()

	if event is InputEventScreenDrag and event.index == _active_touch_index:
		_update_joystick(event.position)

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			_update_joystick(event.position)
		else:
			_set_direction(Vector2.ZERO)
			_reset_joystick()

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_joystick(event.position)


func _update_joystick(local_position: Vector2) -> void:
	var center := joystick_area.size * 0.5
	var radius = max(1.0, min(joystick_area.size.x, joystick_area.size.y) * 0.5)
	var offset := local_position - center

	if offset.length() > radius:
		offset = offset.normalized() * radius

	joystick_knob.position = center + offset - joystick_knob.size * 0.5
	_set_direction(offset / radius)


func _set_direction(direction: Vector2) -> void:
	var next_direction := direction.limit_length(1.0)

	if next_direction.length_squared() < 0.012:
		next_direction = Vector2.ZERO

	if _direction.is_equal_approx(next_direction):
		return

	_direction = next_direction
	movement_changed.emit(_direction)


func _reset_joystick() -> void:
	if joystick_area == null or joystick_knob == null:
		return

	joystick_knob.position = joystick_area.size * 0.5 - joystick_knob.size * 0.5
