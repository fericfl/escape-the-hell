extends CharacterBody2D

@export var moveSpeed = 300
@export var slideCooldown = 1.0 # seconds
@export var slideSpeed = 3.0 # multiplier
@export var slideDuration = 10 # in frames
@export var max_hits: int = 3
@export var endgame_scene: PackedScene

var is_moving = false
var can_slide = true
var is_sliding = false
var slideFrames = 0
var slide_direction = Vector2.ZERO
var last_move_direction = Vector2.ZERO
var current_hits: int = 0
var is_dead: bool = false

func _ready():
	if $SlideTime is Timer:
		$SlideTime.wait_time = slideCooldown
		$SlideTime.one_shot = true
	else:
		push_error("SlideTime node is missing or not a Timer!")

func _physics_process(_delta):
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	
	if Input.is_action_just_pressed("slide") and can_slide and last_move_direction != Vector2.ZERO:
		can_slide = false
		is_sliding = true
		slideFrames = slideDuration
		slide_direction = last_move_direction
		print("Slide cooldown starting")
		$SlideTime.start()
	
	input_dir = input_dir.normalized()

	is_moving = input_dir != Vector2.ZERO
	if is_moving:
		last_move_direction = input_dir

	if is_sliding:
		velocity = slide_direction * moveSpeed * slideSpeed
		slideFrames -= 1
		if slideFrames <= 0:
			is_sliding = false
	else:
		velocity = input_dir * moveSpeed

	move_and_slide()

func take_damage():
	if is_dead:
		return
	
	current_hits += 1
	print("Player hit! Hits:", current_hits, "/", max_hits)
	
	if current_hits >= max_hits:
		die()

func die():
	is_dead = true
	print("Player dead")
	
	if endgame_scene != null:
		get_tree().change_scene_to_packed(endgame_scene)
	else:
		push_error("Endgame Scene not assigned!")

func _on_slide_time_timeout() -> void:
	print("Slide is ready")
	can_slide = true
