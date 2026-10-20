extends Control
class_name OFSolarSystemScreen

signal return_to_builder

const OrbitalPhysics = preload("res://scripts/core/orbital_physics.gd")
const SUN_MASS_KG := 1.98847e30
const MOON_MASS_KG := {
	"Moon":7.342e22,"Phobos":1.0659e16,"Deimos":1.4762e15,
	"Io":8.9319e22,"Europa":4.7998e22,"Ganymede":1.4819e23,"Callisto":1.0759e23,
	"Titan":1.3452e23,"Enceladus":1.0802e20,"Rhea":2.3065e21,"Iapetus":1.8056e21,
	"Titania":3.527e21,"Oberon":3.014e21,"Miranda":6.59e19,"Ariel":1.353e21,
	"Triton":2.14e22,"Proteus":4.4e19,"Nereid":3.1e19,
	"Charon":1.586e21,"Nix":5.8e16,"Hydra":3.2e16
}
const MOON_ECCENTRICITY := {
	"Moon":0.0549,"Phobos":0.0151,"Deimos":0.00033,
	"Io":0.0041,"Europa":0.0094,"Ganymede":0.0013,"Callisto":0.0074,
	"Titan":0.0288,"Enceladus":0.0047,"Rhea":0.001,"Iapetus":0.0283,
	"Titania":0.0011,"Oberon":0.0014,"Miranda":0.0013,"Ariel":0.0012,
	"Triton":0.000016,"Proteus":0.00053,"Nereid":0.7507,
	"Charon":0.0002,"Nix":0.002,"Hydra":0.0059
}
const MOON_RETROGRADE := {"Triton":true}

const PLANETS := [
	{"name":"Mercury","kind":"TERRESTRIAL PLANET","au":0.387,"year":87.969,"day":1407.6,"radius":0.24,"mass":3.3011e23,"ecc":0.2056,"peri":0.84,"color":"#9e9488","accent":"#6e655e","phase":1.1,"lesson":"A fast, hot world with almost no atmosphere. Compare a close solar flyby with the cost of braking into orbit."},
	{"name":"Venus","kind":"TERRESTRIAL PLANET","au":0.723,"year":224.701,"day":-5832.5,"radius":0.36,"mass":4.8675e24,"ecc":0.0068,"peri":1.34,"color":"#d9b77d","accent":"#a87448","phase":2.6,"lesson":"A thick carbon-dioxide atmosphere traps heat. Plan a short-lived lander or use radar from orbit to map the surface."},
	{"name":"Earth","kind":"TERRESTRIAL PLANET","au":1.0,"year":365.256,"day":23.934,"radius":0.39,"mass":5.97237e24,"ecc":0.0167,"peri":1.80,"color":"#347db5","accent":"#5b9c65","phase":3.7,"lesson":"Home base. Practice reaching low orbit, rendezvous, and transferring a payload to a higher orbit."},
	{"name":"Mars","kind":"TERRESTRIAL PLANET","au":1.524,"year":686.98,"day":24.623,"radius":0.31,"mass":6.4171e23,"ecc":0.0934,"peri":5.00,"color":"#b85f43","accent":"#703d36","phase":5.2,"lesson":"A thin atmosphere can slow a lander, but not gently. Balance heat shields, parachutes, and powered descent."},
	{"name":"Ceres","kind":"DWARF PLANET · ASTEROID BELT","au":2.767,"year":1681.63,"day":9.07,"radius":0.19,"mass":9.39e20,"ecc":0.0758,"peri":2.01,"color":"#999b9b","accent":"#62696c","phase":4.0,"lesson":"The largest body in the asteroid belt. Practice low-gravity approach, mapping, and sample return."},
	{"name":"Jupiter","kind":"GAS GIANT","au":5.203,"year":4332.59,"day":9.925,"radius":1.0,"mass":1.8982e27,"ecc":0.0489,"peri":0.26,"color":"#c28f6c","accent":"#855b4b","phase":0.3,"lesson":"A giant planet is a destination for orbiters, not landers. Use its gravity to redirect a spacecraft toward the outer system."},
	{"name":"Saturn","kind":"RINGED GAS GIANT","au":9.537,"year":10759.2,"day":10.7,"radius":0.82,"mass":5.6834e26,"ecc":0.0565,"peri":1.61,"color":"#d2bd8c","accent":"#947553","phase":2.0,"lesson":"Its rings are countless icy pieces in orbit. A long-lived orbiter can study the rings and deploy a probe toward Titan."},
	{"name":"Uranus","kind":"ICE GIANT","au":19.191,"year":30688.5,"day":-17.24,"radius":0.59,"mass":8.6810e25,"ecc":0.0457,"peri":2.98,"color":"#8dc9ce","accent":"#559ba9","phase":4.9,"lesson":"An ice giant tipped onto its side. A distant flyby trades quick science for lower flight time and propellant use."},
	{"name":"Neptune","kind":"ICE GIANT","au":30.07,"year":60182.0,"day":16.11,"radius":0.58,"mass":1.02413e26,"ecc":0.0113,"peri":0.78,"color":"#477ac7","accent":"#283d88","phase":5.8,"lesson":"Sunlight is faint this far out. Plan a long cruise, conserve power, and use Triton's gravity for a close encounter."},
	{"name":"Pluto","kind":"DWARF PLANET","au":39.482,"year":90560.0,"day":-153.3,"radius":0.22,"mass":1.303e22,"ecc":0.2488,"peri":3.91,"color":"#bea58d","accent":"#78675e","phase":1.8,"lesson":"A small icy world in the Kuiper Belt. A fast flyby can reveal complex terrain without needing to land."}
]

const MOONS := {
	"Earth":[{"name":"Moon","distance":384400.0,"period":27.3217,"radius":0.13,"color":"#b9b8b2","lesson":"A nearby world for practicing low-gravity landing, surface operations, and crew return."}],
	"Mars":[{"name":"Phobos","distance":9376.0,"period":0.3189,"radius":0.075,"color":"#867d73","lesson":"A tiny, irregular moon on a very close orbit. A low orbit is only a few kilometers above its surface."},{"name":"Deimos","distance":23463.0,"period":1.263,"radius":0.06,"color":"#aaa092","lesson":"A small outer moon. Compare its slower orbit with fast-moving Phobos."}],
	"Jupiter":[{"name":"Io","distance":421700.0,"period":1.769,"radius":0.13,"color":"#e5be61","lesson":"Tidal forces power intense volcanism. A safe mission uses a radiation-aware flyby."},{"name":"Europa","distance":671100.0,"period":3.551,"radius":0.12,"color":"#d7c4a4","lesson":"An icy shell may cover a global ocean. Map fractures and measure the moon's magnetic response."},{"name":"Ganymede","distance":1070400.0,"period":7.155,"radius":0.16,"color":"#99938b","lesson":"The largest moon in the solar system, with its own magnetic field. Compare its size and gravity with Mercury."},{"name":"Callisto","distance":1882700.0,"period":16.689,"radius":0.15,"color":"#77736f","lesson":"A heavily cratered outer moon. Its distance makes it a useful staging point for the Jupiter system."}],
	"Saturn":[{"name":"Titan","distance":1221870.0,"period":15.945,"radius":0.15,"color":"#d49c55","lesson":"A dense atmosphere and methane lakes make parachute delivery and aerial exploration possible."},{"name":"Enceladus","distance":237948.0,"period":1.370,"radius":0.09,"color":"#d4e0e0","lesson":"Water-rich plumes spray from the south pole. A fly-through can sample material from a hidden ocean."},{"name":"Rhea","distance":527108.0,"period":4.518,"radius":0.11,"color":"#aaa9a3","lesson":"A cratered icy moon. Practice mapping a target before choosing a safe landing ellipse."},{"name":"Iapetus","distance":3560856.0,"period":79.321,"radius":0.10,"color":"#b1aaa0","lesson":"A distant two-tone moon with a prominent equatorial ridge. Long-range navigation matters here."}],
	"Uranus":[{"name":"Titania","distance":436300.0,"period":8.706,"radius":0.12,"color":"#a7b7b4","lesson":"Uranus's largest moon. A close pass can map an ancient, fractured icy crust."},{"name":"Oberon","distance":583500.0,"period":13.463,"radius":0.11,"color":"#8d9795","lesson":"A far-out, cratered moon. Compare its orbit and surface with Titania."},{"name":"Miranda","distance":129900.0,"period":1.414,"radius":0.075,"color":"#b6c2be","lesson":"A small moon with dramatic cliffs and patchwork terrain. Targeted imaging rewards a close approach."},{"name":"Ariel","distance":190900.0,"period":2.520,"radius":0.10,"color":"#c4ccc6","lesson":"Bright canyons cross this icy moon. Track surface features from a low, polar orbit."}],
	"Neptune":[{"name":"Triton","distance":354800.0,"period":5.877,"radius":0.14,"color":"#c8a9a1","lesson":"Triton travels backward around Neptune and has active nitrogen geysers. Its orbit can reshape a spacecraft's path."},{"name":"Proteus","distance":117647.0,"period":1.122,"radius":0.085,"color":"#7b7e83","lesson":"A dark, irregular inner moon. Close navigation is difficult because it is small and dim."},{"name":"Nereid","distance":5513400.0,"period":360.14,"radius":0.065,"color":"#9b9890","lesson":"Its very stretched orbit shows how unusual satellite orbits can be."}],
	"Pluto":[{"name":"Charon","distance":19596.0,"period":6.387,"radius":0.14,"color":"#a8a09a","lesson":"Charon is so large compared with Pluto that both orbit a point in space between them."},{"name":"Nix","distance":48694.0,"period":24.855,"radius":0.07,"color":"#c2b9ad","lesson":"A small, oddly tumbling moon. Long exposures and careful tracking help characterize it."},{"name":"Hydra","distance":64738.0,"period":38.202,"radius":0.07,"color":"#aaa49a","lesson":"A small outer moon in the Pluto system. Compare its orbit with the Pluto–Charon pair."}]
}

const SPEEDS := [1.0,10.0,100.0]
const DAY_RATE := 4.0
const SYSTEM_VIEW_SIZE := 67.0

var viewport_container: SubViewportContainer
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var planet_roots: Dictionary = {}
var planet_visuals: Dictionary = {}
var moon_pivots: Dictionary = {}
var moon_visuals: Dictionary = {}
var moon_orbits: Dictionary = {}
var world_labels: Array[Label3D] = []
var asteroid_belt: MultiMeshInstance3D
var panel: VBoxContainer
var destination_list: VBoxContainer
var moon_list: VBoxContainer
var selected_planet_label: Label
var selected_moon_label: Label
var destination_detail: Label
var mission_detail: Label
var clock_label: Label
var overview_button: Button
var selected_planet := "Earth"
var selected_moon := ""
var sim_days := 0.0
var speed_multiplier := 10.0
var focus_name := ""
var current_view_size := SYSTEM_VIEW_SIZE
var _orbit_nodes: Dictionary = {}
var orbit_sim = OrbitalPhysics.new()
var station_root: Node3D
var station_pivot: Node3D
var station_unlocked := false

func _ready() -> void:
	_build_world()
	_build_interface()
	_select_planet("Earth")
	_show_overview()
	set_process(true)

func _build_world() -> void:
	viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.anchor_right = 0.76
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(960,720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#030711")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#293649")
	environment.ambient_light_energy = 0.38
	environment_node.environment = environment
	world.add_child(environment_node)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = SYSTEM_VIEW_SIZE
	camera.current = true
	camera.position = Vector3(0,35,0.01)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO,Vector3.BACK)
	var sun := MeshInstance3D.new()
	var sun_mesh := SphereMesh.new()
	sun_mesh.radius = 1.35
	sun_mesh.height = 2.7
	sun_mesh.radial_segments = 40
	sun_mesh.rings = 20
	sun.mesh = sun_mesh
	var sun_material := StandardMaterial3D.new()
	sun_material.albedo_color = Color("#ffca67")
	sun_material.emission_enabled = true
	sun_material.emission = Color("#ff9c36")
	sun_material.emission_energy_multiplier = 3.5
	sun_material.roughness = 0.8
	sun.material_override = sun_material
	world.add_child(sun)
	var halo := MeshInstance3D.new()
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 1.78
	halo_mesh.height = 3.56
	halo_mesh.radial_segments = 24
	halo_mesh.rings = 12
	halo.mesh = halo_mesh
	var halo_material := StandardMaterial3D.new()
	halo_material.albedo_color = Color(1.0,0.49,0.18,0.11)
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.material_override = halo_material
	world.add_child(halo)
	var sunlight := OmniLight3D.new()
	sunlight.light_color = Color("#ffe2b0")
	sunlight.light_energy = 2.2
	sunlight.omni_range = 90.0
	sunlight.shadow_enabled = false
	world.add_child(sunlight)
	orbit_sim.add_body("Sun",SUN_MASS_KG,Vector3.ZERO,Vector3.ZERO)
	_add_stars()
	_add_asteroid_belt()
	for data in PLANETS:
		var name := str(data["name"])
		var planet_state: Dictionary = OrbitalPhysics.kepler_state(
			SUN_MASS_KG,float(data["mass"]),float(data["au"])*OrbitalPhysics.AU_M,
			float(data["ecc"]),float(data["phase"]),float(data["peri"])
		)
		orbit_sim.add_body(name,float(data["mass"]),planet_state["position_m"],planet_state["velocity_m_s"])
		var orbit := _make_kepler_orbit(data,Color(0.21,0.38,0.53,0.58),false)
		world.add_child(orbit)
		_orbit_nodes[name] = orbit
		var root := Node3D.new()
		root.name = name
		world.add_child(root)
		planet_roots[name] = root
		var body := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = float(data["radius"])
		sphere.height = float(data["radius"])*2.0
		sphere.radial_segments = 36
		sphere.rings = 20
		body.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(str(data["color"]))
		material.roughness = 0.72
		material.metallic = 0.02
		body.material_override = material
		root.add_child(body)
		planet_visuals[name] = body
		_add_planet_details(name,root,float(data["radius"]))
		if name == "Earth": _create_earth_station(root)
		var label := Label3D.new()
		label.text = name.to_upper()
		label.font_size = 22
		label.pixel_size = 0.012
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.position = Vector3(0,0,float(data["radius"])+0.42)
		label.modulate = Color("#d5e2ee")
		label.set_meta("base_pixel_size",0.04)
		world_labels.append(label)
		root.add_child(label)
		for moon_data in MOONS.get(name,[]):
			var moon_name := str(moon_data["name"])
			var moon_orbit_data: Dictionary = moon_data.duplicate()
			moon_orbit_data["name"] = moon_name
			var pivot := Node3D.new()
			pivot.name = "MoonOrbit_"+moon_name
			root.add_child(pivot)
			var moon_orbit := _make_kepler_orbit(moon_orbit_data,Color(0.35,0.49,0.62,0.56),true)
			root.add_child(moon_orbit)
			moon_orbits[moon_name] = moon_orbit
			var moon := MeshInstance3D.new()
			var moon_sphere := SphereMesh.new()
			moon_sphere.radius = float(moon_data["radius"])
			moon_sphere.height = float(moon_data["radius"])*2.0
			moon_sphere.radial_segments = 20
			moon_sphere.rings = 12
			moon.mesh = moon_sphere
			var moon_material := StandardMaterial3D.new()
			moon_material.albedo_color = Color(str(moon_data["color"]))
			moon_material.roughness = 0.85
			moon.material_override = moon_material
			moon.position = Vector3(_moon_orbit_radius(float(moon_data["distance"])),0,0)
			pivot.add_child(moon)
			moon_visuals[moon_name] = moon
			var moon_label := Label3D.new()
			moon_label.text = moon_name
			moon_label.font_size = 15
			moon_label.pixel_size = 0.009
			moon_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			moon_label.no_depth_test = true
			moon_label.position = Vector3(0,0,float(moon_data["radius"])+0.16)
			moon_label.modulate = Color("#bbcbd6")
			moon_label.set_meta("base_pixel_size",0.032)
			world_labels.append(moon_label)
			moon.add_child(moon_label)
			moon_pivots[moon_name] = pivot
	orbit_sim.recenter_barycenter()
	_update_positions()

func set_station_unlocked(enabled: bool) -> void:
	station_unlocked = enabled
	if station_root != null: station_root.visible = enabled
	if is_node_ready() and selected_planet == "Earth" and selected_moon.is_empty(): _update_destination_panel()

func _create_earth_station(earth: Node3D) -> void:
	station_root = Node3D.new()
	station_root.name = "PermanentOrbitalStation"
	station_root.visible = station_unlocked
	earth.add_child(station_root)
	var orbit := _make_orbit(0.62,Color(0.34,0.82,0.98,0.32),0.006)
	orbit.name = "StationOrbit"
	station_root.add_child(orbit)
	station_pivot = Node3D.new()
	station_root.add_child(station_pivot)
	station_pivot.position = Vector3(0.62,0,0)
	var core := MeshInstance3D.new()
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.035
	core_mesh.bottom_radius = 0.035
	core_mesh.height = 0.10
	core_mesh.radial_segments = 12
	core.mesh = core_mesh
	core.rotation.z = PI*0.5
	core.material_override = _station_material(Color("#d3e2e7"),Color("#7eddf5"))
	station_pivot.add_child(core)
	var hub := MeshInstance3D.new()
	var hub_mesh := SphereMesh.new()
	hub_mesh.radius = 0.055
	hub_mesh.height = 0.11
	hub_mesh.radial_segments = 12
	hub_mesh.rings = 6
	hub.mesh = hub_mesh
	hub.material_override = _station_material(Color("#8195a5"),Color("#29465c"))
	station_pivot.add_child(hub)
	for side in [-1.0,1.0]:
		var panel_mesh := BoxMesh.new()
		panel_mesh.size = Vector3(0.17,0.012,0.095)
		var array := MeshInstance3D.new()
		array.mesh = panel_mesh
		array.position = Vector3(side*0.145,0,0)
		array.material_override = _station_material(Color("#2862a3"),Color("#163c67"))
		station_pivot.add_child(array)
		for line in range(3):
			var stripe := MeshInstance3D.new()
			var stripe_mesh := BoxMesh.new()
			stripe_mesh.size = Vector3(0.004,0.014,0.09)
			stripe.mesh = stripe_mesh
			stripe.position = Vector3(side*0.145+(float(line)-1.0)*0.045,0,0)
			stripe.material_override = _station_material(Color("#7ebde4"),Color("#37658a"))
			station_pivot.add_child(stripe)
	var label := Label3D.new()
	label.text = "EARTH ORBITAL STATION"
	label.font_size = 14
	label.pixel_size = 0.018
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0,0.12,0)
	label.modulate = Color("#c8f0ff")
	label.set_meta("base_pixel_size",0.026)
	world_labels.append(label)
	station_pivot.add_child(label)

func _station_material(color: Color, glow: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.42
	material.metallic = 0.48
	material.emission_enabled = true
	material.emission = glow
	material.emission_energy_multiplier = 0.5
	return material

func _add_planet_details(name: String, parent: Node3D, radius: float) -> void:
	if name == "Saturn" or name == "Uranus":
		var ring := _make_orbit(radius*(1.5 if name == "Saturn" else 1.32),Color(0.78,0.68,0.49,0.8),0.10 if name == "Saturn" else 0.035)
		ring.rotation.x = deg_to_rad(78.0 if name == "Saturn" else 8.0)
		parent.add_child(ring)
		if name == "Saturn":
			var inner_ring := _make_orbit(radius*1.21,Color(0.58,0.48,0.36,0.85),0.035)
			inner_ring.rotation.x = deg_to_rad(78.0)
			parent.add_child(inner_ring)
	if name == "Jupiter" or name == "Saturn":
		for fraction in [0.42,0.68]:
			var band := _make_orbit(radius*fraction,Color(0.62,0.40,0.28,0.24),0.025)
			parent.add_child(band)

func _add_stars() -> void:
	var field := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.035
	star_mesh.height = 0.07
	star_mesh.radial_segments = 5
	star_mesh.rings = 3
	multimesh.mesh = star_mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 320
	var rng := RandomNumberGenerator.new()
	rng.seed = 948211
	for i in range(multimesh.instance_count):
		var point := Vector3(rng.randf_range(-34,34),rng.randf_range(-30,-20),rng.randf_range(-24,24))
		var size := rng.randf_range(0.5,2.2)
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size),point))
	field.multimesh = multimesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#bad3e5")
	material.emission_enabled = true
	material.emission = Color("#7098bb")
	material.emission_energy_multiplier = 1.1
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mesh.material = material
	world.add_child(field)

func _add_asteroid_belt() -> void:
	asteroid_belt = MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	var rock := SphereMesh.new()
	rock.radius = 0.065
	rock.height = 0.13
	rock.radial_segments = 6
	rock.rings = 4
	multimesh.mesh = rock
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 260
	var rng := RandomNumberGenerator.new()
	rng.seed = 13371
	for i in range(multimesh.instance_count):
		var radius := rng.randf_range(_display_orbit_radius(2.15),_display_orbit_radius(3.35))
		var angle := rng.randf_range(0.0,TAU)
		var point := Vector3(cos(angle)*radius,rng.randf_range(-0.10,0.10),sin(angle)*radius)
		var size := rng.randf_range(0.45,1.8)
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size),point))
	asteroid_belt.multimesh = multimesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#a18c76")
	material.roughness = 1.0
	rock.material = material
	world.add_child(asteroid_belt)

func _make_orbit(radius: float, tint: Color, thickness: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(radius-thickness,0.01)
	mesh.outer_radius = radius+thickness
	mesh.rings = 96
	mesh.ring_segments = 4
	instance.mesh = mesh
	# TorusMesh lies in XY by default; solar and satellite paths are in XZ.
	instance.rotation.x = PI*0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint*0.48
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	instance.material_override = material
	return instance

func _make_kepler_orbit(data: Dictionary, tint: Color, is_moon: bool) -> MeshInstance3D:
	var line := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var eccentricity := float(data.get("ecc",MOON_ECCENTRICITY.get(str(data.get("name","")),0.0)))
	var periapsis := float(data.get("peri",0.0))
	var semi_major := float(data["distance"])/1000.0 if is_moon else float(data["au"])
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for index in range(129):
		var anomaly := TAU*float(index)/128.0
		var radius_factor := 1.0-eccentricity*cos(anomaly)
		var true_anomaly := atan2(sqrt(1.0-eccentricity*eccentricity)*sin(anomaly),cos(anomaly)-eccentricity)+periapsis
		var physical_radius := semi_major*radius_factor
		var display_radius := _moon_orbit_radius(physical_radius) if is_moon else _display_orbit_radius(physical_radius)
		mesh.surface_set_color(tint)
		mesh.surface_add_vertex(Vector3(cos(true_anomaly)*display_radius,0.0,sin(true_anomaly)*display_radius))
	mesh.surface_end()
	line.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color(tint.r,tint.g,tint.b)*0.45
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = material
	return line

func _display_orbit_radius(au: float) -> float:
	# Square-root distance compression keeps the outer system on a phone screen.
	return 4.8*sqrt(au)

func _moon_orbit_radius(distance_km: float) -> float:
	return clampf(1.15+0.55*log(1.0+distance_km/10000.0),1.3,4.0)

func _build_interface() -> void:
	var left_header := VBoxContainer.new()
	left_header.anchor_left = 0.02
	left_header.anchor_top = 0.025
	left_header.anchor_right = 0.72
	left_header.anchor_bottom = 0.19
	left_header.add_theme_constant_override("separation",4)
	add_child(left_header)
	var back := Button.new()
	back.text = "←  RETURN TO BUILDER"
	back.custom_minimum_size = Vector2(230,42)
	back.pressed.connect(func(): return_to_builder.emit())
	left_header.add_child(back)
	var title := Label.new()
	title.text = "SOLAR SYSTEM  /  EXPLORATION MAP"
	title.add_theme_font_size_override("font_size",22)
	title.add_theme_color_override("font_color",Color("#ecf4fa"))
	left_header.add_child(title)
	var scale_note := Label.new()
	scale_note.text = "NEWTONIAN N-BODY GRAVITY  ·  KEPLERIAN MOONS  ·  DISPLAY SCALE COMPRESSED"
	scale_note.add_theme_font_size_override("font_size",11)
	scale_note.add_theme_color_override("font_color",Color("#92adc0"))
	left_header.add_child(scale_note)
	var time_controls := HBoxContainer.new()
	time_controls.anchor_left = 0.02
	time_controls.anchor_top = 0.91
	time_controls.anchor_right = 0.72
	time_controls.anchor_bottom = 0.98
	time_controls.add_theme_constant_override("separation",6)
	add_child(time_controls)
	clock_label = Label.new()
	clock_label.text = "SIM DATE  /  DAY 00000"
	clock_label.add_theme_font_size_override("font_size",13)
	clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_controls.add_child(clock_label)
	for speed in SPEEDS:
		var button := Button.new()
		button.text = "%dx" % int(speed)
		button.toggle_mode = true
		button.button_pressed = is_equal_approx(speed,speed_multiplier)
		button.custom_minimum_size.x = 56
		button.pressed.connect(_set_speed.bind(speed))
		time_controls.add_child(button)
	var destination_group := ButtonGroup.new()
	var right_panel := PanelContainer.new()
	right_panel.anchor_left = 0.76
	right_panel.anchor_right = 1.0
	right_panel.anchor_bottom = 1.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0a1724")
	panel_style.border_color = Color("#243b50")
	panel_style.border_width_left = 1
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	right_panel.add_theme_stylebox_override("panel",panel_style)
	add_child(right_panel)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation",5)
	right_panel.add_child(panel)
	var panel_title := Label.new()
	panel_title.text = "DESTINATION SELECT"
	panel_title.add_theme_font_size_override("font_size",17)
	panel.add_child(panel_title)
	var destination_scroll := ScrollContainer.new()
	destination_scroll.custom_minimum_size.y = 186
	destination_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	destination_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(destination_scroll)
	destination_list = VBoxContainer.new()
	destination_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	destination_scroll.add_child(destination_list)
	for index in range(PLANETS.size()):
		var data: Dictionary = PLANETS[index]
		var button := Button.new()
		button.text = "%s   ·   %s" % [str(data["name"]),str(data["kind"])]
		button.toggle_mode = true
		button.button_group = destination_group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 36
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_planet.bind(str(data["name"])))
		destination_list.add_child(button)
	var moons_title := Label.new()
	moons_title.text = "MAJOR MOONS"
	moons_title.add_theme_font_size_override("font_size",12)
	moons_title.add_theme_color_override("font_color",Color("#8eabba"))
	panel.add_child(moons_title)
	var moon_scroll := ScrollContainer.new()
	moon_scroll.custom_minimum_size.y = 82
	moon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(moon_scroll)
	moon_list = VBoxContainer.new()
	moon_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moon_scroll.add_child(moon_list)
	selected_planet_label = Label.new()
	selected_planet_label.add_theme_font_size_override("font_size",21)
	selected_planet_label.add_theme_color_override("font_color",Color("#f2d49e"))
	panel.add_child(selected_planet_label)
	selected_moon_label = Label.new()
	selected_moon_label.add_theme_font_size_override("font_size",15)
	selected_moon_label.add_theme_color_override("font_color",Color("#b9d5e5"))
	panel.add_child(selected_moon_label)
	destination_detail = Label.new()
	destination_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	destination_detail.add_theme_font_size_override("font_size",12)
	destination_detail.add_theme_color_override("font_color",Color("#cfdae2"))
	panel.add_child(destination_detail)
	var mission_title := Label.new()
	mission_title.text = "FIELD MISSION"
	mission_title.add_theme_font_size_override("font_size",12)
	mission_title.add_theme_color_override("font_color",Color("#e6b36a"))
	panel.add_child(mission_title)
	mission_detail = Label.new()
	mission_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mission_detail.add_theme_color_override("font_color",Color("#e1eaf0"))
	panel.add_child(mission_detail)
	overview_button = Button.new()
	overview_button.text = "SYSTEM OVERVIEW"
	overview_button.pressed.connect(_show_overview)
	panel.add_child(overview_button)

func _select_planet(name: String) -> void:
	selected_planet = name
	selected_moon = ""
	for child in moon_list.get_children():
		moon_list.remove_child(child)
		child.queue_free()
	for moon_data in MOONS.get(name,[]):
		var moon_button := Button.new()
		moon_button.text = "○  %s" % str(moon_data["name"])
		moon_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		moon_button.custom_minimum_size.y = 32
		moon_button.pressed.connect(_select_moon.bind(str(moon_data["name"])))
		moon_list.add_child(moon_button)
	_update_destination_panel()
	_focus_selected()

func _select_moon(name: String) -> void:
	selected_moon = name
	_update_destination_panel()
	_focus_selected()

func _update_destination_panel() -> void:
	var data := _planet_data(selected_planet)
	selected_planet_label.text = selected_planet.to_upper()
	var moon_data := _moon_data(selected_planet,selected_moon)
	selected_moon_label.text = selected_moon.to_upper() if not selected_moon.is_empty() else str(data["kind"])
	var distance_au := float(data["au"])
	var period_years := float(data["year"])/365.256
	var radius_m := float(_diameter_km(selected_planet))*500.0
	var surface_g := OrbitalPhysics.surface_gravity(float(data["mass"]),radius_m)
	var escape_speed := OrbitalPhysics.escape_velocity(float(data["mass"]),radius_m)/1000.0
	var detail := "SUN DISTANCE  %.3f AU\nORBIT  %.2f Earth years  ·  e=%.3f\nDAY  %s h\nDIAMETER  %s km\nSURFACE GRAVITY  %.2f m/s²\nESCAPE SPEED  %.2f km/s" % [distance_au,period_years,float(data["ecc"]),_format_number(float(data["day"])),_format_number(_diameter_km(selected_planet)),surface_g,escape_speed]
	if not moon_data.is_empty():
		var moon_name := str(moon_data["name"])
		var moon_mass := float(MOON_MASS_KG.get(moon_name,0.0))
		var moon_period := OrbitalPhysics.orbital_period_seconds(float(data["mass"]),float(moon_data["distance"])*1000.0,moon_mass)/OrbitalPhysics.DAY_S
		detail += "\n\nMOON ORBIT  %.3f days\nMEAN DISTANCE  %s km" % [moon_period,_format_number(float(moon_data["distance"]))]
	destination_detail.text = detail
	mission_detail.text = str(moon_data.get("lesson",data["lesson"])) if not moon_data.is_empty() else str(data["lesson"])
	if selected_planet == "Earth" and selected_moon.is_empty():
		mission_detail.text += "\n\n" + ("PERMANENT ORBITAL STATION ACTIVE · Select the Space Dock to build long-range spacecraft." if station_unlocked else "\nComplete the satellite and heavy-payload program, then deploy the station assembly to unlock the Space Dock.")
	for child in destination_list.get_children():
		if child is Button:
			var child_name := str(child.text).split("   ·")[0]
			child.button_pressed = child_name == selected_planet

func _focus_selected() -> void:
	focus_name = selected_moon if not selected_moon.is_empty() else selected_planet
	current_view_size = 11.5 if not selected_moon.is_empty() else 8.5

func _show_overview() -> void:
	focus_name = ""
	current_view_size = SYSTEM_VIEW_SIZE

func _set_speed(speed: float) -> void:
	speed_multiplier = speed
	for child in get_children():
		if child is HBoxContainer:
			for button in child.get_children():
				if button is Button and button.text.ends_with("x"):
					button.button_pressed = button.text == "%dx" % int(speed)

func _process(delta: float) -> void:
	# Clamp frame spikes after an app pause; the integrator then advances with
	# fixed substeps so changing refresh rate cannot destabilize the system.
	var simulation_seconds := clampf(delta,0.0,0.25)*DAY_RATE*speed_multiplier*OrbitalPhysics.DAY_S
	sim_days += simulation_seconds/OrbitalPhysics.DAY_S
	orbit_sim.step(simulation_seconds,21600.0)
	_update_positions()
	if clock_label != null:
		var years := int(floor(sim_days/365.256))
		var day := int(floor(fmod(sim_days,365.256)))+1
		clock_label.text = "SIM DATE  /  YEAR %03d  ·  DAY %03d  ·  %.0f DAYS / SEC" % [years+1,day,DAY_RATE*speed_multiplier]
	if camera != null:
		var target := Vector3.ZERO
		if planet_roots.has(focus_name):
			target = (planet_roots[focus_name] as Node3D).position
		elif moon_visuals.has(focus_name):
			target = (moon_visuals[focus_name] as Node3D).global_position
		camera.size = lerpf(camera.size,current_view_size,1.0-exp(-delta*3.4))
		camera.position = target+Vector3(0.01,35.0,0.01)
		camera.look_at(target,Vector3.BACK)
		for label in world_labels:
			label.pixel_size = float(label.get_meta("base_pixel_size"))*camera.size/SYSTEM_VIEW_SIZE
	if station_pivot != null:
		station_pivot.rotation.y = sim_days*TAU/0.12

func _update_positions() -> void:
	var sun_position := orbit_sim.body_position("Sun")
	for data in PLANETS:
		var name := str(data["name"])
		var root: Node3D = planet_roots.get(name)
		if root == null: continue
		var physical_position: Vector3 = orbit_sim.body_position(name)-sun_position
		root.position = _display_position(physical_position)
		var body: MeshInstance3D = planet_visuals.get(name)
		if body != null:
			var day_hours := float(data["day"])
			body.rotation.y = fposmod(TAU*(sim_days*24.0)/day_hours,TAU)
		for moon_data in MOONS.get(name,[]):
			var moon_name := str(moon_data["name"])
			var pivot: Node3D = moon_pivots.get(moon_name)
			var moon: MeshInstance3D = moon_visuals.get(moon_name)
			if pivot == null or moon == null: continue
			var moon_mass := float(MOON_MASS_KG.get(moon_name,0.0))
			var parent_mass := float(data["mass"])
			var semi_major_m := float(moon_data["distance"])*1000.0
			var period_days := OrbitalPhysics.orbital_period_seconds(parent_mass,semi_major_m,moon_mass)/OrbitalPhysics.DAY_S
			var phase := float(abs(hash(moon_name))%6283)/1000.0
			var direction := -1.0 if bool(MOON_RETROGRADE.get(moon_name,false)) else 1.0
			var state: Dictionary = OrbitalPhysics.kepler_state(
				parent_mass,moon_mass,semi_major_m,float(MOON_ECCENTRICITY.get(moon_name,0.0)),
				phase+direction*TAU*sim_days/period_days
			)
			pivot.rotation.y = -float(state["true_anomaly"])
			moon.position = Vector3(_moon_orbit_radius(float(state["radius_m"])/1000.0),0.0,0.0)
	if asteroid_belt != null:
		asteroid_belt.rotation.y = sim_days*0.0012

func _display_position(position_m: Vector3) -> Vector3:
	var distance_au := position_m.length()/OrbitalPhysics.AU_M
	if distance_au < 0.0000001: return Vector3.ZERO
	var angle := atan2(position_m.z,position_m.x)
	var radius := _display_orbit_radius(distance_au)
	return Vector3(cos(angle)*radius,0.0,sin(angle)*radius)

func _planet_data(name: String) -> Dictionary:
	for data in PLANETS:
		if str(data["name"]) == name: return data
	return PLANETS[2]

func _moon_data(planet_name: String, moon_name: String) -> Dictionary:
	for data in MOONS.get(planet_name,[]):
		if str(data["name"]) == moon_name: return data
	return {}

func _diameter_km(name: String) -> int:
	var diameters := {"Mercury":4879,"Venus":12104,"Earth":12742,"Mars":6779,"Ceres":939,"Jupiter":139820,"Saturn":116460,"Uranus":50724,"Neptune":49244,"Pluto":2377}
	return int(diameters.get(name,0))

func _format_number(value: float) -> String:
	return "%.0f" % value if value < 10000.0 else "%.0fk" % (value/1000.0)
