extends SceneTree

const LaunchView = preload("res://scripts/ui/launch_view.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var view := LaunchView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(view)
	await process_frame
	if view.viewport == null or view.pad == null or view.camera == null:
		push_error("Launch pad scene did not finish initializing")
		quit(1)
		return
	if _count_meshes(view.pad) < 250:
		push_error("Blender launch complex is missing its authored scene geometry")
		quit(1)
		return
	if view.planet == null or view.starfield == null or view.atmosphere_shell == null:
		push_error("Launch view is missing the planet, atmosphere, or space starfield")
		quit(1)
		return
	if view.viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
		push_error("Launch pad viewport is not set to render")
		quit(1)
		return
	view.load_craft({"parts":[
		{"type":"command_pod","position":[0,2.3,0],"rotation":[0,0,0],"scale":1.0},
		{"type":"engine","position":[-0.8,0.2,0],"rotation":[0,0,0],"scale":1.0},
		{"type":"engine_heavy","position":[0,-0.2,0],"rotation":[0,0,0],"scale":1.0},
		{"type":"engine_vac","position":[0.8,0.2,0],"rotation":[0,0,0],"scale":1.0}
	]})
	await process_frame
	if view.rocket.get_child_count() < 2:
		push_error("Launch pad did not load the vehicle")
		quit(1)
		return
	if view.flames.size() != 3:
		push_error("Each installed engine needs its own exhaust plume")
		quit(1)
		return
	view.show_altitude(0.0,0.8,true)
	var plume_positions := {}
	for plume in view.flames:
		if not plume.visible:
			push_error("An engine plume failed to ignite")
			quit(1)
			return
		plume_positions[roundi(plume.global_position.x*100.0)] = true
	if plume_positions.size() != 3:
		push_error("Engine plumes should appear below their separate engine mounts")
		quit(1)
		return
	view.show_altitude(125000.0,0.0,false,350000.0,32.0,true)
	if not view.starfield.visible or view.pad.visible:
		push_error("Orbital flight view should show stars and leave the launch pad behind")
		quit(1)
		return
	view.show_altitude(0.0,0.0,false)
	for plume in view.flames:
		if plume.visible:
			push_error("Engine plume remained visible with throttle cut")
			quit(1)
			return
	print("LAUNCH_VIEW_SMOKE_PASS: pad geometry and vehicle loaded")
	quit(0)

func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count
