extends CharacterBody2D

@export var speed := 120.0
@export var damage := 1
@export var damage_interval := 0.8

@onready var visual: Polygon2D = $Visual
@onready var damage_area: Area2D = $DamageArea

var player: Node2D
var active := true
var _touching_player := false
var _damage_timer := 0.0


func _ready() -> void:
	add_to_group("enemy")
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)
	player = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player != null:
		var direction := global_position.direction_to(player.global_position)
		velocity = direction * speed

		if direction.length_squared() > 0.0:
			visual.rotation = direction.angle()
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if _damage_timer > 0.0:
		_damage_timer -= delta

	if _touching_player and _damage_timer <= 0.0 and player != null and player.has_method("take_damage"):
		player.take_damage(damage)
		_damage_timer = damage_interval


func set_active(is_active: bool) -> void:
	active = is_active
	set_process(is_active)
	set_physics_process(is_active)


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_touching_player = true


func _on_damage_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_touching_player = false
