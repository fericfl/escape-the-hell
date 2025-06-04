class_name Enemy
extends CharacterBody2D

@export var move_speed: float = 50
@export var attack_range: float = 50
@export var ally_radius: int = 2
@export var animation_player: AnimationPlayer
@export var spawn_delay: float = 1.0
@export var player: CharacterBody2D
@export var roam_wait_time := 2.0
@export var wait_for_ally_time := 10.0

@onready var ray = $RayCast2D
@onready var awareness_area = $AwarenessArea2D
@onready var light_area = $LightAreaDetectorArea2D

var distance_threshold = 10
var spawn_delay_timer: float = 0.0
var can_start = false
var roam_timer := 0.0
var is_waiting := false
var wait_timer = 0.0
var path: Array = []
var current_path_index := 0
var last_player_pos: Vector2 = Vector2.ZERO
var path_update_distance_threshold := 32.0

enum State {IDLE, HIDE, WAIT_FOR_ALLY, CHASE, ATTACK}
var state: State = State.IDLE

#DEBUG
var previous_state = State.IDLE

func _ready():
	add_to_group("Enemies")
	spawn_delay_timer = spawn_delay
	awareness_area.body_entered.connect(_on_Area2D_body_entered)
	awareness_area.body_exited.connect(_on_Area2D_body_exited)

func _physics_process(delta: float) -> void:
	if not can_start:
		spawn_delay_timer -= delta
		if spawn_delay_timer <= 0:
			can_start = true
		else:
			return
	if previous_state != state:
		print("State:", State.keys()[state], " Path size:", path.size(), " Current index:", current_path_index)
		previous_state = state

	match state:
		State.IDLE:
			if can_see_player() and is_in_shadow():
				if get_nearby_ally_count() >= ally_radius:
					state = State.CHASE
				else:
					state = State.WAIT_FOR_ALLY
					wait_timer = wait_for_ally_time
			else:
				roam_randomly(delta)
		State.HIDE:
			hide_behavior()
		State.WAIT_FOR_ALLY:
			velocity = Vector2.ZERO
			wait_timer -= delta
			if get_nearby_ally_count() >= ally_radius:
				state = State.CHASE
			elif wait_timer <= 0:
				state = State.HIDE
		State.CHASE:
			chase_player()
			if global_position.distance_to(player.global_position) <= attack_range:
				state = State.ATTACK
		State.ATTACK:
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
		_move_along_path()

func look_for_player():
	if can_see_player():
		if get_nearby_ally_count() >= ally_radius:
			state = State.CHASE
		else:
			state = State.HIDE

func hide_behavior():
	if path.is_empty() or current_path_index >= path.size():
		_find_furthest_hide_point()
	else:
		_move_along_path()

func chase_player():
	if player.global_position.distance_to(last_player_pos) > path_update_distance_threshold or path.is_empty() or current_path_index >= path.size():
		last_player_pos = player.global_position
		_find_path_to(last_player_pos)

	_move_along_path()

	if global_position.distance_to(player.global_position) <= attack_range:
		state = State.ATTACK


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
		return ray.get_collider() == player
	return false

func is_in_shadow() -> bool:
	print("Am I in shadow?")
	for body in light_area.get_overlapping_areas():
		if body is PointLight2D:
			return false
	return true

func get_nearby_ally_count() -> int:
	var count = 0
	for body in awareness_area.get_overlapping_bodies():
		if body != self and body.is_in_group("Enemies"):
			count += 1
	return count

func _move_along_path():
	if current_path_index >= path.size():
		velocity = Vector2.ZERO
		return
	
	var target = path[current_path_index]
	var dist = global_position.distance_to(target)
	
	if dist < distance_threshold:
		current_path_index += 1
	else:
		var dir = (target - global_position).normalized()
		velocity = dir * move_speed
	move_and_slide()
func _pick_random_roam_point():
	var point_ids = AstarManager.astar.get_point_ids()
	if point_ids.is_empty():
		return
	var start = AstarManager.astar.get_closest_point(global_position)
	var random_id = point_ids[randi() % point_ids.size()]

	if AstarManager.astar.has_point(start) and AstarManager.astar.has_point(random_id):
		path = AstarManager.astar.get_point_path(start, random_id)
		current_path_index = 0

func _find_path_to(target_pos: Vector2):
	if path.size() <= 1:
		path.clear()
		return
	
	var astar = AstarManager.astar
	var start = astar.get_closest_point(global_position)
	var end = astar.get_closest_point(target_pos)
	
	if astar.has_point(start) and astar.has_point(end):
		path = astar.get_point_path(start, end)
		current_path_index = 0

func _find_furthest_hide_point():
	if path.size() <= 1:
		path.clear()
		return
	
	var astar = AstarManager.astar
	var furthest_point = null
	var max_distance = -1.0

	for point_id in astar.get_point_ids():
		var dist = astar.get_point_position(point_id).direction_to(player.global_position)
		if dist > max_distance:
			max_distance = dist
			furthest_point = point_id

	if furthest_point != null:
		var start = astar.get_closest_point(global_position)
		path = astar.get_point_path(start, furthest_point)
		current_path_index = 0

func _on_Area2D_body_entered(_body):
	pass
func _on_Area2D_body_exited(_body):
	pass
