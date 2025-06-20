class_name Enemy
extends CharacterBody2D

@export var move_speed: float = 100
@export var attack_range: float = 50
@export var ally_radius: int = 2
@export var animation_player: AnimationPlayer
@export var spawn_delay: float = 1.0
@export var player: CharacterBody2D


var spawn_delay_timer: float = 0.0
var can_start = false
enum State {IDLE, HIDE, CHASE, ATTACK}
var state: State = State.IDLE
var nearby_allies: Array = []

var path: Array = []
var current_path_index := 0

@onready var ray = $RayCast2D
@onready var awarness_area = $AwarenessArea2D

func _ready():
	add_to_group("Enemies")
	awarness_area.body_entered.connect(_on_Area2D_body_entered)
	awarness_area.body_exited.connect(_on_Area2D_body_exited)
	spawn_delay_timer = spawn_delay

func _physics_process(delta: float) -> void:
	if not can_start:
		spawn_delay_timer -= delta
		if spawn_delay_timer <= 0:
			can_start = true
		else:
			return
	
	match state:
		State.IDLE:
			#print("I am Idle")
			look_for_player()
		State.HIDE:
			#print("I am Hiding")
			hide_behavior()
		State.CHASE:
			print("I am Chasing")
			chase_player()
		State.ATTACK:
			print("I am Attacking")
			attack_player()

func look_for_player():
	if can_see_player():
		if get_nearby_ally_count() >= ally_radius:
			state = State.CHASE
			#animation_player.play("alert")
		else:
			state = State.HIDE

func hide_behavior():
	if path.is_empty() or current_path_index >= path.size():
		_find_hide_path()
	
	if current_path_index < path.size():
		var target_point = path[current_path_index]
		if global_position.distance_to(target_point) < 4:
			current_path_index += 1
		else:
			var dir = (target_point - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()

func chase_player():
	if path.is_empty() or current_path_index >= path.size():
		_find_path_to_player()
	
	if current_path_index < path.size():
		var target_point = path[current_path_index]
		if global_position.distance_to(target_point) < 4:
			current_path_index += 1
		if current_path_index < path.size():
			var dir = (target_point - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()
	
	if global_position.distance_to(player.global_position) <= attack_range:
		state = State.ATTACK

func _find_path_to_player():
	var astar = AstarManager.astar
	var start = astar.get_closest_point(global_position)
	var end = astar.get_closest_point(player.global_position)
	
	if astar.has_point(start) and astar.has_point(end):
		path = astar.get_point_path(start, end)
		current_path_index = 0

func _find_hide_path():
	var furthest_point = null
	var max_distance = -1.0
	var player_pos = player.global_position
	
	for point_id in AstarManager.astar.get_point_ids():
		var point_pos = AstarManager.astar.get_point_position(point_id)
		var dist = point_pos.distance_to(player_pos)
		
		if dist > max_distance:
			max_distance = dist
			furthest_point = point_id
			
	if furthest_point != null:
		var start = AstarManager.astar.get_closest_point(global_position)
		path = AstarManager.astar.get_point_path(start, furthest_point)
		current_path_index = 0

func attack_player():
	velocity = Vector2.ZERO
	#animation_player.play("attack")
	
	if global_position.distance_to(player.global_position) > attack_range:
		state = State.CHASE

func can_see_player() -> bool:
	#var direction = player.global_position - global_position
	#ray.target_position = direction
	#ray.force_raycast_update()
	#if not player:
		#return false
	#if ray.is_colliding():
		#var hit = ray.get_collider()
		#return hit == player
	#return false
	var start = AstarManager.astar.get_closest_point(global_position)
	var end = AstarManager.astar.get_closest_point(player.global_position)
	return start == end or AstarManager.astar.has_point(end)

func get_nearby_ally_count() -> int:
	var count = 0
	for body in awarness_area.get_overlapping_bodies():
		if body != self and body.is_in_group("Enemies"):
			count += 1
	return count

func _on_Area2D_body_entered(body):
	if body.is_in_group("Enemies"):
		nearby_allies.append(body)
		print("I found a friend! ", nearby_allies.size())
		
		
func _on_Area2D_body_exited(body):
	nearby_allies.erase(body)
