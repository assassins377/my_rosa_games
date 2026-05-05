extends Area2D

signal collected(crystal: Area2D)

@onready var visual: Polygon2D = $Visual

var _bob_time := 0.0


func _ready() -> void:
	add_to_group("crystal")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_bob_time += delta
	visual.position.y = sin(_bob_time * 4.0) * 4.0
	visual.rotation += delta * 1.5


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	collected.emit(self)
	queue_free()
