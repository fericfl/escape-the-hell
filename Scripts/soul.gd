extends Area2D

signal collected

func _on_area_entered(area):
	print("I am here")
	if area.is_in_group("Player"):
		emit_signal("collected")
		queue_free()
