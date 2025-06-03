class_name Enemy
extends CharacterBody2D

@export var move_speed: float = 50
@export var attack_range: float = 50
@export var ally_radius: int = 2
@export var animation_player: AnimationPlayer
@export var spawn_delay: float = 1.0
@export var player: CharacterBody2D
@export var roam_wait_time := 2.0

var distance_threshold = 10
var spawn_delay_timer: float = 0.0
var can_start = false
enum State {IDLE, HIDE, CHASE, ATTACK}
var state: State = State.IDLE
var nearby_allies: Array = []
var roam_timer := 0.0
var is_waiting := false
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
			if can_see_player():
				look_for_player()
			else:
				roam_randomly(delta)
		State.HIDE:
			#print("I am Hiding")
			hide_behavior()
		State.CHASE:
			print("I am Chasing")
			chase_player()
		State.ATTACK:
			print("I am Attacking")
			attack_player()

func roam_randomly(delta: float) -> void:
	if path.is_empty() or current_path_index >= path.size():
		if not is_waiting:
			is_waiting = true
			roam_timer = roam_wait_time
		else:
			roam_timer -= delta
			if roam_timer <= 0:
				is_waiting = false
				_pick_random_roam_point()
	else:
		var target_point = path[current_path_index]
		if global_position.distance_to(target_point) < distance_threshold:
			global_position = target_point
			current_path_index += 1
			velocity = Vector2.ZERO
		else:
			var dir = (target_point - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()

func look_for_player():
	if can_see_player():
		if get_nearby_ally_count() >= ally_radius:
			state = State.CHASE
		else:
			state = State.HIDE

func hide_behavior():
	if path.is_empty() or current_path_index >= path.size():
		_find_hide_path()
	
	if current_path_index < path.size():
		var target_point = path[current_path_index]
		if global_position.distance_to(target_point) < distance_threshold:
			global_position = target_point
			current_path_index += 1
			velocity = Vector2.ZERO
		else:
			var dir = (target_point - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()

func chase_player():
	if path.is_empty() or current_path_index >= path.size():
		_find_path_to_player()
	
	if current_path_index < path.size():
		var target_point = path[current_path_index]
		if global_position.distance_to(target_point) < distance_threshold:
			global_position = target_point
			current_path_index += 1
			velocity = Vector2.ZERO
		if current_path_index < path.size():
			var dir = (target_point - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()
	
	if global_position.distance_to(player.global_position) <= attack_range:
		state = State.ATTACK

func _pick_random_roam_point():
	var point_ids = AstarManager.astar.get_point_ids()
	if point_ids.is_empty():
		return
	var start = AstarManager.astar.get_closest_point(global_position)
	var random_id = point_ids[randi() % point_ids.size()]
	
	if AstarManager.astar.has_point(start) and AstarManager.astar.has_point(random_id):
		path = AstarManager.astar.get_point_path(start, random_id)
		current_path_index = 0

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
	
	if global_position.distance_to(player.global_position) > attack_range:
		state = State.CHASE

func can_see_player() -> bool:
	if not player:
		return false
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
		print("I found a friend! ", nearby_allies.size())
		
		
func _on_Area2D_body_exited(body):
	nearby_allies.erase(body)
