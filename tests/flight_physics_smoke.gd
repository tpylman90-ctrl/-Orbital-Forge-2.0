extends SceneTree

const Flight = preload("res://scripts/core/launch_physics.gd")

func _initialize() -> void:
	var craft := {
		"parts":[
			{"uid":"pod","type":"command_pod","scale":1.0},
			{"uid":"tank","type":"fuel_tank","scale":1.0},
			{"uid":"engine","type":"engine","scale":1.0}
		]
	}
	var full := Flight.new()
	full.configure(craft,{})
	var half := Flight.new()
	half.configure(craft,{})
	if full.status != "READY" or full.initial_fuel_kg != 1100.0:
		push_error("Flight preflight did not initialize the fuel load")
		quit(1)
		return
	full.throttle = 1.0
	half.throttle = 0.5
	full.ignite()
	half.ignite()
	full.step(2.0)
	half.step(2.0)
	var full_burn := full.initial_fuel_kg-full.fuel_kg
	var half_burn := half.initial_fuel_kg-half.fuel_kg
	if full_burn <= 0.0 or half_burn <= 0.0 or absf(full_burn/half_burn-2.0) > 0.03:
		push_error("Propellant flow must scale with engine throttle")
		quit(1)
		return
	var guided := Flight.new()
	guided.configure(craft,{})
	guided.steering_input = 1.0
	guided.ignite()
	guided.step(2.0)
	if guided.pitch_degrees < 50.0 or guided.horizontal_speed <= 1.0 or guided.downrange <= 0.0:
		push_error("Touch steering must turn thrust into orbital-direction velocity")
		quit(1)
		return
	if guided.gravity() < 9.7 or guided.gravity() > 9.9 or guided.circular_orbit_speed() < 7000.0:
		push_error("Flight model lost central planet gravity or orbital-speed scale")
		quit(1)
		return
	if guided.horizontal_speed < 390.0:
		push_error("Launch did not inherit the launch site's eastward surface rotation")
		quit(1)
		return
	var q_test := Flight.new()
	q_test.configure(craft,{})
	q_test.vertical_speed = 250.0
	q_test.throttle = 0.0
	q_test.ignite()
	q_test.step(0.02)
	if q_test.dynamic_pressure_pa < 30000.0 or q_test.max_q_pa < q_test.dynamic_pressure_pa:
		push_error("Dynamic pressure and peak Max Q telemetry did not track atmospheric loading")
		quit(1)
		return
	var winged := Flight.new()
	var wing_craft := craft.duplicate(true)
	wing_craft["parts"].append({"uid":"wing","type":"spaceplane_wing","scale":1.0})
	winged.configure(wing_craft,{"spaceplane_wing":{"kind":"wing","radius":0.72,"length":1.55}})
	winged.altitude = 20000.0
	winged.vertical_speed = 250.0
	winged.ignite()
	winged.pitch_degrees = 20.0
	winged.step(0.2)
	if winged.wing_area_m2 <= 0.0 or absf(winged.lift_n) <= 1.0:
		push_error("Spaceplane wing did not generate aerodynamic lift")
		quit(1)
		return
	var preview_source := Flight.new()
	preview_source.configure(craft,{})
	preview_source.throttle = 0.65
	preview_source.ignite()
	preview_source.altitude = 80000.0
	preview_source.downrange = 320000.0
	preview_source.vertical_speed = 160.0
	preview_source.horizontal_speed = 5200.0
	preview_source.pitch_degrees = 31.0
	preview_source.steering_input = 0.18
	preview_source.time_s = 18.0
	var fuel_before_preview: float = preview_source.fuel_kg
	var time_before_preview: float = preview_source.time_s
	var path := preview_source.preview_trajectory(90.0,3.0)
	if path.size() < 2:
		push_error("Live trajectory forecast did not advance; launched=%s status=%s" % [preview_source.launched,preview_source.status])
		quit(1)
		return
	if path[0].distance_to(Vector2(preview_source.downrange,preview_source.altitude)) > 0.01:
		push_error("Live trajectory forecast began at %s instead of current position %s" % [path[0],Vector2(preview_source.downrange,preview_source.altitude)])
		quit(1)
		return
	if not is_equal_approx(preview_source.fuel_kg,fuel_before_preview) or not is_equal_approx(preview_source.time_s,time_before_preview):
		push_error("Trajectory preview mutated the live flight or consumed fuel")
		quit(1)
		return
	var recovery_craft := craft.duplicate(true)
	recovery_craft["parts"].append({"uid":"chute","type":"parachute","scale":1.0})
	var recovery := Flight.new()
	recovery.configure(recovery_craft,{"parachute":{"kind":"parachute","radius":0.48,"length":0.52}})
	recovery.altitude = 5000.0
	recovery.vertical_speed = -240.0
	recovery.horizontal_speed = 390.0
	if not recovery.deploy_parachutes() or not recovery.parachute_deployed:
		push_error("Recovery canopy should deploy in the atmosphere at a safe airspeed")
		quit(1)
		return
	var too_fast := Flight.new()
	too_fast.configure(recovery_craft,{"parachute":{"kind":"parachute","radius":0.48,"length":0.52}})
	too_fast.altitude = 5000.0
	too_fast.vertical_speed = -600.0
	if too_fast.deploy_parachutes():
		push_error("Recovery canopy should reject deployment above its safe speed")
		quit(1)
		return
	var old_final: Vector2 = path[-1]
	preview_source.steering_input = -0.45
	var corrected_path := preview_source.preview_trajectory(90.0,3.0)
	if corrected_path.size() < 2 or corrected_path[-1].distance_to(old_final) < 100.0:
		push_error("Predicted trajectory did not respond to an in-flight course change")
		quit(1)
		return
	print("FLIGHT_PHYSICS_SMOKE_PASS: throttle flow, Earth rotation, spool, Max Q, wing lift, recovery limits and live trajectory previews")
	quit(0)
