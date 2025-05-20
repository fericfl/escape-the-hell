extends CharacterBody2D

@export var NORMAL_SPEED = 50
@export var SLOW_SPEED = 15
@export var lives: int = 3
@export var JUMP_HEIGHT = 12
@export var JUMP_DURATION = 0.5 
@export var endgame_scene: PackedScene
@export var animation_player: AnimationPlayer
@export var tilemap: TileMapLayer
@export var SPIKE_TILE = Vector2i(3, 3)

const LANE_HEIGHT = 32
const LANES = [96, 144, 192]
var current_lane = 1
var is_jumping = false
var jump_timer = 0.0
var original_y = 0.0
var current_speed = NORMAL_SPEED
var did_hit_spike = false
var target_y: float = 0.0

func _ready():
	position.y = LANES[current_lane]
	target_y = position.y

func _physics_process(delta: float) -> void:
	global_position.y = lerp(global_position.y, target_y, 8 * delta)
	velocity.x = current_speed
	velocity.y = 0
	
	if is_jumping:
		jump_timer -= delta
		var t = 1.0 - (jump_timer / JUMP_DURATION)
		var jump_offset = -JUMP_HEIGHT * sin(t * PI)
		if jump_timer > 0:
			global_position.y = original_y + jump_offset
		else:
			is_jumping = false
			target_y = LANES[current_lane]
			animation_player.speed_scale = 1
	animation_player.play("run")
	check_spike_collision() 
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("change_lane_up"):
		if current_lane > 0:
			current_lane -= 1
			target_y = LANES[current_lane]
	elif event.is_action_pressed("change_lane_down"):
		if current_lane < LANES.size() - 1:
			current_lane += 1
			target_y = LANES[current_lane]
	elif event.is_action_pressed("jump") and is_jumping == false:
		start_jump()

func start_jump():
	is_jumping = true
	jump_timer = JUMP_DURATION
	original_y = global_position.y
	animation_player.speed_scale = 0.5

func check_spike_collision():
	if is_jumping:
		did_hit_spike = false
		return
	var local_pos = tilemap.to_local(global_position)
	var tile_coords = tilemap.local_to_map(local_pos)
	var tile = tilemap.get_cell_atlas_coords(tile_coords)
	
	if tile == SPIKE_TILE:
		if not did_hit_spike:
			did_hit_spike = true
			lives -= 1
			current_speed = SLOW_SPEED
			if lives <= 0:
				get_tree().change_scene_to_packed(endgame_scene)
	else:
		did_hit_spike = false
		current_speed = NORMAL_SPEED
