extends SceneTree

const Flight = preload("res://scripts/core/launch_physics.gd")
const TrajectoryMap = preload("res://scripts/ui/trajectory_map.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var craft := {"parts":[
		{"uid":"pod","type":"command_pod","scale":1.0},
		{"uid":"tank","type":"fuel_tank","scale":1.0},
		{"uid":"engine","type":"engine","scale":1.0}
	]}
	var flight := Flight.new()
	flight.configure(craft,{})
	flight.ignite()
	flight.altitude = 90000.0
	flight.downrange = 280000.0
	flight.vertical_speed = 130.0
	flight.horizontal_speed = 5100.0
	flight.pitch_degrees = 28.0
	flight.steering_input = 0.2
	flight.time_s = 12.0
	var map_view: OFTrajectoryMap = TrajectoryMap.new()
	map_view.size = Vector2(960,540)
	root.add_child(map_view)
	map_view.set_flight(flight)
	map_view.visible = true
	await process_frame
	if map_view.forecast.size() < 2:
		push_error("Flight map did not calculate a predicted trajectory")
		quit(1)
		return
	map_view.observe_flight(flight)
	if map_view.history.is_empty() or map_view._max_extent() <= Flight.R:
		push_error("Flight map did not track the craft against planetary scale")
		quit(1)
		return
	var marker: Vector2 = map_view._project(Vector2(flight.downrange,flight.altitude),Vector2(480,300),0.0001)
	if not is_finite(marker.x) or not is_finite(marker.y):
		push_error("Flight map produced invalid current-position coordinates")
		quit(1)
		return
	print("TRAJECTORY_MAP_SMOKE_PASS: live position, history, planetary scale and forecast")
	quit(0)
