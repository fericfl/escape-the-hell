extends Area2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO

func _ready():
	visible = false

func _physics_process(delta):
	position += direction * speed * delta
	
	if not get_viewport_rect().has_point(global_position):
			queue_free()

func set_direction(dir: Vector2):
	direction = dir.normalized()
	visible = true

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.take_damage()
		queue_free()
