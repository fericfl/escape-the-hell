extends CharacterBody2D

@export var move_speed = 10
@export var shoot_cooldown: float = 1.5
@export var bullet_scene: PackedScene

var player: CharacterBody2D = null
var shoot_timer: float = 0.0

func _ready():
	player = get_parent().get_node_or_null("Player")
	if player == null:
		push_error("Player node not found!")

func _physics_process(delta):
	if player == null:
		return
	
	var direction = (player.global_position - global_position).normalized()
	
	velocity = direction * move_speed
	
	move_and_slide()
	
	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_at_player()
		shoot_timer = shoot_cooldown
		
func shoot_at_player():
	if bullet_scene == null:
		push_error("No bullet scene assigned to boss!")
		return
	
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	
	bullet.global_position = global_position
	
	var dir_to_player = (player.global_position - global_position).normalized()
	bullet.set_direction(dir_to_player)
