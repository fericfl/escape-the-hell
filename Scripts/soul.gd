extends Area2D

signal collected

@export var animation_player: AnimationPlayer

func _ready() -> void:
	animation_player.play("idle")

func _on_area_entered(area):
	if area.is_in_group("Player"):
		emit_signal("collected")
		queue_free()
