extends CharacterBody2D

@export var move_speed: float = 100
@export var attack_range: float = 50
@export var ally_radius: int = 2
@export var player_path: NodePath = "/root/Scenes/Player"
@export var animation_player: AnimationPlayer

enum State {IDLE, HIDE, CHASE, ATTACK}
var state: State = State.IDLE

var player: CharacterBody2D
var nearby_allies: Array = []

@onready var ray = $RayCast2D
@onready var awarness_area = $Area2D

func _ready():
	player = get_node(player_path)
	add_to_group("Enemies")
	awarness_area.body_entered.connect(_on_Area2D_body_entered)
	awarness_area.body_exited.connect(_on_Area2D_body_exited)

func _physics_process(_delta: float) -> void:
	match state:
		State.IDLE:
			look_for_player()
		State.HIDE:
			hide_behavior()
		State.CHASE:
			chase_player()
		State.ATTACK:
			attack_player()

func look_for_player():
	if can_see_player():
		if get_nearby_ally_count() >= ally_radius:
			state = State.CHASE
			animation_player.play("alert")
		else:
			state = State.HIDE

func hide_behavior():
	var dir = (global_position - player.global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()
	animation_player.play("hide")

func chase_player():
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()
	animation_player.play("run")
	
	if global_position.distance_to(player.global_position) <= attack_range:
		state = State.ATTACK

func attack_player():
	velocity = Vector2.ZERO
	animation_player.play("attack")
	
	if global_position.distance_to(player.global_position) > attack_range:
		state = State.CHASE

func can_see_player() -> bool:
	var direction = player.global_position - global_position
	ray.target_position = direction
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var hit = ray.get_collider()
		return hit == player
	return false

func get_nearby_ally_count() -> int:
	var count = 0
	for body in awarness_area.get_overlapping_bodies():
		if body != self and body.is_in_group("Enemies"):
			count += 1
	return count

func _on_Area2D_body_entered(body):
	if body.is_in_group("Enemies"):
		nearby_allies.append(body)
		
func _on_Area2D_body_exited(body):
	nearby_allies.erase(body)
