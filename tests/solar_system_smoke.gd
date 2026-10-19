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
	var moon_count := screen.moon_visuals.size()
	if moon_count < 20 or not screen.planet_roots.has("Earth") or not screen.moon_visuals.has("Moon"):
		push_error("Major planetary moons were not created")
		quit(1)
		return
	if screen.camera.size < 60.0 or screen.focus_name != "":
		push_error("Solar system should open in a full-system overview")
		quit(1)
		return
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
	screen._set_speed(100.0)
	screen._process(0.25)
	var new_earth := (screen.planet_roots["Earth"] as Node3D).position
	if screen.sim_days < 90.0 or old_earth.distance_to(new_earth) < 0.1:
		push_error("Planets and moons must advance on their orbital periods when simulation time runs")
		quit(1)
		return
	screen._show_overview()
	if screen.focus_name != "" or screen.current_view_size < 60.0:
		push_error("System overview control did not restore the full solar system")
		quit(1)
		return
	print("SOLAR_SYSTEM_SMOKE_PASS: planet and moon bodies, orbital motion, destinations and science briefings")
	quit(0)
