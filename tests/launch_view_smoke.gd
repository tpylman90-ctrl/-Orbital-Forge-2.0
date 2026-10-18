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
	if view.pad.get_child_count() < 150:
		push_error("Launch pad scene is missing expected geometry")
		quit(1)
		return
	if view.viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
		push_error("Launch pad viewport is not set to render")
		quit(1)
		return
	view.load_craft({"parts":[{"type":"command_pod","position":[0,1.3,0],"rotation":[0,0,0],"scale":1.0}]})
	await process_frame
	if view.rocket.get_child_count() < 2:
		push_error("Launch pad did not load the vehicle")
		quit(1)
		return
	print("LAUNCH_VIEW_SMOKE_PASS: pad geometry and vehicle loaded")
	quit(0)
