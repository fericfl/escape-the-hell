extends Area2D

signal collected

func _read():
	print("I connected to signal")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("I am here")
	if body.is_in_group("Player"):
		collected.emit("collected")
		queue_free()
