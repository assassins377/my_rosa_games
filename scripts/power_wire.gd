extends StaticBody2D

const POWER_CHECK_INTERVAL := 0.25

@export var power_source_path: NodePath
@export var powered := false
@export var connection_radius_cells := 6
@export var build_grid_size := 32.0

@onready var sprite: Sprite2D = $Sprite2D

var connected_power_source: Node
var power_check_timer := 0.0


func _ready() -> void:
	add_to_group("power_wire")
	add_to_group("wire")
	_refresh_power_state()
	_update_visual()


func _process(delta: float) -> void:
	power_check_timer -= delta

	if power_check_timer <= 0.0:
		power_check_timer = POWER_CHECK_INTERVAL
		_refresh_power_state()
		_update_visual()


func _draw() -> void:
	var source := get_power_source()

	if source == null or not source is Node2D:
		return

	var source_2d := source as Node2D
	var line_color := Color(0.25, 0.95, 1.0, 0.55) if is_powered() else Color(0.45, 0.45, 0.4, 0.28)
	draw_line(Vector2.ZERO, to_local(source_2d.global_position), line_color, 3.0)


func get_power_source(visited_nodes: Array = []) -> Node:
	var visited := visited_nodes.duplicate()

	if visited.has(get_instance_id()):
		return null

	visited.append(get_instance_id())

	if String(power_source_path) != "":
		var explicit_source := get_node_or_null(power_source_path)
		var explicit_resolved := _resolve_power_source(explicit_source, visited)

		if explicit_resolved != null:
			return explicit_resolved

	if connected_power_source != null and is_instance_valid(connected_power_source):
		var resolved := _resolve_power_source(connected_power_source, visited)

		if resolved != null:
			return resolved

	connected_power_source = _find_nearest_power_source(visited)
	return _resolve_power_source(connected_power_source, visited)


func is_powered() -> bool:
	if powered:
		return true

	return _source_has_energy(get_power_source(), [])


func consume_energy(amount_wh: float) -> bool:
	var source := get_power_source()

	if source == null:
		return is_powered()

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

	return _source_has_energy(source, [])


func get_connection_radius_pixels() -> float:
	return float(connection_radius_cells) * build_grid_size


func _refresh_power_state() -> void:
	connected_power_source = _find_nearest_power_source([])
	queue_redraw()


func _find_nearest_power_source(visited: Array) -> Node:
	var nearest := _find_nearest_node_in_group("battery", visited)

	if nearest != null:
		return nearest

	nearest = _find_nearest_node_in_group("power_source", visited)

	if nearest != null:
		return nearest

	return _find_nearest_wire(visited)


func _find_nearest_node_in_group(group_name: StringName, visited: Array) -> Node:
	var nearest: Node
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group(group_name):
		if node == self or not node is Node2D:
			continue

		if node.is_in_group("power_wire"):
			continue

		var node_2d := node as Node2D
		var distance := global_position.distance_to(node_2d.global_position)

		if distance > get_connection_radius_pixels() or distance >= nearest_distance:
			continue

		if not _source_has_energy(node, visited):
			continue

		nearest = node
		nearest_distance = distance

	return nearest


func _find_nearest_wire(visited: Array) -> Node:
	var nearest: Node
	var nearest_distance := INF

	for node in get_tree().get_nodes_in_group("power_wire"):
		if node == self or not node is Node2D:
			continue

		var node_2d := node as Node2D
		var distance := global_position.distance_to(node_2d.global_position)

		if distance > get_connection_radius_pixels() or distance >= nearest_distance:
			continue

		if visited.has(node.get_instance_id()):
			continue

		var source := _resolve_power_source(node, visited)

		if source == null or not _source_has_energy(source, visited):
			continue

		nearest = node
		nearest_distance = distance

	return nearest


func _resolve_power_source(source: Node, visited: Array) -> Node:
	if source == null or not is_instance_valid(source) or source == self:
		return null

	if source.is_in_group("power_wire") and source.has_method("get_power_source"):
		var resolved = source.call("get_power_source", visited)
		return resolved if resolved is Node else null

	return source


func _source_has_energy(source: Node, visited: Array) -> bool:
	source = _resolve_power_source(source, visited)

	if source == null:
		return false

	if source.has_method("has_energy"):
		return bool(source.call("has_energy"))

	var stored_energy = source.get("stored_energy_wh")

	if typeof(stored_energy) == TYPE_FLOAT or typeof(stored_energy) == TYPE_INT:
		return float(stored_energy) > 0.0

	if source.has_method("is_powered"):
		return bool(source.call("is_powered"))

	return true


func _update_visual() -> void:
	var is_active := is_powered()
	sprite.modulate = Color.WHITE if is_active else Color(0.48, 0.50, 0.50, 0.85)
	queue_redraw()
