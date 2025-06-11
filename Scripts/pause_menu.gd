extends Control

var menu_vissable := false
func _process(_delta: float) -> void:
	press_button()

func resume():
	get_tree().paused = false
	menu_vissable = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$AnimationPlayer.play_backwards("blur")

func pause():
	get_tree().paused = true
	menu_vissable = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	$AnimationPlayer.play("blur")

func quit():
	get_tree().quit()

func press_button():
	if Input.is_action_just_pressed("esc"):
		if menu_vissable:
			resume()
		else:
			pause()

func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	quit()
