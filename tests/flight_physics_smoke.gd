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
	print("FLIGHT_PHYSICS_SMOKE_PASS: throttle flow, steering, curved gravity and orbital scale")
	quit(0)
