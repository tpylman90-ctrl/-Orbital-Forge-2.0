extends SceneTree

const Parts = preload("res://scripts/core/parts_catalog.gd")

func _initialize() -> void:
	for part_id in Parts.ITEMS:
		var item: Dictionary = Parts.ITEMS[part_id]
		if Parts.make_mesh(item) == null:
			push_error("Catalog part has no base mesh: %s" % part_id)
			quit(1)
			return
		var holder := Node3D.new()
		Parts.add_visual(holder,item)
		if holder.get_child_count() == 0:
			push_error("Catalog part has no visible geometry: %s" % part_id)
			quit(1)
			return
		var connectors: Dictionary = Parts.ports(item)
		var radial: bool = str(item.get("kind","")) == "decoupler_radial"
		if radial and (not connectors.has("inner") or not connectors.has("outer")):
			push_error("Radial part is missing attachment points: %s" % part_id)
			quit(1)
			return
		if not radial and (not connectors.has("top") or not connectors.has("bottom")):
			push_error("Catalog part is missing axial attachment points: %s" % part_id)
			quit(1)
			return
	var command_pod := Node3D.new()
	Parts.add_visual(command_pod,Parts.ITEMS["command_pod"])
	if command_pod.get_child_count() < 12:
		push_error("Command pod is missing its molded cap and porthole details")
		quit(1)
		return
	var engine := Node3D.new()
	Parts.add_visual(engine,Parts.ITEMS["engine"])
	if engine.get_child_count() < 22:
		push_error("Engine is missing its gimbal and feed hardware")
		quit(1)
		return
	print("PARTS_CATALOG_SMOKE_PASS: %d parts" % Parts.ITEMS.size())
	quit(0)
