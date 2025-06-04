extends CharacterBody2D

signal score_threshold_reached

@export var START_SPEED = 50
@export var SLOW_SPEED = 15
var max_health = RunProgress.get_max_player_health()
var current_health = RunProgress.get_current_player_health()
@export var JUMP_HEIGHT = 12
@export var JUMP_DURATION = 0.5 
@export var endgame_scene: PackedScene
@export var animation_player: AnimationPlayer
@export var sprite: Sprite2D
@export var tilemap: TileMapLayer
@export var SPIKE_TILE = Vector2i(3, 3)
@onready var shadow = $Shadow

var score_threshold: int  = RunProgress.get_current_score_threshold()
const LANE_HEIGHT = 32
const LANES = [96, 144, 192]
var current_lane = 1
var is_jumping = false
var jump_timer = 0.0
var original_y = 0.0
var current_speed = START_SPEED
var did_hit_spike = false
var target_y: float = 0.0
var souls = 0
var score = 0
var last_x = 0
var score_threshold_reached_emitted = false
var speed_increment = 5
var max_speed = 300

func _ready():
	position.y = LANES[current_lane]
	target_y = position.y
	$Area2D.connect("area_entered", Callable(self, "_on_area_entered"))


func _physics_process(delta: float) -> void:
	global_position.y = lerp(global_position.y, target_y, 8 * delta)
	velocity.x = current_speed
	velocity.y = 0
	
	# Scoring logic
	var moved_distance = int(global_position.x - last_x)
	if moved_distance > 0:
		score += moved_distance
		last_x = int(global_position.x)
	if score >= score_threshold and not score_threshold_reached_emitted:
		RunProgress.add_total_souls_collected(souls)
		emit_signal("score_threshold_reached")
		score_threshold_reached_emitted = true
	# Jump logic
	if is_jumping:
		jump_timer -= delta
		var t = 1.0 - (jump_timer / JUMP_DURATION)
		var jump_offset = -JUMP_HEIGHT * sin(t * PI)
		if jump_timer > 0:
			global_position.y = original_y + jump_offset
			shadow.modulate.a = 0.0
		else:
			is_jumping = false
			target_y = LANES[current_lane]
			animation_player.speed_scale = 1
			shadow.modulate.a = 0.4
	animation_player.play("run")
	check_spike_collision() 
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("change_lane_up"):
		if current_lane > 0:
			current_lane -= 1
			target_y = LANES[current_lane]
		else:
			wiggle()
	elif event.is_action_pressed("change_lane_down"):
		if current_lane < LANES.size() - 1:
			current_lane += 1
			target_y = LANES[current_lane]
		else:
			wiggle()
	elif event.is_action_pressed("jump") and is_jumping == false:
		start_jump()


func wiggle():
	var reffrence_y := sprite.position.y
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(sprite, "position:y", reffrence_y + 3, 0.075)
	tween.tween_property(sprite, "position:y", reffrence_y - 3, 0.075)
	tween.tween_property(sprite, "position:y", reffrence_y, 0.05)


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
			current_health -= 1
			current_speed = SLOW_SPEED
			if current_health <= 0:
				get_tree().change_scene_to_packed(endgame_scene)
	else:
		did_hit_spike = false
		current_speed = START_SPEED

func _on_area_entered(_area: Area2D) -> void:
	score += 100
	souls += 1
	print("Souls: ", souls)

func set_player_health():
	RunProgress.set_current_player_health(current_health)

func _on_elapsed_time_timeout() -> void:
	if current_speed < max_speed:
		current_speed += speed_increment
		START_SPEED = current_speed
