extends SceneTree

const Craft = preload("res://scripts/core/craft_document.gd")

func _initialize() -> void:
	var design := Craft.create("Test vessel")
	var core := Craft.add_part(design,"command_pod")
	var tank := Craft.add_part(design,"fuel_tank",Vector3(1.5,0,0),Vector3(0,0,1),1.5)
	var engine := Craft.add_part(design,"engine",Vector3(0,-2,0))
	if not Craft.link_parts(design,core,tank) or not Craft.link_parts(design,tank,engine): quit(1); return
	if not Craft.validate(design): quit(1); return
	if not Craft.save(design,"user://craft_smoke.json"): quit(1); return
	var restored := Craft.load("user://craft_smoke.json")
	if restored.get("links",[]).size() != 2: quit(1); return
	Craft.remove_part(restored,tank)
	if restored["links"].size() != 0 or restored["parts"].size() != 2: quit(1); return
	print("CRAFT_DOCUMENT_SMOKE_PASS")
	quit(0)
