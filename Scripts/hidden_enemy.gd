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

var max_health: int = 100
var current_health: int
var attack_cooldown := 1.5
var attack_timer := 0.0
var is_attacking := false
var player_damage := RunProgress.get_player_damage()
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
	current_health = max_health
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
	var shadow = is_in_shadow()
	var ally_count = get_nearby_ally_count()
	
	if state != State.ATTACK:
		if not shadow and ally_count < ally_radius:
			state = State.HIDE
			_find_furthest_hide_point()
			return
		elif state == State.WAIT_FOR_ALLY and ally_count >= ally_radius:
			state = State.CHASE
			return
	if previous_state != state:
		print("State:", State.keys()[state], " Path size:", path.size(), " Current index:", current_path_index)
		previous_state = state

	match state:
		State.IDLE:
			if can_see_player():
				last_player_pos = player.global_position
				if shadow:
					if ally_count >= ally_radius:
						state = State.CHASE
					else:
						state = State.WAIT_FOR_ALLY
						wait_timer = wait_for_ally_time
				else:
					state = State.HIDE
					_find_furthest_hide_point()
		State.HIDE:
			hide_behavior()
		State.WAIT_FOR_ALLY:
			wait_timer -= delta
			
			if shadow:
				if player.global_position.distance_to(last_player_pos) > path_update_distance_threshold or path.is_empty() or current_path_index >= path.size():
					last_player_pos = player.global_position
					_find_path_to(last_player_pos)
				_move_along_path()
			else:
				velocity = Vector2.ZERO
				move_and_slide()
		State.CHASE:
			if not shadow and ally_count < ally_radius:
				state = State.HIDE
				_find_furthest_hide_point()
			else:
				chase_player()
				if global_position.distance_to(player.global_position) <= attack_range:
					state = State.ATTACK
		State.ATTACK:
			print("Attacking Player")
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

	if not can_see_player():
		var dist_to_last_pos = global_position.distance_to(last_player_pos)
		if dist_to_last_pos < attack_range * 2:
			state = State.IDLE
		
		else:
			if global_position.distance_to(player.global_position) <= attack_range:
				state = State.ATTACK

func take_damage():
	current_health -= player_damage
	if current_health <= 0:
		die()
func die():
	queue_free()
func attack_player():
	print("attacking")
	velocity = Vector2.ZERO
	move_and_slide()
	
	attack_timer -= get_physics_process_delta_time()
	

	if global_position.distance_to(player.global_position) > attack_range:
		state = State.CHASE
		is_attacking = false
	else:
		if attack_timer <= 0 and not is_attacking:
			is_attacking = true
			animation_player.play("chomp")
			$Timer.start(0.5)
			attack_timer = attack_cooldown

func can_see_player() -> bool:
	if not player:
		return false
	var direction = player.global_position - global_position
	ray.global_position = global_position
	ray.target_position = direction
	ray.force_raycast_update()

	if ray.is_colliding():
		return ray.get_collider() == player
	return false

func is_in_shadow() -> bool:
	for area in light_area.get_overlapping_areas():
		if area.is_in_group("LightZone"):
			return false
	return true

func get_nearby_ally_count() -> int:
	var count = 0
	for area in awareness_area.get_overlapping_areas():
		var parent = area.get_parent()
		if parent != self and parent.is_in_group("Enemies"):
			print("I found this many allies: ", count)
			count += 1
	return count

func _move_along_path():
	if current_path_index >= path.size():
		velocity = Vector2.ZERO
		move_and_slide()
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
	var astar = AstarManager.astar
	var start = astar.get_closest_point(global_position)
	var end = astar.get_closest_point(target_pos)
	
	if astar.has_point(start) and astar.has_point(end):
		path = astar.get_point_path(start, end)
		current_path_index = 0

func _find_furthest_hide_point():
	var astar = AstarManager.astar
	var best_point = null
	var best_score = -INF

	for point_id in astar.get_point_ids():
		var point_pos = astar.get_point_position(point_id)
		var distance_to_player = point_pos.distance_to(player.global_position)
		
		var los_ray = RayCast2D.new()
		add_child(los_ray)
		los_ray.global_position = player.global_position
		los_ray.target_position = (point_pos - player.global_position).normalized() * distance_to_player
		los_ray.force_raycast_update()
		
		var not_visible = not los_ray.is_colliding() or los_ray.get_collider() != self
		los_ray.queue_free()
		
		var is_dark = true
		for area in light_area.get_overlapping_areas():
			if area.global_position.distance_to(point_pos) < 64:
				is_dark = false
				break
		
		var score = distance_to_player
		if not_visible:
			score += 100
		if is_dark:
			score += 50
		
		if score > best_score:
			best_score = score
			best_point = point_id
	if best_point != null:
		var start = astar.get_closest_point(global_position)
		path = astar.get_point_path(start, best_point)
		current_path_index = 0

func _on_Area2D_body_entered(_body):
	pass
func _on_Area2D_body_exited(_body):
	pass


func _on_timer_timeout() -> void:
	if player and global_position.distance_to(player.global_position) <= attack_range:
		player.take_damage()
	is_attacking = false
