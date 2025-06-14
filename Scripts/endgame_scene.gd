extends Control

func _ready():
	RunProgress.reset_stats()

func _on_try_again_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/infinite_run.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
