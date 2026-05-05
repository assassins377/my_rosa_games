extends Node2D

const BASE_VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const PAUSE_PANEL_MAX_SIZE := Vector2(420.0, 420.0)
const PAUSE_PANEL_MIN_SIZE := Vector2(300.0, 300.0)
const SCREEN_MARGIN := 24.0
const BUILD_GRID_SIZE := 32.0
const FACTORY_FOOTPRINT_RADIUS_CELLS := 2
const BATTERY_FOOTPRINT_RADIUS_CELLS := 1
const WIRE_FOOTPRINT_RADIUS_CELLS := 0
const BUILDING_MIN_DISTANCE := 84.0
const WIRE_BUILDING_MIN_DISTANCE := 48.0
const PLAYER_BUILD_MIN_DISTANCE := 88.0
const FACTORY_SCENE := preload("res://scenes/factory_l1_north.tscn")
const BATTERY_SCENE := preload("res://scenes/battery.tscn")
const WIRE_SCENE := preload("res://scenes/power_wire.tscn")
const FACTORY_TEXTURE := preload("res://assets/l1_nord_active_frames/l1_nord_active_00.png")
const BATTERY_TEXTURE := preload("res://assets/battery_frames/battery_05.png")
const WIRE_TEXTURE := preload("res://assets/power_wire.png")
const FACTORY_GHOST_SCALE := Vector2(0.78, 0.78)
const BATTERY_GHOST_SCALE := Vector2(0.43, 0.43)
const WIRE_GHOST_SCALE := Vector2.ONE
const MOBILE_BUILD_DISTANCE := 128.0
const MOBILE_CONTROLS_MAX_WIDTH := 980.0
const STATUS_MESSAGE_DURATION := 2.0
const CAMERA_ZOOM_MIN := 0.65
const CAMERA_ZOOM_MAX := 2.6
const CAMERA_ZOOM_STEP := 1.12
const HUD_COMPACT_WIDTH := 820.0
const HUD_COMPACT_HEIGHT := 560.0

@onready var language = get_node("/root/Language")
@onready var screen = get_node("/root/Screen")
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var procedural_world: Node2D = $World/ProceduralWorld
@onready var buildings: Node2D = $Buildings
@onready var top_hud: VBoxContainer = $Hud/TopHud
@onready var help_label: Label = $Hud/TopHud/Help
@onready var factories_label: Label = $Hud/TopHud/Goal
@onready var hint_label: Label = $Hud/TopHud/Health
@onready var build_button: Button = $Hud/TopHud/BuildButton
@onready var battery_button: Button = $Hud/TopHud/BatteryButton
@onready var wire_button: Button = $Hud/TopHud/WireButton
@onready var status_label: Label = $Hud/Status
@onready var mobile_controls: MobileControls = $Hud/MobileControls
@onready var pause_overlay: Control = $Hud/PauseOverlay
@onready var pause_panel: PanelContainer = $Hud/PauseOverlay/Panel
@onready var pause_title: Label = $Hud/PauseOverlay/Panel/Margin/VBox/Title
@onready var resume_button: Button = $Hud/PauseOverlay/Panel/Margin/VBox/ResumeButton
@onready var restart_button: Button = $Hud/PauseOverlay/Panel/Margin/VBox/RestartButton
@onready var language_button: Button = $Hud/PauseOverlay/Panel/Margin/VBox/LanguageButton
@onready var menu_button: Button = $Hud/PauseOverlay/Panel/Margin/VBox/MenuButton

var build_mode := false
var build_kind := &""
var game_paused := false
var placed_factories := 0
var placed_batteries := 0
var placed_wires := 0
var ghost_factory: Sprite2D
var _mobile_build_direction := Vector2.RIGHT
var _moving_building: Node2D
var _moving_original_position := Vector2.ZERO
var _status_clear_timer := 0.0
var _adaptive_camera_zoom := 1.0
var _manual_camera_zoom := 1.0


func _ready() -> void:
	_ensure_key_action("restart", [KEY_R])
	_ensure_key_action("pause", [KEY_ESCAPE])
	_ensure_key_action("build_factory", [KEY_B])
	_ensure_key_action("build_battery", [KEY_G])
	_ensure_key_action("build_wire", [KEY_V])

	build_button.pressed.connect(_on_build_button_pressed)
	battery_button.pressed.connect(_on_battery_button_pressed)
	wire_button.pressed.connect(_on_wire_button_pressed)
	mobile_controls.movement_changed.connect(_on_mobile_movement_changed)
	mobile_controls.dash_changed.connect(_on_mobile_dash_changed)
	mobile_controls.build_factory_pressed.connect(_on_build_button_pressed)
	mobile_controls.build_battery_pressed.connect(_on_battery_button_pressed)
	mobile_controls.build_wire_pressed.connect(_on_wire_button_pressed)
	mobile_controls.place_pressed.connect(_on_mobile_place_pressed)
	mobile_controls.cancel_pressed.connect(_on_mobile_cancel_pressed)
	mobile_controls.pause_pressed.connect(_on_mobile_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	language_button.pressed.connect(_on_language_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	language.language_changed.connect(_update_text)
	screen.size_changed.connect(_apply_screen_layout)

	_create_ghost_factory()
	status_label.text = ""
	pause_overlay.visible = false
	_update_text()
	_apply_screen_layout()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if build_mode:
			_cancel_build_mode()
		else:
			_set_paused(not game_paused)

	if Input.is_action_just_pressed("restart"):
		_on_restart_pressed()

	if Input.is_action_just_pressed("build_factory") and not game_paused:
		_toggle_build_mode(&"factory")

	if Input.is_action_just_pressed("build_battery") and not game_paused:
		_toggle_build_mode(&"battery")

	if Input.is_action_just_pressed("build_wire") and not game_paused:
		_toggle_build_mode(&"wire")

	if build_mode:
		_update_ghost_factory()

	_update_status_clear_timer(delta)


func _unhandled_input(event: InputEvent) -> void:
	if game_paused:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0 / CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if build_mode:
			if not _uses_mobile_build_cursor():
				_try_place_building()
				get_viewport().set_input_as_handled()
		elif _try_start_move_building(get_global_mouse_position()):
			get_viewport().set_input_as_handled()

	if event is InputEventScreenTouch and event.pressed:
		var world_position := _screen_to_world(event.position)

		if build_mode:
			if not _uses_mobile_build_cursor():
				_try_place_building(world_position)
				get_viewport().set_input_as_handled()
		elif _try_start_move_building(world_position):
			get_viewport().set_input_as_handled()


func _create_ghost_factory() -> void:
	ghost_factory = Sprite2D.new()
	ghost_factory.texture = FACTORY_TEXTURE
	ghost_factory.scale = FACTORY_GHOST_SCALE
	ghost_factory.z_index = 20
	ghost_factory.visible = false
	add_child(ghost_factory)


func _set_build_mode(is_enabled: bool, should_clear_status := true) -> void:
	if not is_enabled and _moving_building != null and is_instance_valid(_moving_building):
		_moving_building.visible = true
		_moving_building = null

	build_mode = is_enabled
	build_kind = build_kind if build_mode else &""
	_update_ghost_building()
	ghost_factory.visible = build_mode
	mobile_controls.set_build_mode(build_mode)

	if build_mode:
		_status_clear_timer = 0.0
		status_label.text = language.t(_build_status_choose_key())
	elif should_clear_status:
		_clear_status()

	_update_text()


func _toggle_build_mode(kind: StringName) -> void:
	if build_mode and build_kind == kind:
		_cancel_build_mode()
		return

	if _moving_building != null:
		_cancel_build_mode()

	build_kind = kind
	_set_build_mode(true)


func _cancel_build_mode() -> void:
	if _moving_building != null and is_instance_valid(_moving_building):
		_moving_building.global_position = _moving_original_position

	_set_build_mode(false)


func _update_ghost_building() -> void:
	if ghost_factory == null:
		return

	if _moving_building != null and is_instance_valid(_moving_building):
		var moved_sprite := _moving_building.get_node_or_null("Sprite2D") as Sprite2D

		if moved_sprite != null:
			ghost_factory.texture = moved_sprite.texture
			ghost_factory.scale = moved_sprite.scale

		return

	if build_kind == &"battery":
		ghost_factory.texture = BATTERY_TEXTURE
		ghost_factory.scale = BATTERY_GHOST_SCALE
	elif build_kind == &"wire":
		ghost_factory.texture = WIRE_TEXTURE
		ghost_factory.scale = WIRE_GHOST_SCALE
	else:
		ghost_factory.texture = FACTORY_TEXTURE
		ghost_factory.scale = FACTORY_GHOST_SCALE


func _update_ghost_factory() -> void:
	var build_position := _get_snapped_build_position()
	var can_place := _can_place_selected_building(build_position)
	var ghost_offset := _selected_building_ghost_offset()
	ghost_factory.global_position = build_position + ghost_offset
	ghost_factory.modulate = Color(0.35, 1.0, 1.0, 0.48) if can_place else Color(1.0, 0.25, 0.25, 0.45)


func _try_place_building(world_position := Vector2.INF) -> void:
	var build_position := _get_snapped_build_position(world_position)

	if not _can_place_selected_building(build_position):
		status_label.text = language.t("build_status_blocked")
		return

	if _moving_building != null and is_instance_valid(_moving_building):
		var moved_building := _moving_building
		var status_key := _move_status_placed_key()
		moved_building.global_position = build_position
		moved_building.visible = true
		_refresh_moved_building(moved_building)
		_set_build_mode(false, false)
		_show_temporary_status(language.t(status_key))
	elif build_kind == &"battery":
		var battery = BATTERY_SCENE.instantiate()
		buildings.add_child(battery)
		battery.global_position = build_position
		placed_batteries += 1
		_refresh_power_network()
		_set_build_mode(false, false)
		_show_temporary_status(language.t("build_status_battery_placed"))
	elif build_kind == &"wire":
		var wire = WIRE_SCENE.instantiate()
		buildings.add_child(wire)
		wire.global_position = build_position
		placed_wires += 1
		_refresh_power_network()
		_set_build_mode(false, false)
		_show_temporary_status(language.t("build_status_wire_placed"))
	else:
		var factory = FACTORY_SCENE.instantiate()
		buildings.add_child(factory)
		factory.global_position = build_position
		factory.set_active(false)
		placed_factories += 1
		_refresh_power_network()
		_set_build_mode(false, false)
		_show_temporary_status(language.t("build_status_placed"))

	_update_text()


func _get_snapped_build_position(world_position := Vector2.INF) -> Vector2:
	var mouse_position := world_position

	if mouse_position == Vector2.INF:
		mouse_position = _get_mobile_build_position() if _uses_mobile_build_cursor() else get_global_mouse_position()

	return Vector2(
		round(mouse_position.x / BUILD_GRID_SIZE) * BUILD_GRID_SIZE,
		round(mouse_position.y / BUILD_GRID_SIZE) * BUILD_GRID_SIZE
	)


func _uses_mobile_build_cursor() -> bool:
	return mobile_controls.visible


func _get_mobile_build_position() -> Vector2:
	var direction := _mobile_build_direction

	if player.has_method("get_facing_direction"):
		direction = player.call("get_facing_direction")

	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT

	_mobile_build_direction = direction.normalized()
	return player.global_position + _mobile_build_direction * MOBILE_BUILD_DISTANCE


func _can_place_selected_building(build_position: Vector2) -> bool:
	var footprint := _selected_building_footprint_radius()
	return _can_place_building(build_position, footprint)


func _selected_building_footprint_radius() -> int:
	if build_kind == &"battery":
		return BATTERY_FOOTPRINT_RADIUS_CELLS

	if build_kind == &"wire":
		return WIRE_FOOTPRINT_RADIUS_CELLS

	return FACTORY_FOOTPRINT_RADIUS_CELLS


func _selected_building_ghost_offset() -> Vector2:
	if build_kind == &"battery":
		return Vector2(0.0, -20.0)

	if build_kind == &"wire":
		return Vector2.ZERO

	return Vector2(0.0, -36.0)


func _can_place_building(build_position: Vector2, footprint_radius_cells: int) -> bool:
	if procedural_world.has_method("is_buildable_position") and not procedural_world.call("is_buildable_position", build_position, footprint_radius_cells):
		return false

	if build_position.distance_to(player.global_position) < PLAYER_BUILD_MIN_DISTANCE:
		return false

	for building in buildings.get_children():
		if building == _moving_building:
			continue

		if building is Node2D and build_position.distance_to(building.global_position) < _selected_building_min_distance():
			return false

	return true


func _selected_building_min_distance() -> float:
	return WIRE_BUILDING_MIN_DISTANCE if build_kind == &"wire" else BUILDING_MIN_DISTANCE


func _try_start_move_building(world_position: Vector2) -> bool:
	var building := _find_building_at(world_position)

	if building == null:
		return false

	_moving_building = building
	_moving_original_position = building.global_position
	build_kind = _get_building_kind(building)
	_moving_building.visible = false
	_set_build_mode(true)
	return true


func _find_building_at(world_position: Vector2) -> Node2D:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var results := space_state.intersect_point(query, 16)

	for result in results:
		var collider = result.get("collider")

		if collider is Node:
			var building := _get_building_from_node(collider)

			if building != null:
				return building

	var nearest_building: Node2D
	var nearest_distance := INF

	for building in buildings.get_children():
		if not building is Node2D or not building.visible:
			continue

		var building_2d := building as Node2D
		var distance := world_position.distance_to(building_2d.global_position)
		var selection_radius := 92.0 if _get_building_kind(building_2d) == &"factory" else 72.0

		if distance <= selection_radius and distance < nearest_distance:
			nearest_building = building_2d
			nearest_distance = distance

	return nearest_building


func _get_building_from_node(node: Node) -> Node2D:
	var current := node

	while current != null and current != buildings:
		if current.get_parent() == buildings and current is Node2D:
			return current as Node2D

		current = current.get_parent()

	return null


func _get_building_kind(building: Node) -> StringName:
	if building.is_in_group("wire") or building.is_in_group("power_wire"):
		return &"wire"

	if building.is_in_group("battery"):
		return &"battery"

	return &"factory"


func _refresh_moved_building(building: Node) -> void:
	if building.has_method("_refresh_power_state"):
		building.call_deferred("_refresh_power_state")

	if building.has_method("_update_visual"):
		building.call_deferred("_update_visual")

	_refresh_power_network()


func _refresh_power_network() -> void:
	for building in buildings.get_children():
		if building.has_method("_refresh_power_state"):
			building.call_deferred("_refresh_power_state")


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _show_temporary_status(text: String) -> void:
	status_label.text = text
	_status_clear_timer = STATUS_MESSAGE_DURATION


func _clear_status() -> void:
	status_label.text = ""
	_status_clear_timer = 0.0


func _update_status_clear_timer(delta: float) -> void:
	if _status_clear_timer <= 0.0:
		return

	_status_clear_timer -= delta

	if _status_clear_timer <= 0.0 and not build_mode:
		_clear_status()


func _update_text() -> void:
	help_label.text = language.t("game_help_builder")
	factories_label.text = language.t("game_buildings") % [placed_factories, placed_batteries, placed_wires]
	hint_label.text = language.t("move_hint_active") if _moving_building != null else (language.t("build_hint_active") if build_mode else language.t("build_hint_idle"))
	build_button.text = language.t("move_button_cancel") if _moving_building != null and build_kind == &"factory" else (language.t("build_button_cancel") if build_mode and build_kind == &"factory" else language.t("build_button"))
	battery_button.text = language.t("move_button_cancel") if _moving_building != null and build_kind == &"battery" else (language.t("build_battery_button_cancel") if build_mode and build_kind == &"battery" else language.t("build_battery_button"))
	wire_button.text = language.t("move_button_cancel") if _moving_building != null and build_kind == &"wire" else (language.t("build_wire_button_cancel") if build_mode and build_kind == &"wire" else language.t("build_wire_button"))
	pause_title.text = language.t("pause_title")
	resume_button.text = language.t("pause_resume")
	restart_button.text = language.t("pause_restart")
	language_button.text = language.t("language_button") % language.current_language_name()
	menu_button.text = language.t("pause_menu")
	mobile_controls.set_texts(
		language.t("mobile_dash"),
		language.t("mobile_factory"),
		language.t("mobile_battery"),
		language.t("mobile_wire"),
		language.t("mobile_place"),
		language.t("mobile_cancel"),
		language.t("mobile_pause")
	)


func _apply_screen_layout() -> void:
	_fit_pause_panel()
	_update_camera_zoom()
	_update_mobile_controls_visibility()
	_fit_game_hud_layout()


func _fit_pause_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var available_size := viewport_size - Vector2(SCREEN_MARGIN * 2.0, SCREEN_MARGIN * 2.0)
	var panel_width = min(PAUSE_PANEL_MAX_SIZE.x, max(PAUSE_PANEL_MIN_SIZE.x, available_size.x))
	var panel_height = min(PAUSE_PANEL_MAX_SIZE.y, max(PAUSE_PANEL_MIN_SIZE.y, available_size.y))

	pause_panel.offset_left = -panel_width * 0.5
	pause_panel.offset_top = -panel_height * 0.5
	pause_panel.offset_right = panel_width * 0.5
	pause_panel.offset_bottom = panel_height * 0.5


func _update_camera_zoom() -> void:
	var viewport_size := get_viewport_rect().size
	_adaptive_camera_zoom = max(
		viewport_size.x / BASE_VIEWPORT_SIZE.x,
		viewport_size.y / BASE_VIEWPORT_SIZE.y
	)
	_adaptive_camera_zoom = clampf(_adaptive_camera_zoom, 0.75, 2.5)
	_apply_camera_zoom()


func _zoom_camera(multiplier: float) -> void:
	_manual_camera_zoom = clampf(
		_manual_camera_zoom * multiplier,
		CAMERA_ZOOM_MIN / _adaptive_camera_zoom,
		CAMERA_ZOOM_MAX / _adaptive_camera_zoom
	)
	_apply_camera_zoom()


func _apply_camera_zoom() -> void:
	var zoom_value := clampf(_adaptive_camera_zoom * _manual_camera_zoom, CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
	camera.zoom = Vector2.ONE * zoom_value


func _set_paused(is_paused: bool) -> void:
	game_paused = is_paused
	pause_overlay.visible = is_paused
	player.set_process(not is_paused)
	player.set_physics_process(not is_paused)

	if is_paused:
		mobile_controls.release_all()
		ghost_factory.visible = false
		resume_button.grab_focus()
	else:
		ghost_factory.visible = build_mode
		_update_mobile_controls_visibility()


func _on_build_button_pressed() -> void:
	_toggle_build_mode(&"factory")


func _on_battery_button_pressed() -> void:
	_toggle_build_mode(&"battery")


func _on_wire_button_pressed() -> void:
	_toggle_build_mode(&"wire")


func _on_mobile_movement_changed(direction: Vector2) -> void:
	if direction.length_squared() > 0.0:
		_mobile_build_direction = direction.normalized()

	if player.has_method("set_mobile_movement"):
		player.call("set_mobile_movement", direction)


func _on_mobile_dash_changed(is_pressed: bool) -> void:
	if player.has_method("set_mobile_dash"):
		player.call("set_mobile_dash", is_pressed)


func _on_mobile_place_pressed() -> void:
	if build_mode and not game_paused:
		_try_place_building()


func _on_mobile_cancel_pressed() -> void:
	if build_mode:
		_cancel_build_mode()


func _on_mobile_pause_pressed() -> void:
	if build_mode:
		_cancel_build_mode()
	else:
		_set_paused(not game_paused)


func _build_status_choose_key() -> String:
	if _moving_building != null:
		if build_kind == &"battery":
			return "move_status_choose_battery"

		if build_kind == &"wire":
			return "move_status_choose_wire"

		return "move_status_choose_factory"

	if build_kind == &"battery":
		return "build_status_choose_battery"

	if build_kind == &"wire":
		return "build_status_choose_wire"

	return "build_status_choose"


func _move_status_placed_key() -> String:
	if build_kind == &"battery":
		return "move_status_placed_battery"

	if build_kind == &"wire":
		return "move_status_placed_wire"

	return "move_status_placed_factory"


func _on_resume_pressed() -> void:
	_set_paused(false)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_language_pressed() -> void:
	language.toggle_language()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _update_mobile_controls_visibility() -> void:
	var viewport_size := get_viewport_rect().size
	var should_show := OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available() or viewport_size.x <= MOBILE_CONTROLS_MAX_WIDTH
	mobile_controls.visible = should_show and not game_paused
	build_button.visible = not mobile_controls.visible
	battery_button.visible = not mobile_controls.visible
	wire_button.visible = not mobile_controls.visible
	mobile_controls.fit_to_screen(viewport_size)

	if not mobile_controls.visible:
		mobile_controls.release_all()
	else:
		mobile_controls.set_build_mode(build_mode)


func _fit_game_hud_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var is_compact := mobile_controls.visible or viewport_size.x <= HUD_COMPACT_WIDTH or viewport_size.y <= HUD_COMPACT_HEIGHT
	var margin := 12.0 if is_compact else 24.0
	var hud_height := 106.0 if is_compact else 220.0
	var label_font_size := 12 if is_compact else 14
	var hint_font_size := 11 if is_compact else 14
	var status_font_size := 18 if is_compact else 24
	var button_width := clampf(viewport_size.x * 0.24, 180.0, 220.0)
	var button_height := 36.0 if viewport_size.y <= HUD_COMPACT_HEIGHT else 40.0

	top_hud.offset_left = margin
	top_hud.offset_top = margin
	top_hud.offset_right = -margin
	top_hud.offset_bottom = margin + hud_height
	top_hud.add_theme_constant_override("separation", 2 if is_compact else 4)

	help_label.visible = not is_compact
	help_label.add_theme_font_size_override("font_size", label_font_size)
	factories_label.add_theme_font_size_override("font_size", label_font_size)
	hint_label.add_theme_font_size_override("font_size", hint_font_size)

	for button in [build_button, battery_button, wire_button]:
		button.custom_minimum_size = Vector2(button_width, button_height)
		button.add_theme_font_size_override("font_size", 14 if is_compact else 16)

	status_label.anchor_left = 0.05 if is_compact else 0.08
	status_label.anchor_top = 0.34 if is_compact else 0.42
	status_label.anchor_right = 0.95 if is_compact else 0.92
	status_label.anchor_bottom = 0.52 if is_compact else 0.58
	status_label.add_theme_font_size_override("font_size", status_font_size)


func _ensure_key_action(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	if not InputMap.action_get_events(action_name).is_empty():
		return

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
