extends StaticBody2D

const FACTORY_TEXTURE := preload("res://assets/l1_nord_active_frames/l1_nord_active_00.png")
const ACTIVE_FRAME_TEXTURES := [
	preload("res://assets/l1_nord_active_frames/l1_nord_active_00.png"),
	preload("res://assets/l1_nord_active_frames/l1_nord_active_01.png"),
	preload("res://assets/l1_nord_active_frames/l1_nord_active_02.png"),
	preload("res://assets/l1_nord_active_frames/l1_nord_active_03.png"),
	preload("res://assets/l1_nord_active_frames/l1_nord_active_04.png"),
	preload("res://assets/l1_nord_active_frames/l1_nord_active_05.png"),
	preload("res://assets/l1_nord_active_frames/l1_nord_active_06.png"),
	preload("res://assets/l1_nord_active_frames/l1_nord_active_07.png"),
]
const POWER_CHECK_INTERVAL := 0.25
const SECONDS_PER_HOUR := 3600.0
const ACTIVE_ANIMATION_FPS := 6.0
const FACTORY_SPRITE_POSITION := Vector2(0.0, -36.0)
const FACTORY_SPRITE_SCALE := Vector2(0.78, 0.78)

@export var max_durability := 100
@export var durability := 100
@export var energy_usage_watts_per_hour := 5.0
@export var power_radius_cells := 10
@export var build_grid_size := 32.0

@onready var language = get_node("/root/Language")
@onready var sprite: Sprite2D = $Sprite2D
@onready var status_label: Label = $StatusLabel
@onready var info_button: Button = $InfoButton
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_text: Label = $InfoPanel/Margin/InfoText

var active := false
var power_source: Node
var power_check_timer := 0.0
var active_animation_time := 0.0
var active_frame_index := 0


func _ready() -> void:
	add_to_group("factory")
	durability = clampi(durability, 0, max_durability)
	language.language_changed.connect(_update_text)
	info_button.mouse_entered.connect(_show_info_panel)
	info_button.mouse_exited.connect(_hide_info_panel)
	info_button.pressed.connect(_toggle_info_panel)
	info_panel.visible = false
	set_active(active)
	call_deferred("_refresh_power_state")


func _process(delta: float) -> void:
	power_check_timer -= delta

	if power_check_timer <= 0.0:
		power_check_timer = POWER_CHECK_INTERVAL
		_refresh_power_state()

	if active:
		_consume_energy(delta)

		if active:
			_advance_active_animation(delta)


func set_active(is_active: bool) -> void:
	var was_active := active
	active = is_active and durability > 0
	sprite.position = FACTORY_SPRITE_POSITION
	sprite.scale = FACTORY_SPRITE_SCALE

	if active:
		if not was_active:
			active_animation_time = 0.0
			active_frame_index = 0

		_apply_active_animation_frame()
	else:
		sprite.texture = FACTORY_TEXTURE

	sprite.modulate = Color.WHITE if durability > 0 else Color(0.45, 0.45, 0.5, 1.0)
	_update_text()


func take_damage(amount: int) -> void:
	if amount <= 0 or durability <= 0:
		return

	durability = maxi(durability - amount, 0)

	if durability <= 0:
		power_source = null
		set_active(false)
	else:
		_update_text()


func repair(amount: int) -> void:
	if amount <= 0:
		return

	durability = mini(durability + amount, max_durability)
	_update_text()


func get_power_radius_pixels() -> float:
	return float(power_radius_cells) * build_grid_size


func get_characteristics() -> Dictionary:
	return {
		"durability": durability,
		"max_durability": max_durability,
		"energy_usage_watts_per_hour": energy_usage_watts_per_hour,
		"power_radius_cells": power_radius_cells,
	}


func _advance_active_animation(delta: float) -> void:
	active_animation_time += delta
	active_frame_index = int(active_animation_time * ACTIVE_ANIMATION_FPS) % ACTIVE_FRAME_TEXTURES.size()
	_apply_active_animation_frame()


func _apply_active_animation_frame() -> void:
	sprite.texture = ACTIVE_FRAME_TEXTURES[active_frame_index] if not ACTIVE_FRAME_TEXTURES.is_empty() else FACTORY_TEXTURE


func _update_text() -> void:
	var state_key := "factory_destroyed" if durability <= 0 else ("factory_active" if active else "factory_locked")
	status_label.text = language.t(state_key)
	_update_info_text()


func _update_info_text() -> void:
	var state_text: String = language.t("factory_state_destroyed") if durability <= 0 else (language.t("factory_state_active") if active else language.t("factory_state_unpowered"))
	var power_source_text: String = language.t("power_source_found") if power_source != null and is_instance_valid(power_source) else language.t("power_source_missing")

	info_text.text = language.t("factory_info") % [
		state_text,
		durability,
		max_durability,
		energy_usage_watts_per_hour,
		power_radius_cells,
		power_source_text,
	]


func _show_info_panel() -> void:
	_update_info_text()
	info_panel.visible = true


func _hide_info_panel() -> void:
	info_panel.visible = false


func _toggle_info_panel() -> void:
	if info_panel.visible:
		_hide_info_panel()
	else:
		_show_info_panel()


func _refresh_power_state() -> void:
	if durability <= 0:
		power_source = null
		set_active(false)
		return

	power_source = _find_power_source()
	set_active(power_source != null and _source_has_energy(power_source))


func _consume_energy(delta: float) -> void:
	if power_source == null or not is_instance_valid(power_source):
		_refresh_power_state()
		return

	var required_energy_wh := energy_usage_watts_per_hour * delta / SECONDS_PER_HOUR

	if required_energy_wh <= 0.0:
		return

	if not _consume_from_source(power_source, required_energy_wh):
		power_source = null
		set_active(false)


func _find_power_source() -> Node:
	var direct_source := _find_nearest_valid_node_in_group("battery")

	if direct_source != null:
		return direct_source

	direct_source = _find_nearest_valid_node_in_group("power_source")

	if direct_source != null:
		return direct_source

	var wire := _find_nearest_powered_wire()

	if wire == null:
		return null

	var wire_source := _get_wire_power_source(wire)
	return wire_source if wire_source != null else wire


func _find_nearest_valid_node_in_group(group_name: StringName) -> Node:
	var nearest: Node
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group(group_name):
		if node == self or not node is Node2D:
			continue

		var node_2d := node as Node2D
		var distance := global_position.distance_to(node_2d.global_position)

		if distance > get_power_radius_pixels() or distance >= nearest_distance:
			continue

		if not _source_has_energy(node):
			continue

		nearest = node
		nearest_distance = distance

	return nearest


func _find_nearest_powered_wire() -> Node:
	var nearest := _find_nearest_powered_wire_in_group("power_wire")

	if nearest != null:
		return nearest

	return _find_nearest_powered_wire_in_group("wire")


func _find_nearest_powered_wire_in_group(group_name: StringName) -> Node:
	var nearest: Node
	var nearest_distance := INF

	for wire in get_tree().get_nodes_in_group(group_name):
		if not wire is Node2D:
			continue

		var wire_2d := wire as Node2D
		var distance := global_position.distance_to(wire_2d.global_position)

		if distance > get_power_radius_pixels() or distance >= nearest_distance:
			continue

		if not _wire_has_power(wire):
			continue

		nearest = wire
		nearest_distance = distance

	return nearest


func _source_has_energy(source: Node) -> bool:
	if source == null or not is_instance_valid(source):
		return false

	if source.has_method("has_energy"):
		return bool(source.call("has_energy"))

	if source.has_method("can_supply_energy"):
		return bool(source.call("can_supply_energy", 0.0))

	var stored_energy = source.get("stored_energy_wh")

	if typeof(stored_energy) == TYPE_FLOAT or typeof(stored_energy) == TYPE_INT:
		return float(stored_energy) > 0.0

	var wire_source := _get_wire_power_source(source)

	if wire_source != null and wire_source != source:
		return _source_has_energy(wire_source)

	if source.has_method("is_powered"):
		return bool(source.call("is_powered"))

	return true


func _wire_has_power(wire: Node) -> bool:
	if wire == null or not is_instance_valid(wire):
		return false

	if wire.has_method("is_powered") and bool(wire.call("is_powered")):
		return true

	var powered = wire.get("powered")

	if typeof(powered) == TYPE_BOOL and bool(powered):
		return true

	var wire_source := _get_wire_power_source(wire)
	return wire_source != null and _source_has_energy(wire_source)


func _get_wire_power_source(wire: Node) -> Node:
	if wire == null or not is_instance_valid(wire):
		return null

	if wire.has_method("get_power_source"):
		var method_source = wire.call("get_power_source")

		if method_source is Node:
			return method_source

	var connected_power_source = wire.get("connected_power_source")

	if connected_power_source is Node:
		return connected_power_source

	return null


func _consume_from_source(source: Node, amount_wh: float) -> bool:
	if source == null or not is_instance_valid(source):
		return false

	if amount_wh <= 0.0:
		return _source_has_energy(source)

	var wire_source := _get_wire_power_source(source)

	if wire_source != null and wire_source != source:
		return _consume_from_source(wire_source, amount_wh)

	if source.has_method("consume_energy"):
		return bool(source.call("consume_energy", amount_wh))

	if source.has_method("request_energy"):
		return bool(source.call("request_energy", amount_wh))

	var stored_energy = source.get("stored_energy_wh")

	if typeof(stored_energy) == TYPE_FLOAT or typeof(stored_energy) == TYPE_INT:
		var stored_energy_float := float(stored_energy)

		if stored_energy_float < amount_wh:
			source.set("stored_energy_wh", 0.0)
			return false

		source.set("stored_energy_wh", stored_energy_float - amount_wh)
		return true

	if source.has_method("is_powered"):
		return bool(source.call("is_powered"))

	return true
