extends CharacterBody2D
class_name Enemy

enum State {IDLE, CHASE, ATTACK, ROAM, GROUP_CHASE, HIDING, COORDINATED_ATTACK}
const MAZE_SIZE = Vector2i(40,25)

@export var ally_radius: int = 2
@export var attack_range: float = 16.0
@export var move_speed: float = 40.0
@export var animation_player: AnimationPlayer
@export var spawn_delay: float = 0.5
@export var group_attack_distance: float = 400.0

var damage = RunProgress.get_player_damage()
var state: State = State.IDLE
var can_start := false
var can_attack := false
var max_health := 50
var current_health = max_health
var attack_cooldown := 1.0
var attack_timer := 0.0
var spawn_timer := 0.0
var roam_timer: float = 0.0
var roam_target: Vector2 = Vector2.ZERO
var assigned_attack_pos: Vector2 = Vector2.ZERO
var current_hide_pos: Vector2 = Vector2.ZERO

@onready var player = EnemyCoordinator.player


func _ready():
	EnemyCoordinator.register(self)
	EnemyCoordinator.connect("update_enemy_awareness", _on_awareness_update)
	EnemyCoordinator.connect("group_attack_position", _on_group_attack_positions)
	EnemyCoordinator.connect("send_hide_positions", _on_hide_positions)
	spawn_timer = spawn_delay

func _exit_tree():
	EnemyCoordinator.unregister(self)

func _on_awareness_update(enemy: Node2D, nearby_allies: int) -> void:
	if enemy != self:
		return
	can_attack = nearby_allies >= ally_radius

func _on_group_attack_positions(positions: Array) -> void:
	if positions.size() > 0:
		var closest_pos = positions[0]
		var min_dist = global_position.distance_to(closest_pos)

		for pos in positions:
			var dist = global_position.distance_to(pos)
			if dist < min_dist:
				min_dist = dist
				closest_pos = pos
		
		assigned_attack_pos = closest_pos

		if state != State.ATTACK and state != State.COORDINATED_ATTACK:
			state = State.COORDINATED_ATTACK

func _on_hide_positions(positions: Array) -> void:
	if positions.size() > 0 and state != State.HIDING:
		var closest_pos = positions[0]
		var min_dist = global_position.distance_to(closest_pos)

		for pos in positions:
			var dist = global_position.distance_to(pos)
			if dist < min_dist:
				min_dist = dist
				closest_pos = pos
			
			current_hide_pos = closest_pos

func _physics_process(delta: float):
	if not can_start:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			can_start = true
		else:
			return
	
	
	if not player:
		player = EnemyCoordinator.player
		if not player:
			return
	
	match  state:
		State.IDLE:
			if can_see_player():
				if can_attack:
					state = State.COORDINATED_ATTACK
				else:
					state = State.CHASE
			else:
				state = State.ROAM
		State.CHASE:
			move_towards_player()
			if global_position.distance_to(player.global_position) <= attack_range:
				state = State.ATTACK
			else:
				state = State.ROAM
		State.ATTACK:
			if global_position.distance_to(player.global_position) > attack_range:
				state = State.CHASE
			else:
				perform_attack(delta)
				
		State.COORDINATED_ATTACK:
			if assigned_attack_pos != Vector2.ZERO:
				var path = AstarManager.astar.get_point_path(
					AstarManager.astar.get_closest_point(global_position),
					AstarManager.astar.get_closest_point(assigned_attack_pos))
				
				if path.size() > 1:
					var direction = (path[1] - global_position).normalized()
					velocity = direction * move_speed
					move_and_slide()
				
				if global_position.distance_to(assigned_attack_pos) < 10:
					state = State.ATTACK
		State.HIDING:
			if current_hide_pos != Vector2.ZERO:
				var path = AstarManager.astar.get_point_path(
					AstarManager.astar.get_closest_point(global_position),
					AstarManager.astar.get_closest_point(current_hide_pos))
				
				if path.size() > 1:
					var direction = (path[1] - global_position).normalized()
					velocity = direction * move_speed
					move_and_slide()
				if global_position.distance_to(current_hide_pos) < 10:
					state = State.IDLE
		State.ROAM:
			roam_timer -= delta
			if roam_timer <= 0 or global_position.distance_to(roam_target) < 5:
				var valid_position_found = false
				var attempts = 0
				var max_attempts = 10
				
				while not valid_position_found and attempts < max_attempts:
					var random_x = randi_range(1, MAZE_SIZE.x - 2)
					var random_y = randi_range(1, MAZE_SIZE.y - 2)
					var tile_pos = Vector2i(random_x, random_y)
					if tile_pos.y < AstarManager.maze.size() and tile_pos.x < AstarManager.maze[0].size():
						if AstarManager.maze[tile_pos.y][tile_pos.x]:
							roam_target = AstarManager.floor_tilemap.map_to_local(tile_pos)
							roam_timer = randf_range(2.0, 5.0)
							valid_position_found = true
					attempts += 1
				if not valid_position_found:
					roam_target = global_position
			if roam_target != Vector2.ZERO:
				var start_id = AstarManager.astar.get_closest_point(global_position)
				var end_id = AstarManager.astar.get_closest_point(roam_target)
				
				if start_id != -1 and end_id != -1:
					var path = AstarManager.astar.get_point_path(start_id, end_id)
					if path.size() > 1:
						velocity = (path[1] - global_position).normalized() * move_speed
						move_and_slide()
			
			if can_see_player():
				if can_attack:
					state = State.CHASE
				else:
					state = State.ROAM
		State.GROUP_CHASE:
			if EnemyCoordinator.attack_positions.size() > 0:
				var closest_pos = EnemyCoordinator.attack_positions[0]
				var min_dist = global_position.distance_to(closest_pos)
				
				for pos in EnemyCoordinator.attack_positions:
					var dist = global_position.distance_to(pos)
					if dist < min_dist:
						min_dist = dist
						closest_pos = pos
				
				var start_id = AstarManager.astar.get_closest_point(global_position)
				var end_id = AstarManager.astar.get_closest_point(closest_pos)
				
				if start_id != -1 and end_id != -1:
					var path = AstarManager.astar.get_point_path(start_id, end_id)
					if path.size() > 1:
						velocity = (path[1] - global_position).normalized() * move_speed
						move_and_slide()
				if global_position.distance_to(closest_pos) < 20:
					state = State.ATTACK
			else:
				state = State.CHASE

func move_towards_player():
	if not player:
		return
	var from_id = AstarManager.astar.get_closest_point(global_position)
	var to_id = AstarManager.astar.get_closest_point(player.global_position)
	
	
	var path = AstarManager.astar.get_point_path(from_id, to_id)
	
	if path.size() == 0:
		return
	
	if path.size() > 1:
		var direction = (path[1] - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()

func perform_attack(delta: float):
	attack_timer -= delta
	if attack_timer <= 0:
		animation_player.play("chomp")
		player.take_damage()
		attack_timer = attack_cooldown
	
	if randf() < 0.1:
		state = State.HIDING

func can_see_player() -> bool:
	$RayCast2D.target_position = player.global_position - global_position
	$RayCast2D.force_raycast_update()
	if $RayCast2D.is_colliding():
		var collider = $RayCast2D.get_collider()
		return collider == player
	return false

func take_damage():
	current_health -= damage
	if current_health <= 0:
		die()

func die():
	EnemyCoordinator.unregister(self)
	queue_free()
