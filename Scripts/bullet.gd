extends Area2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
var bullet_owner: String = ""

func _ready():
	visible = false

func _physics_process(delta):
	position += direction * speed * delta

func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = direction.angle()
	$Bullet.flip_v = direction.x < 0
	visible = true

func _on_body_entered(body):
	if bullet_owner == "Player": 
		if body.is_in_group("Boss"):
			body.take_damage()
			queue_free()
		elif body.is_in_group("Enemies"):
			body.take_damage()
			queue_free()
		elif body.is_in_group("Wall"):
			queue_free()
	
	if bullet_owner == "Boss":
		if body.is_in_group("Player"):
			body.take_damage()
			queue_free()
		elif body.is_in_group("Wall"):
			queue_free()
	
