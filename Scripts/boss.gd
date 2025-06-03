extends CharacterBody2D

signal boss_defeated

@export var move_speed = 10
@export var bullet_scene: PackedScene
@export var animation_player: AnimationPlayer

var next_scene = preload("res://Scenes/infinite_run.tscn")
var max_hits: int = RunProgress.get_current_boss_hits()
var shoot_cooldown = RunProgress.get_current_tbsb()
var no_of_shots = RunProgress.get_current_total_rounds_fired_boss()
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
	
	current_hits += 25
	print("Boss hit! Hits:", current_hits, "/", max_hits)
	
	if current_hits >= max_hits:
		die()

func die():
	is_dead = true
	print("Boss defeated!")
	
	RunProgress.rounds_completed += 1
	emit_signal("boss_defeated")
	queue_free()
	

func shoot_at_player():
	if bullet_scene == null:
		push_error("No bullet scene assigned to boss!")
		return
	
	var cone_angle := deg_to_rad(45)
	var angle_step := 0.0
	if no_of_shots > 1:
		angle_step = cone_angle / (no_of_shots - 1)
	
	var dir_to_player = (player.global_position - global_position).normalized()
	var base_angle = dir_to_player.angle() - cone_angle / 2
	
	animation_player.play("shoot")
	if no_of_shots > 1:
		for i in no_of_shots:
			var bullet = bullet_scene.instantiate()
			bullet.bullet_owner = "Boss"
			get_parent().add_child(bullet)
			bullet.global_position = global_position + Vector2(0, -20)
			
			var angle = base_angle + i * angle_step
			var spread_direction = Vector2.RIGHT.rotated(angle)
			bullet.set_direction(spread_direction)
	else:
		var bullet = bullet_scene.instantiate()
		bullet.bullet_owner = "Boss"
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(0, -20)
		
		bullet.set_direction(dir_to_player)
	
