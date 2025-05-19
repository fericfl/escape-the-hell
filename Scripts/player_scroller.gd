extends CharacterBody2D

@export var SPEED = 200
@export var JUMP_HEIGHT = 12
@export var JUMP_DURATION = 0.5 
@export var animation_player: AnimationPlayer

const LANE_HEIGHT = 32
const LANES = [46, 92, 140]
var current_lane = 1
var is_jumping = false
var jump_timer = 0.0
var original_y = 0.0

func _ready():
	position.y = LANES[current_lane]

func _physics_process(_delta: float) -> void:
	velocity.x = SPEED
	velocity.y = 0
	
	if is_jumping:
		animation_player.stop()
		jump_timer -= _delta
		if jump_timer > 0:
			global_position.y = original_y - JUMP_HEIGHT
		else:
			is_jumping = false
			update_lane_position()
	animation_player.play("run") 
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("change_lane_up"):
		if current_lane > 0:
			current_lane -= 1
			update_lane_position()
	elif event.is_action_pressed("change_lane_down"):
		if current_lane < LANES.size() - 1:
			current_lane += 1
			update_lane_position()
	elif event.is_action_pressed("jump") and is_jumping == false:
		start_jump()

func start_jump():
	is_jumping = true
	jump_timer = JUMP_DURATION
	original_y = global_position.y

func update_lane_position():
	global_position.y = LANES[current_lane]
