extends Node2D

func _ready() -> void:
	$Boss.connect("boss_defeated", self._on_boss_defeated)
	
func _on_boss_defeated():
	$Player.set_player_health()
	get_tree().change_scene_to_file("res://Scenes/infinite_run.tscn")
