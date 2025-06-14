extends Control

@onready var perk_container = $VBoxContainer/HBoxContainer
var font = preload("res://Assets/Font/joystix monospace.otf")
var all_perks = [
	{
		"name": "Max Health +1",
		"description": "Adds one heart.",
		"cost": 3,
		"apply": func(): RunProgress.set_player_health(1)
	},
	{
		"name": "Max Health +2",
		"description": "Adds two hearts.",
		"cost": 5,
		"apply": func(): RunProgress.set_player_health(2)
	},
	{
		"name": "Bonus damage",
		"description": "Add 15 damage.",
		"cost": 4,
		"apply": func(): RunProgress.set_player_damdage(15)
	},
	{
		"name": "Bigger Bonus damage!",
		"description": "Add 30 damage.",
		"cost": 7,
		"apply": func(): RunProgress.set_player_damdage(30)
	},
	{
		"name": "Boots of swiftness",
		"description": "Increase movement speed by 15%",
		"cost": 7,
		"apply": func(): RunProgress.set_player_move_speed(1.15)
	},
	{
		"name": "Another one bites!",
		"description": "Add another projectile to your attack.",
		"cost": 10,
		"apply": func(): RunProgress.set_player_shots(1)
	},
]

var shown_perks = []
var buttons = {}

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
func show_perks():
	get_tree().paused = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	shown_perks = all_perks.duplicate()
	shown_perks.shuffle()
	shown_perks = shown_perks.slice(0,3)
	_clear_perk_container()
	_shown_perks()

func hide_perks():
	get_tree().paused = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _clear_perk_container():
	for child in perk_container.get_children():
		child.queue_free()

func _shown_perks():
	for perk in shown_perks:
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.custom_minimum_size = Vector2(200,0)
		perk_container.add_theme_constant_override("separation", 50)
		
		var label = RichTextLabel.new()
		label.append_text("%s\n%s\nCost: %d" % [perk["name"], perk["description"], perk["cost"]])
		label.add_theme_font_override("normal_font", font)
		label.autowrap_mode = 3
		label.fit_content = true
		vbox.add_child(label)
		
		var btn = Button.new()
		btn.text = "Buy"
		btn.add_theme_font_override("font", font)
		if RunProgress.get_total_souls_collected() < perk["cost"]:
			btn.text = "Not enough souls"
			btn.disabled = true
		else:
			btn.text = "Buy"
			btn.disabled = false
		btn.pressed.connect(func():
			perk.apply.call()
			RunProgress.set_total_souls_collected(-perk["cost"])
			RunProgress.HUD.update_hearts()
			btn.disabled = true
			btn.text = "Bought!"
			_update_buttons()
		)
		buttons[perk["name"]] = btn
		vbox.add_child(btn)
		
		perk_container.add_child(vbox)

func _update_buttons():
	var souls = RunProgress.get_total_souls_collected()
	for perk_name in buttons.keys():
		var index = shown_perks.find(func(p): return p["name"] == perk_name)
		if index != -1:
			var perk = shown_perks[index]
			buttons[perk_name].disabled = souls < perk["cost"] or buttons[perk_name].disabled
			if souls < perk["cost"]:
				buttons[perk_name].text = "Not enough Souls!"
			else:
				buttons[perk_name].text = "Buy"

func _on_button_pressed() -> void:
	get_tree().paused = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().change_scene_to_file("res://Scenes/infinite_run.tscn")
