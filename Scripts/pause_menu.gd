extends Control

func _process(_delta: float) -> void:
	press_button()

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func quit():
	get_tree().quit()

func press_button():
	if Input.is_action_just_pressed("esc") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("esc") and get_tree().paused:
		resume()

func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	quit()
