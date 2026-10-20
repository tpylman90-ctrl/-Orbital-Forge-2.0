extends SceneTree

const SolarSystem = preload("res://scripts/ui/solar_system_screen.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen := SolarSystem.new()
	root.add_child(screen)
	await process_frame
	if screen.planet_roots.size() != 10 or screen._orbit_nodes.size() != 10:
		push_error("Solar system should contain the Sun's eight planets, Ceres, Pluto, and their orbit paths")
		quit(1)
		return
	if screen.orbit_sim.bodies.size() != 11 or not ((screen._orbit_nodes["Pluto"] as MeshInstance3D).mesh is ImmediateMesh):
		push_error("Celestial bodies must use the physical Sun-planet simulation and elliptical orbit paths")
		quit(1)
		return
	var moon_count := screen.moon_visuals.size()
	if moon_count < 20 or not screen.planet_roots.has("Earth") or not screen.moon_visuals.has("Moon"):
		push_error("Major planetary moons were not created")
		quit(1)
		return
	if screen.camera.size < 60.0 or screen.focus_name != "":
		push_error("Solar system should open in a full-system overview")
		quit(1)
		return
	if screen.station_root == null or screen.station_root.visible:
		push_error("The permanent orbital station should exist but remain locked before orbit")
		quit(1)
		return
	screen.set_station_unlocked(true)
	if not screen.station_root.visible or not screen.mission_detail.text.contains("STATION ACTIVE"):
		push_error("Unlocking orbit progress should reveal the station and Earth briefing")
		quit(1)
		return
	screen.set_station_unlocked(false)
	screen._select_planet("Jupiter")
	if screen.moon_list.get_child_count() != 4 or screen.selected_planet != "Jupiter":
		push_error("Destination selection did not expose Jupiter's major moons")
		quit(1)
		return
	screen._select_moon("Europa")
	if screen.selected_moon != "Europa" or not screen.mission_detail.text.contains("ocean"):
		push_error("Moon destination did not load its exploration briefing")
		quit(1)
		return
	var old_earth := (screen.planet_roots["Earth"] as Node3D).position
	var earth_node: Node3D = screen.planet_roots["Earth"]
	var moon_node: Node3D = screen.moon_visuals["Moon"]
	var old_moon_relative: Vector3 = moon_node.global_position-earth_node.global_position
	var initial_system_energy: float = screen.orbit_sim.total_energy_j()
	screen._set_speed(100.0)
	screen._process(0.25)
	var new_earth := (screen.planet_roots["Earth"] as Node3D).position
	if screen.sim_days < 90.0 or old_earth.distance_to(new_earth) < 0.1:
		push_error("Planets and moons must advance on their orbital periods when simulation time runs")
		quit(1)
		return
	var new_moon_relative: Vector3 = moon_node.global_position-earth_node.global_position
	if old_moon_relative.distance_to(new_moon_relative) < 0.1:
		push_error("The Moon must follow its Kepler orbit around the moving Earth")
		quit(1)
		return
	var energy_error := absf((screen.orbit_sim.total_energy_j()-initial_system_energy)/initial_system_energy)
	if energy_error > 0.01:
		push_error("The solar-system N-body simulation must remain gravitationally stable across time warp")
		quit(1)
		return
	screen._show_overview()
	if screen.focus_name != "" or screen.current_view_size < 60.0:
		push_error("System overview control did not restore the full solar system")
		quit(1)
		return
	print("SOLAR_SYSTEM_SMOKE_PASS: planet and moon bodies, orbital motion, destinations and science briefings")
	quit(0)
