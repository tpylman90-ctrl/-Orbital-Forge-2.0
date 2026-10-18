extends Control

const Craft = preload("res://scripts/core/craft_document.gd")
var active_craft: Dictionary = {}

func _ready() -> void:
	active_craft = Craft.load("user://earth_craft_v2.json")
	if active_craft.is_empty():
		active_craft = Craft.create("Starter Rocket","earth")
		Craft.add_part(active_craft,"command_pod")
		Craft.save(active_craft,"user://earth_craft_v2.json")
	var background := ColorRect.new()
	background.color = Color("#071521")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var panel := VBoxContainer.new()
	panel.anchor_left = 0.05
	panel.anchor_right = 0.95
	panel.anchor_top = 0.09
	panel.anchor_bottom = 0.93
	panel.add_theme_constant_override("separation",20)
	add_child(panel)
	var title := Label.new()
	title.text = "ORBITAL FORGE 2.0"
	title.add_theme_font_size_override("font_size",36)
	panel.add_child(title)
	var sub := Label.new()
	sub.text = "New engine foundation  |  Clean craft architecture"
	sub.add_theme_font_size_override("font_size",18)
	panel.add_child(sub)
	var status := Label.new()
	status.text = "CRAFT: %s\nCONSTRUCTION PARTS: %d\nLOCATION: EARTH" % [active_craft["name"],active_craft["parts"].size()]
	panel.add_child(status)
	var help := Label.new()
	help.text = "Project initialized. Next: 3D freeform builder, attachment tools, flight simulation, and mission progression."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(help)
