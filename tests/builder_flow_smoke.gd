extends SceneTree

const Craft = preload("res://scripts/core/craft_document.gd")
const Main = preload("res://scripts/main.gd")
const Flight = preload("res://scripts/core/launch_physics.gd")
const Parts = preload("res://scripts/core/parts_catalog.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app := Main.new()
	root.add_child(app)
	await process_frame
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
	app.active_craft = Craft.create("Launch interlock smoke test","earth")
	var launch_pod := Craft.add_part(app.active_craft,"command_pod",Vector3(0,1.3,0))
	Craft.add_part(app.active_craft,"fuel_tank",Vector3(0,0,0))
	Craft.add_part(app.active_craft,"engine",Vector3(0,-1,0))
	app.selected_uid = launch_pod
	app._refresh()
	app._start_launch_test()
	if app.flight == null or app.flight.launched:
		push_error("Opening a launch test ignited engines without a command")
		quit(1)
		return
	if app.pad_status == null or not app.pad_status.text.contains("STANDBY"):
		push_error("Launch pad did not show the armed standby state")
		quit(1)
		return
	app._ignite_launch_engines()
	if not app.flight.launched:
		push_error("Explicit ignition command did not start the flight test")
		quit(1)
		return
	app._stop_launch_test()
	app.active_craft = Craft.create("Systems workflow smoke test","earth")
	var systems_tank := Craft.add_part(app.active_craft,"fuel_tank",Vector3(-1,0,0))
	var systems_engine := Craft.add_part(app.active_craft,"engine",Vector3(1,0,0))
	app.selected_uid = systems_engine
	app._set_builder_mode("SYSTEMS")
	if app.build_panel.visible or not app.systems_panel.visible or app.bay.placement_mode:
		push_error("Systems workflow did not separate itself from part construction")
		quit(1)
		return
	var unconnected := Flight.new()
	app.active_craft["fuel_routes"][systems_engine] = []
	unconnected.configure(app.active_craft,Parts.ITEMS)
	if unconnected.status != "NEEDS FUEL CONNECTION":
		push_error("Explicit fuel routing did not block an unconnected engine")
		quit(1)
		return
	app.selected_uid = systems_tank
	app._choose_fuel_tank()
	app.selected_uid = systems_engine
	app._connect_fuel_route()
	var connected := Flight.new()
	connected.configure(app.active_craft,Parts.ITEMS)
	var fuel_before: float = connected.fuel_kg
	if connected.status != "READY" or app._fuel_route_count() != 1:
		push_error("Tank-to-engine fuel line was not saved and recognized by preflight")
		quit(1)
		return
	connected.ignite()
	connected.step(0.5)
	if connected.fuel_kg >= fuel_before:
		push_error("Connected fuel was not consumed by the assigned engine")
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
