extends CharacterBody2D

@export var move_speed = 10
@export var shoot_cooldown: float = 1.5
@export var bullet_scene: PackedScene
@export var infinite_run = "res://Scenes/infinite_run.tscn"
@export var max_hits: int = 5
@export var animation_player: AnimationPlayer

var player: CharacterBody2D = null
var shoot_timer: float = 0.0
var current_hits: int = 0
var is_dead: bool = false

func _ready():
	player = get_parent().get_node_or_null("Player")
	if player == null:
		push_error("Player node not found!")

func _physics_process(delta):
	if player == null:
		return
	
	var direction = (player.global_position - global_position).normalized()
	
	velocity = direction * move_speed
	if direction.x < 0:
		get_node("Sprite2D").flip_h = true
	else:
		get_node("Sprite2D").flip_h = false
	move_and_slide()
	
	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_at_player()
		shoot_timer = shoot_cooldown
		
func take_damage():
	if is_dead:
		return
	
	current_hits += 1
	print("Boss hit! Hits:", current_hits, "/", max_hits)
	
	if current_hits >= max_hits:
		die()

func die():
	is_dead = true
	print("Boss defeated!")
	
	queue_free()
	get_tree().change_scene_to_file(infinite_run)
	

func shoot_at_player():
	if bullet_scene == null:
		push_error("No bullet scene assigned to boss!")
		return
	
	animation_player.play("shoot")
	var bullet = bullet_scene.instantiate()
	bullet.bullet_owner = "Boss"
	get_parent().add_child(bullet)
	
	bullet.global_position = global_position
	
	var dir_to_player = (player.global_position - global_position).normalized()
	bullet.set_direction(dir_to_player)
