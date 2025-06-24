extends Control

var menu_visible := false

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause():
	if menu_visible:
		resume()
	else:
		pause()
	menu_visible != menu_visible

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	await $AnimationPlayer.animation_finished
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func pause():
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func quit():
	get_tree().quit()

func press_button():
	if Input.is_action_just_pressed("esc"):
		if menu_visible:
			resume()
		else:
			pause()

func _on_resume_pressed() -> void:
	resume()
	menu_visible = false

func _on_quit_pressed() -> void:
	quit()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
