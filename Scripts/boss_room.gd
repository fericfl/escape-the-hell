extends Node2D

func _ready() -> void:
	$Boss.connect("boss_defeated", self._on_boss_defeated)
	
func _on_boss_defeated():
	RunProgress.add_score(500)
	var perk_ui = get_node("CanvasLayer/Perk Screen")
	perk_ui.show_perks()
