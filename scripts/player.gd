extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

const PLAYER_DIRECTIONS := ["up", "up_right", "right", "down_right", "down", "down_left", "left", "up_left"]
const PLAYER_FRAME_COUNT := 4

@export var speed := 240.0
@export var dash_multiplier := 1.6
@export var max_health := 3
@export var damage_cooldown := 0.8
@export var animation_fps := 8.0

@onready var visual: AnimatedSprite2D = $Visual
@onready var health_fill: ColorRect = $HealthBar/Fill
@onready var health_label: Label = $HealthBar/HealthLabel

var health := max_health
var _damage_timer := 0.0
var _is_alive := true
var _mobile_movement := Vector2.ZERO
var _mobile_dash_pressed := false
var _facing_direction := Vector2.DOWN
var _facing_animation := "down"


func _ready() -> void:
	add_to_group("player")
	_ensure_default_input()
	_setup_visual_animations()
	_update_movement_animation(Vector2.ZERO)
	health = max_health
	_update_health_bar()
	health_changed.emit(health, max_health)


func _process(delta: float) -> void:
	if _damage_timer > 0.0:
		_damage_timer -= delta
		visual.modulate = Color(1.0, 0.45, 0.45, 1.0)
	else:
		visual.modulate = Color.WHITE


func _physics_process(_delta: float) -> void:
	if not _is_alive:
		velocity = Vector2.ZERO
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _mobile_movement.length_squared() > 0.0:
		input_direction = _mobile_movement

	var current_speed := speed

	if Input.is_action_pressed("dash") or _mobile_dash_pressed:
		current_speed *= dash_multiplier

	velocity = input_direction * current_speed

	if input_direction.length_squared() > 0.0:
		_facing_direction = input_direction.normalized()

	_update_movement_animation(input_direction)
	move_and_slide()


func set_mobile_movement(direction: Vector2) -> void:
	_mobile_movement = direction.limit_length(1.0)


func set_mobile_dash(is_pressed: bool) -> void:
	_mobile_dash_pressed = is_pressed


func get_facing_direction() -> Vector2:
	return _facing_direction


func _setup_visual_animations() -> void:
	var sprite_frames := SpriteFrames.new()

	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

	for direction_index in range(PLAYER_DIRECTIONS.size()):
		var direction_name: String = PLAYER_DIRECTIONS[direction_index]
		var walk_animation := StringName("walk_" + direction_name)
		var idle_animation := StringName("idle_" + direction_name)

		sprite_frames.add_animation(walk_animation)
		sprite_frames.set_animation_speed(walk_animation, animation_fps)
		sprite_frames.set_animation_loop(walk_animation, true)

		for frame_index in range(PLAYER_FRAME_COUNT):
			var walk_texture := _load_player_frame(direction_name, frame_index)

			if walk_texture != null:
				sprite_frames.add_frame(walk_animation, walk_texture)

		sprite_frames.add_animation(idle_animation)
		sprite_frames.set_animation_speed(idle_animation, 1.0)
		sprite_frames.set_animation_loop(idle_animation, false)

		var idle_texture := _load_player_frame(direction_name, 0)

		if idle_texture != null:
			sprite_frames.add_frame(idle_animation, idle_texture)

	visual.sprite_frames = sprite_frames


func _load_player_frame(direction_name: String, frame_index: int) -> Texture2D:
	var frame_suffix := str(frame_index)

	if frame_index < 10:
		frame_suffix = "0" + frame_suffix

	var frame_path := "res://assets/player_frames/%s_%s.png" % [direction_name, frame_suffix]
	return load(frame_path) as Texture2D


func _update_movement_animation(input_direction: Vector2) -> void:
	if visual.sprite_frames == null:
		return

	var is_moving := input_direction.length_squared() > 0.0

	if is_moving:
		_facing_animation = _direction_to_animation_name(input_direction.normalized())

	var animation_name := StringName(("walk_" if is_moving else "idle_") + _facing_animation)

	if not visual.sprite_frames.has_animation(animation_name):
		return

	if is_moving:
		if visual.animation != animation_name:
			visual.play(animation_name)
		elif not visual.is_playing():
			visual.play()
	else:
		if visual.animation != animation_name:
			visual.animation = animation_name

		visual.stop()
		visual.frame = 0


func _direction_to_animation_name(direction: Vector2) -> String:
	if direction.length_squared() == 0.0:
		return _facing_animation

	var x_strength := absf(direction.x)
	var y_strength := absf(direction.y)
	var diagonal_threshold := 0.35

	if x_strength > diagonal_threshold and y_strength > diagonal_threshold:
		if direction.x > 0.0 and direction.y < 0.0:
			return "up_right"

		if direction.x > 0.0 and direction.y > 0.0:
			return "down_right"

		if direction.x < 0.0 and direction.y > 0.0:
			return "down_left"

		return "up_left"

	if x_strength >= y_strength:
		return "right" if direction.x >= 0.0 else "left"

	return "down" if direction.y >= 0.0 else "up"


func take_damage(amount: int) -> void:
	if not _is_alive or _damage_timer > 0.0:
		return

	health = max(health - amount, 0)
	_damage_timer = damage_cooldown
	_update_health_bar()
	health_changed.emit(health, max_health)

	if health == 0:
		_is_alive = false
		died.emit()


func _update_health_bar() -> void:
	var health_ratio := 0.0

	if max_health > 0:
		health_ratio = float(health) / float(max_health)

	health_fill.scale.x = clamp(health_ratio, 0.0, 1.0)
	health_label.text = "%d / %d" % [health, max_health]


func _ensure_default_input() -> void:
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("move_up", [KEY_W, KEY_UP])
	_ensure_key_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_key_action("dash", [KEY_SHIFT])
	_ensure_key_action("restart", [KEY_R])


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
