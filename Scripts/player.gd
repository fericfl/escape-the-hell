extends CharacterBody2D

@export var moveSpeed = 300
@export var slideCooldown = 1.0 # seconds
@export var slideSpeed = 2.0 # multiplier
@export var slideDuration = 10 # in frames
var max_health = RunProgress.get_max_player_health()
var current_health = RunProgress.get_current_player_health()
var number_of_shots = RunProgress.get_player_shots()
@export var endgame_scene: PackedScene
@export var bullet_scene: PackedScene
@export var shoot_cooldown: float = 0.5
@export var animation_player: AnimationPlayer
@export var camera: Camera2D
@export var collision_shape: CollisionShape2D

var is_moving = false
var can_slide = true
var is_sliding = false
var slideFrames = 0
var slide_direction = Vector2.ZERO
var last_move_direction = Vector2.ZERO
var is_dead: bool = false
var shoot_timer: float = 0.0
var face_locked: bool = false
var ready_to_move = false
var alert_timer: Timer

func _ready():
	await get_tree().process_frame
	ready_to_move = true
	var is_in_boss_room = get_tree().current_scene
	alert_timer = Timer.new()
	add_child(alert_timer)
	alert_timer.one_shot = true
	alert_timer.timeout.connect(_on_alert_timeout)
	EnemyCoordinator.group_attack_position.connect(_on_group_attack)
	if $SlideTime is Timer:
		$SlideTime.wait_time = slideCooldown
		$SlideTime.one_shot = true
	else:
		push_error("SlideTime node is missing or not a Timer!")
	if $FaceLockTime is Timer:
		$FaceLockTime.one_shot = true
	else:
		push_error("SlideTime node is missing or not a Timer!")
	if is_in_boss_room.scene_file_path.ends_with("light_maze.tscn"):
		$Shadow.visible = !$Shadow.visible
	if is_in_boss_room.scene_file_path.ends_with("boss_room.tscn"):
		$CloseLight.enabled = !$CloseLight.enabled
		$FarLight.enabled = !$FarLight.enabled

func _physics_process(_delta):
	if not ready_to_move:
		return
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	
	if Input.is_action_just_pressed("slide") and can_slide  and last_move_direction != Vector2.ZERO:
		can_slide = false
		is_sliding = true
		slideFrames = slideDuration
		slide_direction = last_move_direction
		$SlideTime.start()
	
	input_dir = input_dir.normalized()
	is_moving = input_dir != Vector2.ZERO
		
	if is_moving:
		last_move_direction = input_dir
		if not face_locked:
			if velocity.x != 0:
				$Sprite2D.flip_h = velocity.x < 0
				$Shadow.flip_h = velocity.x < 0
		animation_player.play("walk")
	else:
		animation_player.play("idle")
	
	if is_sliding:
		velocity = slide_direction * moveSpeed * slideSpeed
		slideFrames -= 1
		if slideFrames <= 0:
			is_sliding = false
	else:
		velocity = input_dir * moveSpeed

	move_and_slide()
	
	shoot_timer -= _delta
	if Input.is_action_just_pressed("shoot") and shoot_timer <= 0:
		shoot()
		shoot_timer = shoot_cooldown

func take_damage():
	if is_dead:
		return
	
	current_health -= 1
	RunProgress.set_current_player_health(current_health)
	
	if current_health <= 0:
		die()

func die():
	is_dead = true
	
	queue_free()
	if endgame_scene != null:
		get_tree().change_scene_to_packed(endgame_scene)
	else:
		push_error("Endgame Scene not assigned!")

func shoot():
	if bullet_scene == null:
		push_error("No bullet scene assigned to player!")
		return
	var spacing = 5.0
	var total_spread = (number_of_shots - 1) * spacing
	
	var mouse_position = get_viewport().get_camera_2d().get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()
	
	var is_horizontal = abs(direction_to_mouse.x) > abs(direction_to_mouse.y)
	
	for i in number_of_shots:
		var bullet = bullet_scene.instantiate()
		bullet.bullet_owner = "Player"
		get_parent().add_child(bullet)
		
		var offset: Vector2
		if number_of_shots > 1:
			if is_horizontal:
				offset = Vector2(0, -total_spread/2 + i*spacing)
				bullet.global_position = global_position + offset
			else:
				offset = Vector2(-total_spread/2 + i*spacing, 0)
				bullet.global_position = global_position + offset + Vector2(0, -10) 
			bullet.set_direction(direction_to_mouse)
		else:
			bullet.global_position = global_position
			bullet.set_direction(direction_to_mouse)
	
	$Sprite2D.flip_h = direction_to_mouse.x < 0
	face_locked = true
	$FaceLockTime.start()

func _on_group_attack(_positions: Array):
	$RichTextLabel.visible = true
	alert_timer.start(1.0)

func _on_alert_timeout():
	$RichTextLabel.visible = false

func _on_slide_time_timeout() -> void:
	can_slide = true
	
func _on_face_lock_timer_timeout() -> void:
	face_locked = false
