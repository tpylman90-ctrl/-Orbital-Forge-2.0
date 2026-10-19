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
	print("FLIGHT_PHYSICS_SMOKE_PASS: throttle flow, Earth rotation, spool, Max Q, wing lift and orbital scale")
	quit(0)
