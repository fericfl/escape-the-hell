extends Control

@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

var max_health = RunProgress.get_max_player_health()
var current_health = RunProgress.get_current_player_health()

@onready var heart_container = $HeartContainer
@onready var SoulsText = $SoulsScoreContainer/Souls
@onready var ScoreText = $SoulsScoreContainer/Score

func _ready():
	RunProgress.HUD = self
	update_hearts()
	
	RunProgress.connect("score_changed", self.update_score)
	RunProgress.connect("souls_changed", self.update_souls)
	
	update_score(RunProgress.get_score())
	update_souls(RunProgress.get_total_souls_collected())

func set_current_health(new_health: int):
	current_health = new_health
	update_hearts()

func update_hearts():
	max_health = RunProgress.get_max_player_health()
	current_health = RunProgress.get_current_player_health()
	
	for child in heart_container.get_children():
		child.queue_free()
	
	for i in max_health:
		var heart = TextureRect.new()
		heart.custom_minimum_size = Vector2(64,64)
		heart.texture = full_heart_texture if i < current_health else empty_heart_texture
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_container.add_child(heart)

func update_souls(souls):
	SoulsText.clear()
	SoulsText.append_text("Souls: %d" % souls)

func update_score(new_score):
	ScoreText.clear()
	ScoreText.append_text("Score: %d | " % new_score)
