extends SceneTree

const Craft = preload("res://scripts/core/craft_document.gd")
const Main = preload("res://scripts/main.gd")
const Flight = preload("res://scripts/core/launch_physics.gd")
const Parts = preload("res://scripts/core/parts_catalog.gd")
const CatalogIcon = preload("res://scripts/ui/part_catalog_icon.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("BUILDER_CHECKPOINT: start")
	var app := Main.new()
	root.add_child(app)
	await process_frame
	print("BUILDER_CHECKPOINT: app ready")
	if app.catalog_grid.get_child_count() != Parts.ITEMS.size():
		push_error("Part inventory did not show every component")
		quit(1)
		return
	for tile in app.catalog_grid.get_children():
		if not tile.has_meta("part_type") or tile.get_child_count() == 0 or tile.get_child(0).get_child_count() == 0 or tile.get_child(0).get_child(0).get_script() != CatalogIcon:
			push_error("Part inventory tile is missing its image or component identity")
			quit(1)
			return
	app._select_catalog_category("TANKS")
	if app.catalog_grid.get_child_count() == 0:
		push_error("Part inventory tank filter returned no components")
		quit(1)
		return
	for tile in app.catalog_grid.get_children():
		if tile.get_meta("part_category") != "TANKS":
			push_error("Part inventory category filter displayed a component from another type")
			quit(1)
			return
	app._select_catalog_category("ALL")
	print("BUILDER_CHECKPOINT: image inventory and category filters passed")
	var starter_node: Node3D = app.bay.nodes[app.selected_uid]
	var projected := app.bay.camera.unproject_position(starter_node.global_position)
	var grab_position: Vector2 = projected*app.bay.size/Vector2(app.bay.viewport.size)
	if app.bay._hit_part(grab_position) != app.selected_uid:
		push_error("Touch hit test could not select the projected center of a vehicle part")
		quit(1)
		return
	var position_before := app._part_position(Craft.find_part(app.active_craft,app.selected_uid))
	app.bay._begin_touch(grab_position)
	app.bay._continue_drag(grab_position+Vector2(60,0),Vector2(60,0))
	app.bay._finish_touch(grab_position+Vector2(60,0))
	var position_after := app._part_position(Craft.find_part(app.active_craft,app.selected_uid))
	if position_after.distance_to(position_before) < 0.1:
		push_error("Dragging a vehicle part did not update its saved position")
		quit(1)
		return
	print("BUILDER_CHECKPOINT: part grab and reposition passed")
	app.active_craft = Craft.create("Overlapping part selection test","earth")
	var camera_back := app.bay.camera.global_transform.basis.z.normalized()
	var front_part := Craft.add_part(app.active_craft,"command_pod",app.bay.camera_target+camera_back*0.35)
	Craft.add_part(app.active_craft,"command_pod",app.bay.camera_target-camera_back*0.35)
	app.selected_uid = front_part
	app.selected_uids = [front_part]
	app._refresh()
	var front_node: Node3D = app.bay.nodes[front_part]
	var overlap_point := app.bay.camera.unproject_position(front_node.global_position)*app.bay.size/Vector2(app.bay.viewport.size)
	if app.bay._hit_part(overlap_point) != front_part:
		push_error("Overlapping parts selected a hidden part behind the visible one")
		quit(1)
		return
	print("BUILDER_CHECKPOINT: overlapping part selection passed")
	app.active_craft = Craft.create("Builder flow smoke test","earth")
	var pod := Craft.add_part(app.active_craft,"command_pod",Vector3(0,1.3,0))
	app.selected_uid = pod
	app._refresh()
	app._toggle_craft_profile()
	if app.craft_profile != "SPACECRAFT":
		push_error("Craft profile did not switch to spacecraft mode")
		quit(1)
		return
	app._add_part("fuel_tank")
	if app.active_craft["links"].size() != 1:
		push_error("New body component was not attached to the selected part")
		quit(1)
		return
	var tank: Dictionary = app.active_craft["parts"].back()
	var tank_pos := Vector3(tank["position"][0],tank["position"][1],tank["position"][2])
	if absf(tank_pos.x+1.55) > 0.01:
		push_error("Spacecraft body did not follow the rotated axial connector")
		quit(1)
		return
	app.selected_uid = pod
	app._refresh()
	app._add_part("spaceplane_wing")
	if app.active_craft["links"].size() != 2 or str(app.active_craft["links"].back().get("a_port","")) != "right":
		push_error("Spacecraft wing did not attach to an open side mount")
		quit(1)
		return
	app.active_craft = Craft.create("Multi-select smoke test","earth")
	print("BUILDER_CHECKPOINT: spacecraft placement passed")
	var group_pod := Craft.add_part(app.active_craft,"command_pod",Vector3.ZERO)
	var group_tank := Craft.add_part(app.active_craft,"fuel_tank",Vector3(1,0,0))
	var group_engine := Craft.add_part(app.active_craft,"engine",Vector3(2,0,0))
	Craft.link_parts(app.active_craft,group_pod,group_tank)
	Craft.link_parts(app.active_craft,group_tank,group_engine)
	app.selected_uid = group_pod
	app.selected_uids = [group_pod]
	app.multi_select_enabled = false
	app._refresh()
	app._set_multi_select_enabled(true)
	print("BUILDER_CHECKPOINT: multi-select enabled")
	app._on_part_selected(group_tank)
	app._on_part_selected(group_engine)
	if app.selected_uids.size() != 3:
		push_error("Multi-select could not assemble a craft group")
		quit(1)
		return
	var group_distance_before := app._part_position(Craft.find_part(app.active_craft,group_pod)).distance_to(app._part_position(Craft.find_part(app.active_craft,group_engine)))
	app._on_piece_dragged(group_pod,Vector3(0.75,0.25,0),false)
	app._on_piece_dragged(group_pod,Vector3.ZERO,true)
	print("BUILDER_CHECKPOINT: group drag passed")
	var group_distance_after := app._part_position(Craft.find_part(app.active_craft,group_pod)).distance_to(app._part_position(Craft.find_part(app.active_craft,group_engine)))
	if absf(group_distance_after-group_distance_before) > 0.001 or app.active_craft["links"].size() != 2:
		push_error("Dragging a multi-selected ship did not preserve its shape and internal links")
		quit(1)
		return
	app._turn("Y")
	print("BUILDER_CHECKPOINT: group rotation passed")
	if not Craft.validate(app.active_craft):
		push_error("Batch rotation corrupted craft part transforms")
		quit(1)
		return
	app._duplicate()
	print("BUILDER_CHECKPOINT: group duplication passed")
	if app.active_craft["parts"].size() != 6 or app.active_craft["links"].size() != 4:
		push_error("Duplicating a selected craft group did not copy its internal structure")
		quit(1)
		return
	app._remove()
	print("BUILDER_CHECKPOINT: group removal passed")
	if app.active_craft["parts"].size() != 3 or not Craft.validate(app.active_craft):
		push_error("Removing a duplicated group did not remove all selected parts cleanly")
		quit(1)
		return
	app._set_multi_select_enabled(false)
	if not app.performance_label.text.contains("DESIGN ANALYSIS") or not app.performance_label.text.contains("Δv"):
		push_error("Builder performance analysis did not report design metrics")
		quit(1)
		return
	app.active_craft = Craft.create("Launch interlock smoke test","earth")
	print("BUILDER_CHECKPOINT: performance analysis passed")
	var launch_pod := Craft.add_part(app.active_craft,"command_pod",Vector3(0,1.3,0))
	Craft.add_part(app.active_craft,"fuel_tank",Vector3(0,0,0))
	Craft.add_part(app.active_craft,"engine",Vector3(0,-1,0))
	app.selected_uid = launch_pod
	app._refresh()
	app._start_launch_test()
	print("BUILDER_CHECKPOINT: launch pad opened")
	if app.flight == null or app.flight.launched:
		push_error("Opening a launch test ignited engines without a command")
		quit(1)
		return
	if app.pad_status == null or not app.pad_status.text.contains("STANDBY"):
		push_error("Launch pad did not show the armed standby state")
		quit(1)
		return
	app._ignite_launch_engines()
	print("BUILDER_CHECKPOINT: manual ignition passed")
	if not app.flight.launched:
		push_error("Explicit ignition command did not start the flight test")
		quit(1)
		return
	app._stop_launch_test()
	app.active_craft = Craft.create("Systems workflow smoke test","earth")
	var systems_tank := Craft.add_part(app.active_craft,"fuel_tank",Vector3(-1,0,0))
	var systems_tank2 := Craft.add_part(app.active_craft,"tank_short",Vector3(-2,0,0))
	var systems_engine := Craft.add_part(app.active_craft,"engine",Vector3(1,0,0))
	app.selected_uid = systems_engine
	app._set_builder_mode("SYSTEMS")
	print("BUILDER_CHECKPOINT: systems mode opened")
	if app.build_panel.visible or not app.systems_panel.visible or app.bay.placement_mode:
		push_error("Systems workflow did not separate itself from part construction")
		quit(1)
		return
	var unconnected := Flight.new()
	app.active_craft["fuel_routes"][systems_engine] = []
	app.active_craft["fuel_routing_enabled"] = true
	unconnected.configure(app.active_craft,Parts.ITEMS)
	if unconnected.status != "NEEDS FUEL CONNECTION":
		push_error("Explicit fuel routing did not block an unconnected engine")
		quit(1)
		return
	app.selected_uid = systems_tank
	app._choose_fuel_tank()
	app.selected_uid = systems_engine
	app._connect_fuel_route()
	app.selected_uid = systems_tank2
	app._choose_fuel_tank()
	app.selected_uid = systems_engine
	app._connect_fuel_route()
	var connected := Flight.new()
	connected.configure(app.active_craft,Parts.ITEMS)
	var fuel_before: float = connected.fuel_kg
	if connected.status != "READY" or app._fuel_route_count() != 2:
		push_error("Tank-to-engine fuel line was not saved and recognized by preflight")
		quit(1)
		return
	connected.ignite()
	connected.step(0.5)
	print("BUILDER_CHECKPOINT: first fuel drain passed")
	if connected.fuel_kg >= fuel_before or connected.tank_fuel[systems_tank] >= 1100.0 or connected.tank_fuel[systems_tank2] < 540.0:
		push_error("Engine did not consume the first tank in its assigned drain order")
		quit(1)
		return
	app._move_fuel_route(systems_engine,systems_tank2,-1)
	var priority_test := Flight.new()
	priority_test.configure(app.active_craft,Parts.ITEMS)
	priority_test.ignite()
	priority_test.step(0.5)
	print("BUILDER_CHECKPOINT: tank priority passed")
	if priority_test.tank_fuel[systems_tank2] >= 540.0 or priority_test.tank_fuel[systems_tank] < 1100.0:
		push_error("Per-engine tank drain priority did not follow the Systems list order")
		quit(1)
		return
	app._remove_fuel_route(systems_engine,systems_tank)
	app._remove_fuel_route(systems_engine,systems_tank2)
	var disconnected_again := Flight.new()
	disconnected_again.configure(app.active_craft,Parts.ITEMS)
	if disconnected_again.status != "NEEDS FUEL CONNECTION":
		push_error("Removing the last explicit fuel line unexpectedly restored automatic flow")
		quit(1)
		return
	var breakpoint_uid := Craft.add_part(app.active_craft,"decoupler",Vector3(0,1,0))
	app.selected_uid = breakpoint_uid
	app._stage_selected()
	if app.active_craft["stages"].size() != 1:
		push_error("Systems workflow did not designate a separation breakpoint")
		quit(1)
		return
	print("BUILDER_FLOW_SMOKE_PASS: free-form construction, separated systems, fuel routing and manual ignition")
	quit(0)
