extends Node2D

const CELL_SIZE := 32
const CHUNK_CELLS := 16
const CHUNK_SIZE := CELL_SIZE * CHUNK_CELLS
const UPDATE_INTERVAL := 0.2
const GROUND_BASIC_TEXTURES := [
	preload("res://assets/terrain_tiles/ground_basic_00.png"),
	preload("res://assets/terrain_tiles/ground_basic_01.png"),
	preload("res://assets/terrain_tiles/ground_basic_02.png"),
	preload("res://assets/terrain_tiles/ground_basic_03.png"),
	preload("res://assets/terrain_tiles/ground_basic_04.png"),
	preload("res://assets/terrain_tiles/ground_basic_05.png"),
	preload("res://assets/terrain_tiles/ground_basic_06.png"),
	preload("res://assets/terrain_tiles/ground_basic_07.png"),
]
const GROUND_DETAIL_TEXTURES := [
	preload("res://assets/terrain_tiles/ground_detail_00.png"),
	preload("res://assets/terrain_tiles/ground_detail_01.png"),
	preload("res://assets/terrain_tiles/ground_detail_02.png"),
	preload("res://assets/terrain_tiles/ground_detail_03.png"),
	preload("res://assets/terrain_tiles/ground_detail_04.png"),
	preload("res://assets/terrain_tiles/ground_detail_05.png"),
	preload("res://assets/terrain_tiles/ground_detail_06.png"),
	preload("res://assets/terrain_tiles/ground_detail_07.png"),
]
const CRYSTAL_TEXTURES := [
	preload("res://assets/terrain_tiles/crystal_cluster_00.png"),
	preload("res://assets/terrain_tiles/crystal_cluster_01.png"),
	preload("res://assets/terrain_tiles/crystal_cluster_02.png"),
	preload("res://assets/terrain_tiles/crystal_cluster_03.png"),
	preload("res://assets/terrain_tiles/crystal_cluster_04.png"),
	preload("res://assets/terrain_tiles/crystal_cluster_05.png"),
	preload("res://assets/terrain_tiles/crystal_cluster_06.png"),
	preload("res://assets/terrain_tiles/crystal_cluster_07.png"),
]
const ROCK_TEXTURES := [
	preload("res://assets/terrain_tiles/rock_formation_00.png"),
	preload("res://assets/terrain_tiles/rock_formation_01.png"),
	preload("res://assets/terrain_tiles/rock_formation_02.png"),
	preload("res://assets/terrain_tiles/rock_formation_03.png"),
	preload("res://assets/terrain_tiles/rock_formation_04.png"),
	preload("res://assets/terrain_tiles/rock_formation_05.png"),
	preload("res://assets/terrain_tiles/rock_formation_06.png"),
	preload("res://assets/terrain_tiles/rock_formation_07.png"),
]
const RIFT_EDGE_TEXTURES := [
	preload("res://assets/terrain_tiles/rift_edge_00.png"),
	preload("res://assets/terrain_tiles/rift_edge_01.png"),
	preload("res://assets/terrain_tiles/rift_edge_02.png"),
	preload("res://assets/terrain_tiles/rift_edge_03.png"),
	preload("res://assets/terrain_tiles/rift_edge_04.png"),
	preload("res://assets/terrain_tiles/rift_edge_05.png"),
	preload("res://assets/terrain_tiles/rift_edge_06.png"),
	preload("res://assets/terrain_tiles/rift_edge_07.png"),
]
const RIFT_CORNER_TEXTURES := [
	preload("res://assets/terrain_tiles/rift_corner_00.png"),
	preload("res://assets/terrain_tiles/rift_corner_01.png"),
	preload("res://assets/terrain_tiles/rift_corner_02.png"),
	preload("res://assets/terrain_tiles/rift_corner_03.png"),
	preload("res://assets/terrain_tiles/rift_corner_04.png"),
	preload("res://assets/terrain_tiles/rift_corner_05.png"),
	preload("res://assets/terrain_tiles/rift_corner_06.png"),
	preload("res://assets/terrain_tiles/rift_corner_07.png"),
]
const TRANSITION_TEXTURES := [
	preload("res://assets/terrain_tiles/transition_00.png"),
	preload("res://assets/terrain_tiles/transition_01.png"),
	preload("res://assets/terrain_tiles/transition_02.png"),
	preload("res://assets/terrain_tiles/transition_03.png"),
	preload("res://assets/terrain_tiles/transition_04.png"),
	preload("res://assets/terrain_tiles/transition_05.png"),
	preload("res://assets/terrain_tiles/transition_06.png"),
	preload("res://assets/terrain_tiles/transition_07.png"),
]
const DECOR_TEXTURES := [
	preload("res://assets/terrain_tiles/decor_00.png"),
	preload("res://assets/terrain_tiles/decor_01.png"),
	preload("res://assets/terrain_tiles/decor_02.png"),
	preload("res://assets/terrain_tiles/decor_03.png"),
	preload("res://assets/terrain_tiles/decor_04.png"),
	preload("res://assets/terrain_tiles/decor_05.png"),
	preload("res://assets/terrain_tiles/decor_06.png"),
	preload("res://assets/terrain_tiles/decor_07.png"),
]

enum CellType {
	ASH,
	IRON_DUST,
	CRACKED_STONE,
	ENERGY_SOIL,
	RIFT,
}

@export var world_seed := 20260503
@export var player_path: NodePath
@export var render_radius_chunks := 3

var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var energy_noise := FastNoiseLite.new()
var player: Node2D
var active_chunks: Dictionary = {}
var update_timer := 0.0


func _ready() -> void:
	z_index = -20
	player = get_node_or_null(player_path)
	_setup_noise()
	_update_active_chunks(true)


func _process(delta: float) -> void:
	update_timer -= delta

	if update_timer > 0.0:
		return

	update_timer = UPDATE_INTERVAL
	_update_active_chunks(false)


func is_buildable_position(world_position: Vector2, footprint_radius_cells := 2) -> bool:
	var center_cell := world_to_cell(world_position)

	for y in range(center_cell.y - footprint_radius_cells, center_cell.y + footprint_radius_cells + 1):
		for x in range(center_cell.x - footprint_radius_cells, center_cell.x + footprint_radius_cells + 1):
			if _is_blocked_cell(Vector2i(x, y)):
				return false

	return true


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / CELL_SIZE), floori(world_position.y / CELL_SIZE))


func world_to_chunk(world_position: Vector2) -> Vector2i:
	var cell := world_to_cell(world_position)
	return Vector2i(floori(float(cell.x) / CHUNK_CELLS), floori(float(cell.y) / CHUNK_CELLS))


func _draw() -> void:
	for chunk in active_chunks.keys():
		_draw_chunk(chunk)


func _setup_noise() -> void:
	terrain_noise.seed = world_seed
	terrain_noise.frequency = 0.035
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	detail_noise.seed = world_seed + 97
	detail_noise.frequency = 0.12
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	energy_noise.seed = world_seed + 211
	energy_noise.frequency = 0.055
	energy_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX


func _update_active_chunks(force_redraw: bool) -> void:
	if player == null or not is_instance_valid(player):
		player = get_node_or_null(player_path)

	if player == null:
		return

	var center_chunk := world_to_chunk(player.global_position)
	var next_chunks: Dictionary = {}

	for y in range(center_chunk.y - render_radius_chunks, center_chunk.y + render_radius_chunks + 1):
		for x in range(center_chunk.x - render_radius_chunks, center_chunk.x + render_radius_chunks + 1):
			next_chunks[Vector2i(x, y)] = true

	if force_redraw or not _same_chunk_set(active_chunks, next_chunks):
		active_chunks = next_chunks
		queue_redraw()


func _same_chunk_set(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size():
		return false

	for key in left.keys():
		if not right.has(key):
			return false

	return true


func _draw_chunk(chunk: Vector2i) -> void:
	var chunk_origin := Vector2(chunk.x * CHUNK_SIZE, chunk.y * CHUNK_SIZE)
	draw_rect(Rect2(chunk_origin, Vector2(CHUNK_SIZE, CHUNK_SIZE)), Color(0.055, 0.075, 0.08, 1.0))

	for local_y in range(CHUNK_CELLS):
		for local_x in range(CHUNK_CELLS):
			var cell := Vector2i(chunk.x * CHUNK_CELLS + local_x, chunk.y * CHUNK_CELLS + local_y)
			var cell_position := Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)
			var cell_type := _get_cell_type(cell)
			_draw_cell_texture(cell_position, cell, cell_type)

	_draw_grid_for_chunk(chunk_origin)
	_draw_chunk_decorations(chunk, chunk_origin)


func _draw_cell_texture(cell_position: Vector2, cell: Vector2i, cell_type: CellType) -> void:
	var texture := _get_cell_texture(cell, cell_type)

	if texture == null:
		draw_rect(Rect2(cell_position, Vector2(CELL_SIZE, CELL_SIZE)), _get_cell_color(cell, cell_type))
		return

	draw_texture_rect(texture, Rect2(cell_position, Vector2(CELL_SIZE, CELL_SIZE)), false)


func _draw_grid_for_chunk(chunk_origin: Vector2) -> void:
	var grid_color := Color(0.18, 0.36, 0.34, 0.16)

	for i in range(CHUNK_CELLS + 1):
		var offset := float(i * CELL_SIZE)
		draw_line(chunk_origin + Vector2(offset, 0.0), chunk_origin + Vector2(offset, CHUNK_SIZE), grid_color, 1.0)
		draw_line(chunk_origin + Vector2(0.0, offset), chunk_origin + Vector2(CHUNK_SIZE, offset), grid_color, 1.0)


func _draw_chunk_decorations(chunk: Vector2i, chunk_origin: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _hash_chunk(chunk)

	for i in range(5):
		var position := chunk_origin + Vector2(rng.randf_range(16.0, CHUNK_SIZE - 16.0), rng.randf_range(16.0, CHUNK_SIZE - 16.0))
		var radius := rng.randf_range(1.5, 4.0)
		var color := Color(0.10, 0.22, 0.24, rng.randf_range(0.10, 0.22))
		draw_circle(position, radius, color)


func _draw_rift_cell(cell_position: Vector2, cell: Vector2i) -> void:
	var center := cell_position + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
	var glow := 0.25 + float(_hash_cell(cell) % 100) / 600.0
	draw_rect(Rect2(cell_position + Vector2(4.0, 8.0), Vector2(CELL_SIZE - 8.0, CELL_SIZE - 16.0)), Color(0.05, 0.23, 0.26, glow))
	draw_line(center + Vector2(-10.0, -8.0), center + Vector2(10.0, 8.0), Color(0.17, 0.90, 0.92, 0.28), 1.0)


func _get_cell_texture(cell: Vector2i, cell_type: CellType) -> Texture2D:
	match cell_type:
		CellType.IRON_DUST:
			return _texture_from_array(TRANSITION_TEXTURES if _hash_cell(cell) % 3 == 0 else GROUND_DETAIL_TEXTURES, cell)
		CellType.CRACKED_STONE:
			return _texture_from_array(ROCK_TEXTURES, cell)
		CellType.ENERGY_SOIL:
			if _hash_cell(cell) % 4 == 0:
				return _texture_from_array(CRYSTAL_TEXTURES, cell)

			return _texture_from_array(TRANSITION_TEXTURES, cell)
		CellType.RIFT:
			return _texture_from_array(RIFT_CORNER_TEXTURES if _hash_cell(cell) % 4 == 0 else RIFT_EDGE_TEXTURES, cell)
		_:
			if _hash_cell(cell) % 17 == 0:
				return _texture_from_array(DECOR_TEXTURES, cell)

			if _hash_cell(cell) % 5 == 0:
				return _texture_from_array(GROUND_DETAIL_TEXTURES, cell)

			return _texture_from_array(GROUND_BASIC_TEXTURES, cell)


func _texture_from_array(textures: Array, cell: Vector2i) -> Texture2D:
	if textures.is_empty():
		return null

	var index := _variant_index(cell, textures.size())
	return textures[index] as Texture2D


func _variant_index(cell: Vector2i, count: int) -> int:
	if count <= 0:
		return 0

	return _hash_cell(cell) % count


func _get_cell_type(cell: Vector2i) -> CellType:
	var terrain := terrain_noise.get_noise_2d(cell.x, cell.y)
	var detail := detail_noise.get_noise_2d(cell.x, cell.y)
	var energy := energy_noise.get_noise_2d(cell.x, cell.y)

	if terrain < -0.58 and detail > -0.15:
		return CellType.RIFT

	if detail > 0.68 and terrain > -0.20:
		return CellType.CRACKED_STONE

	if energy > 0.54:
		return CellType.ENERGY_SOIL

	if terrain > 0.34:
		return CellType.IRON_DUST

	return CellType.ASH


func _get_cell_color(cell: Vector2i, cell_type: CellType) -> Color:
	var variation := float(_hash_cell(cell) % 1000) / 1000.0

	match cell_type:
		CellType.IRON_DUST:
			return Color(0.16, 0.135, 0.13, 1.0).lerp(Color(0.25, 0.20, 0.17, 1.0), variation)
		CellType.CRACKED_STONE:
			return Color(0.12, 0.14, 0.15, 1.0).lerp(Color(0.20, 0.22, 0.23, 1.0), variation)
		CellType.ENERGY_SOIL:
			return Color(0.075, 0.12, 0.12, 1.0).lerp(Color(0.09, 0.23, 0.20, 1.0), variation)
		CellType.RIFT:
			return Color(0.035, 0.055, 0.065, 1.0).lerp(Color(0.035, 0.105, 0.12, 1.0), variation)
		_:
			return Color(0.075, 0.09, 0.095, 1.0).lerp(Color(0.12, 0.135, 0.13, 1.0), variation)


func _is_blocked_cell(cell: Vector2i) -> bool:
	var cell_type := _get_cell_type(cell)
	return cell_type == CellType.RIFT or cell_type == CellType.CRACKED_STONE


func _hash_cell(cell: Vector2i) -> int:
	var value := int(cell.x) * 374761393 + int(cell.y) * 668265263 + world_seed * 1442695041
	value = value ^ (value >> 13)
	value *= 1274126177
	return absi(value)


func _hash_chunk(chunk: Vector2i) -> int:
	var value := int(chunk.x) * 1103515245 + int(chunk.y) * 12345 + world_seed * 69069
	value = value ^ (value >> 16)
	return absi(value)
