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
		push_error("Command pod is missing its pressure-shell and porthole details")
		quit(1)
		return
	var pod_spec: Dictionary = Parts.ITEMS["command_pod"]
	var pod_length := float(pod_spec["length"])
	var pod_radius := float(pod_spec["radius"])
	var pod_vertices: PackedVector3Array = Parts.make_mesh(pod_spec).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var pod_tip_radius := 0.0
	for vertex in pod_vertices:
		if vertex.y > pod_length*0.49:
			pod_tip_radius = maxf(pod_tip_radius,Vector2(vertex.x,vertex.z).length())
	if pod_tip_radius > pod_radius*0.03:
		push_error("Command pod crown still has a broad flat top")
		quit(1)
		return
	for detail in command_pod.get_children():
		if detail is MeshInstance3D and detail.mesh is CylinderMesh and detail.position.y > pod_length*0.47:
			push_error("Command pod has a separate disk at the cone crown")
			quit(1)
			return
	var engine := Node3D.new()
	Parts.add_visual(engine,Parts.ITEMS["engine"])
	if engine.get_child_count() < 22:
		push_error("Engine is missing its gimbal and feed hardware")
		quit(1)
		return
	var legs := Node3D.new()
	Parts.add_visual(legs,Parts.ITEMS["landing_legs"])
	if legs.get_child_count() < 18:
		push_error("Landing gear is missing its braces, hinges, or footpads")
		quit(1)
		return
	print("PARTS_CATALOG_SMOKE_PASS: %d parts" % Parts.ITEMS.size())
	quit(0)
