extends CharacterBody2D

@export var SPEED = 200
const LANE_HEIGHT = 32
const LANES = [46, 92, 140]
var current_lane = 1

func _ready():
	position.y = LANES[current_lane]

func _physics_process(_delta: float) -> void:
	velocity.x = SPEED
	velocity.y = 0
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

func update_lane_position():
	global_position.y = LANES[current_lane]
