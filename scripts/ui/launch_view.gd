extends SubViewportContainer
class_name OFLaunchView
const Parts = preload("res://scripts/core/parts_catalog.gd")
const Flight = preload("res://scripts/core/launch_physics.gd")
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var rocket: Node3D
var flames: Array[MeshInstance3D] = []
var flame_cores: Array[MeshInstance3D] = []
var engine_lights: Array[OmniLight3D] = []
var sky: WorldEnvironment
var sky_material: ProceduralSkyMaterial
var pad: Node3D
var ground: Node3D
var deluge: CPUParticles3D
var planet: MeshInstance3D
var atmosphere_shell: MeshInstance3D
var starfield: MultiMeshInstance3D
var rocket_base := 0.0

func _ready() -> void:
 stretch = true
 mouse_filter = Control.MOUSE_FILTER_STOP
 viewport = SubViewport.new()
 viewport.size = Vector2i(960,600)
 viewport.own_world_3d = true
 viewport.transparent_bg = false
 viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 world = Node3D.new()
 viewport.add_child(world)
 sky = WorldEnvironment.new()
 var env := Environment.new()
 sky_material = ProceduralSkyMaterial.new()
 sky_material.sky_top_color = Color("#12243b")
 sky_material.sky_horizon_color = Color("#537587")
 sky_material.ground_bottom_color = Color("#14232c")
 sky_material.ground_horizon_color = Color("#526b70")
 sky_material.sun_angle_max = 18.0
 sky_material.sun_curve = 0.12
 var sky_resource := Sky.new()
 sky_resource.sky_material = sky_material
 env.background_mode = Environment.BG_SKY
 env.sky = sky_resource
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#526579")
 env.ambient_light_energy = 0.58
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.tonemap_exposure = 0.82
 env.glow_enabled = true
 env.glow_intensity = 0.32
 env.glow_bloom = 0.08
 sky.environment = env
 world.add_child(sky)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-24,32,-18)
 sun.light_color = Color("#ffd2a0")
 sun.light_energy = 0.88
 sun.shadow_enabled = true
 world.add_child(sun)
 camera = Camera3D.new()
 camera.current = true
 camera.fov = 48.0
 world.add_child(camera)
 var launch_asset := load("res://assets/blender/launch_bay.glb") as PackedScene
 pad = Node3D.new()
 if launch_asset != null:
  pad = launch_asset.instantiate() as Node3D
  pad.name = "Blender Authored Launch Complex"
 else:
  push_error("Missing generated Blender launch complex at res://assets/blender/launch_bay.glb")
 world.add_child(pad)
 ground = Node3D.new()
 world.add_child(ground)
 # Dark coastal scrub keeps the concrete, safety paint, and white structures
 # readable at phone scale instead of washing out into one green plane.
 _make_curved_terrain()
 _make_pad_lights()
 _make_deluge_steam()
 planet = _create_planet()
 world.add_child(planet)
 atmosphere_shell = _create_atmosphere_shell()
 world.add_child(atmosphere_shell)
 starfield = _create_starfield()
 world.add_child(starfield)
 rocket = Node3D.new()
 world.add_child(rocket)
 _camera(0.0)

func _make_engine_flame(engine_root: Node3D, part_id: String, length: float) -> MeshInstance3D:
 var flame := MeshInstance3D.new()
 var exhaust := CylinderMesh.new()
 exhaust.top_radius = 0.07
 exhaust.bottom_radius = 0.48
 exhaust.height = 1.65
 exhaust.radial_segments = 12
 flame.mesh = exhaust
 flame.position = Vector3(0,-length*0.72,0)
 var exhaust_material := StandardMaterial3D.new()
 exhaust_material.albedo_color = Color("#66bce8") if part_id in ["engine_ion","engine_plasma","thruster"] else Color("#ffad4b")
 exhaust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 flame.material_override = exhaust_material
 engine_root.add_child(flame)
 flame.visible = false
 flames.append(flame)
 var core := MeshInstance3D.new()
 var core_mesh := CylinderMesh.new()
 core_mesh.top_radius = 0.035
 core_mesh.bottom_radius = 0.19
 core_mesh.height = 1.05
 core_mesh.radial_segments = 10
 core.mesh = core_mesh
 core.position = Vector3(0,-length*0.57,0)
 var core_material := StandardMaterial3D.new()
 core_material.albedo_color = Color("#b9edff") if part_id in ["engine_ion","engine_plasma","thruster"] else Color("#fff0ba")
 core_material.emission_enabled = true
 core_material.emission = Color("#70cfff") if part_id in ["engine_ion","engine_plasma","thruster"] else Color("#ff9a39")
 core_material.emission_energy_multiplier = 2.4
 core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 core.material_override = core_material
 engine_root.add_child(core)
 core.visible = false
 flame_cores.append(core)
 var engine_light := OmniLight3D.new()
 engine_light.position = Vector3(0,-length*0.42,0)
 engine_light.light_color = Color("#80cfff") if part_id in ["engine_ion","engine_plasma","thruster"] else Color("#ff9b48")
 engine_light.light_energy = 0.0
 engine_light.omni_range = 7.0
 engine_light.shadow_enabled = false
 engine_root.add_child(engine_light)
 engine_lights.append(engine_light)
 return flame

func _block(parent: Node3D, pos: Vector3, shape: Vector3, tint: Color) -> void:
 var mesh := BoxMesh.new()
 mesh.size = shape
 var instance := MeshInstance3D.new()
 instance.mesh = mesh
 instance.position = pos
 var material := StandardMaterial3D.new()
 material.albedo_color = tint
 instance.material_override = material
 parent.add_child(instance)

func _make_curved_terrain() -> void:
 # A faceted but smooth landform follows the planet instead of ending at a square slab.
 # The center stays level around the pad; the horizon rolls away into the globe.
 var rings := 76
 var segments := 192
 var radius := 238.0
 var st := SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for ring in range(rings):
  var inner_r := radius*float(ring)/float(rings)
  var outer_r := radius*float(ring+1)/float(rings)
  for segment in range(segments):
   var a0 := TAU*float(segment)/float(segments)
   var a1 := TAU*float(segment+1)/float(segments)
   var p00 := _terrain_point(inner_r,a0)
   var p01 := _terrain_point(inner_r,a1)
   var p10 := _terrain_point(outer_r,a0)
   var p11 := _terrain_point(outer_r,a1)
   _add_terrain_triangle(st,p00,p01,p10)
   _add_terrain_triangle(st,p01,p11,p10)
 st.generate_normals()
 var terrain := MeshInstance3D.new()
 terrain.name = "Curved Launch Coast"
 terrain.mesh = st.commit()
 var material := StandardMaterial3D.new()
 material.vertex_color_use_as_albedo = true
 material.roughness = 0.98
 material.metallic = 0.0
 terrain.material_override = material
 ground.add_child(terrain)

func _terrain_point(radial_distance: float, angle: float) -> Vector3:
 var curve := smoothstep(31.0,104.0,radial_distance)
 var sphere_y := -300.0+sqrt(maxf(90000.0-radial_distance*radial_distance,0.0))
 var local_y := lerpf(-0.76,sphere_y,curve)
 var distant_ridge := maxf(radial_distance-106.0,0.0)
 local_y += curve*(sin(angle*5.0+radial_distance*0.035)*1.7+sin(angle*9.0-radial_distance*0.023)*0.8+sin(radial_distance*0.11+angle*2.0)*1.2)
 local_y += curve*maxf(sin(angle*3.0+0.7),0.0)*minf(distant_ridge*0.12,5.0)
 return Vector3(cos(angle)*radial_distance,local_y,sin(angle)*radial_distance)

func _add_terrain_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
 for point in [a,b,c]:
  var band := smoothstep(45.0,220.0,point.length())
  var variation := 0.94+0.06*sin(point.x*0.18+point.z*0.12)
  var color := Color("#263238").lerp(Color("#43504a"),band)*variation
  if point.length() > 80.0 and sin(point.x*0.055+point.z*0.08)>0.72:
   color = color.lerp(Color("#596052"),0.22)
  st.set_color(color)
  st.add_vertex(point)

func _make_pad_lights() -> void:
 # Four low-energy pools of warm work light add shape to the gantry at night.
 for spec in [
  [Vector3(-9.0,13.0,-8.0),Color("#ffc37a")],
  [Vector3(9.0,13.0,-8.0),Color("#ffc37a")],
  [Vector3(-9.0,11.0,8.0),Color("#9fdcff")],
  [Vector3(9.0,11.0,8.0),Color("#9fdcff")]
 ]:
  var light := OmniLight3D.new()
  light.position = spec[0]
  light.light_color = spec[1]
  light.light_energy = 1.3
  light.omni_range = 20.0
  light.shadow_enabled = false
  pad.add_child(light)

func _make_deluge_steam() -> void:
 deluge = CPUParticles3D.new()
 deluge.name = "Launch Trench Deluge Steam"
 deluge.position = Vector3(0,0.25,0)
 deluge.amount = 84
 deluge.lifetime = 2.3
 deluge.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
 deluge.emission_box_extents = Vector3(5.5,0.15,4.5)
 deluge.direction = Vector3(0,1,0)
 deluge.spread = 20.0
 deluge.gravity = Vector3(0,1.4,0)
 deluge.initial_velocity_min = 1.1
 deluge.initial_velocity_max = 3.8
 deluge.scale_amount_min = 0.6
 deluge.scale_amount_max = 1.5
 deluge.color = Color(0.58,0.69,0.73,0.24)
 var steam_mesh := SphereMesh.new()
 steam_mesh.radius = 0.42
 steam_mesh.height = 0.84
 steam_mesh.radial_segments = 8
 steam_mesh.rings = 4
 deluge.mesh = steam_mesh
 deluge.emitting = false
 var steam_material := StandardMaterial3D.new()
 steam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 steam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 steam_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
 deluge.material_override = steam_material
 world.add_child(deluge)

func _cylinder(parent: Node3D, pos: Vector3, top_radius: float, bottom_radius: float, height: float, tint: Color, segments: int = 12) -> void:
 var mesh := CylinderMesh.new()
 mesh.top_radius = top_radius
 mesh.bottom_radius = bottom_radius
 mesh.height = height
 mesh.radial_segments = segments
 var instance := MeshInstance3D.new()
 instance.mesh = mesh
 instance.position = pos
 var material := StandardMaterial3D.new()
 material.albedo_color = tint
 instance.material_override = material
 parent.add_child(instance)

func _silo(parent: Node3D, center: Vector3, radius: float, height: float, tint: Color) -> void:
 _cylinder(parent,center,radius,radius,height,tint,20)
 var top_y := center.y+height*0.5
 var base_y := center.y-height*0.5
 _cylinder(parent,Vector3(center.x,top_y-0.035,center.z),radius*0.88,radius*1.045,0.16,Color("#879398"),20)
 _cylinder(parent,Vector3(center.x,base_y+0.12,center.z),radius*1.045,radius*1.045,0.12,Color("#66747b"),20)
 _cylinder(parent,Vector3(center.x,center.y+height*0.28,center.z),radius*1.025,radius*1.025,0.075,Color("#879398"),20)
 _cylinder(parent,Vector3(center.x,center.y-height*0.28,center.z),radius*1.025,radius*1.025,0.075,Color("#879398"),20)
 var gauge_x := center.x+radius*0.48
 var gauge_z := center.z+radius*0.87
 _beam(parent,Vector3(gauge_x,base_y+0.32,gauge_z),Vector3(gauge_x,top_y-0.32,gauge_z),radius*0.035,Color("#53656c"))
 _block(parent,Vector3(gauge_x,center.y,gauge_z+radius*0.035),Vector3(radius*0.12,height*0.2,radius*0.045),Color("#7bb9c6"))
 _cylinder(parent,Vector3(center.x,top_y+0.12,center.z),radius*0.13,radius*0.13,0.24,Color("#68767c"),10)
 for angle in [0.0,TAU/3.0,TAU*2.0/3.0]:
  var foot := Vector3(sin(angle)*radius*0.72,-height*0.5+0.04,cos(angle)*radius*0.72)
  _block(parent,center+foot,Vector3(radius*0.36,0.18,radius*0.36),Color("#505c61"))

func _beam(parent: Node3D, start: Vector3, finish: Vector3, radius: float, tint: Color) -> void:
 var delta := finish-start
 if delta.length_squared() < 0.0001: return
 var mesh := CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = delta.length()
 mesh.radial_segments = 6
 var instance := MeshInstance3D.new()
 instance.mesh = mesh
 instance.position = (start+finish)*0.5
 instance.quaternion = Quaternion(Vector3.UP,delta.normalized())
 var material := StandardMaterial3D.new()
 material.albedo_color = tint
 material.metallic = 0.55
 instance.material_override = material
 parent.add_child(instance)

func _signal_lamp(parent: Node3D, pos: Vector3, tint: Color) -> void:
 var mesh := SphereMesh.new()
 mesh.radius = 0.11
 mesh.height = 0.2
 var instance := MeshInstance3D.new()
 instance.mesh = mesh
 instance.position = pos
 var material := StandardMaterial3D.new()
 material.albedo_color = tint
 material.emission_enabled = true
 material.emission = tint
 material.emission_energy_multiplier = 1.2
 instance.material_override = material
 parent.add_child(instance)

func load_craft(craft: Dictionary) -> void:
 for child in rocket.get_children():
  child.queue_free()
 flames.clear()
 flame_cores.clear()
 engine_lights.clear()
 var lowest := INF
 for part in craft.get("parts",[]):
  var def: Dictionary = Parts.ITEMS.get(str(part.get("type","")),{})
  if def.is_empty(): continue
  var root := Node3D.new()
  var p: Array = part["position"]
  var r: Array = part["rotation"]
  root.position = Vector3(float(p[0]),float(p[1]),float(p[2]))
  root.rotation = Vector3(float(r[0]),float(r[1]),float(r[2]))
  root.scale = Vector3.ONE*float(part.get("scale",1.0))
  Parts.add_visual(root,def)
  rocket.add_child(root)
  var part_id := str(part.get("type",""))
  var rating: Array = Flight.RATINGS.get(part_id,[0.0,0.0,0.0,0.0])
  if float(rating[2]) > 0.0:
   _make_engine_flame(root,part_id,float(def.get("length",1.0)))
  lowest = minf(lowest,root.position.y-float(def.get("length",1.0))*0.5*root.scale.x)
 rocket_base = 0.72-lowest if lowest < INF else 0.72
 show_altitude(0.0,0.0,false)

func _create_planet() -> MeshInstance3D:
 var body := MeshInstance3D.new()
 var globe := SphereMesh.new()
 globe.radius = 300.0
 globe.height = 600.0
 globe.radial_segments = 72
 globe.rings = 36
 body.mesh = globe
 body.position = Vector3(0,-300,0)
 var material := StandardMaterial3D.new()
 material.albedo_color = Color("#183c59")
 material.roughness = 0.94
 material.metallic = 0.08
 body.material_override = material
 return body

func _create_atmosphere_shell() -> MeshInstance3D:
 var shell := MeshInstance3D.new()
 var shell_mesh := SphereMesh.new()
 shell_mesh.radius = 304.0
 shell_mesh.height = 608.0
 shell_mesh.radial_segments = 64
 shell_mesh.rings = 32
 shell.mesh = shell_mesh
 shell.position = Vector3(0,-300,0)
 var material := StandardMaterial3D.new()
 material.albedo_color = Color(0.12,0.43,0.7,0.12)
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.cull_mode = BaseMaterial3D.CULL_FRONT
 shell.material_override = material
 return shell

func _create_starfield() -> MultiMeshInstance3D:
 var field := MultiMeshInstance3D.new()
 var multimesh := MultiMesh.new()
 var star_mesh := SphereMesh.new()
 star_mesh.radius = 0.72
 star_mesh.height = 1.44
 star_mesh.radial_segments = 5
 star_mesh.rings = 3
 multimesh.mesh = star_mesh
 multimesh.transform_format = MultiMesh.TRANSFORM_3D
 multimesh.instance_count = 260
 var rng := RandomNumberGenerator.new()
 rng.seed = 824031
 for i in range(multimesh.instance_count):
  var direction := Vector3(rng.randf_range(-1.0,1.0),rng.randf_range(-1.0,1.0),rng.randf_range(-1.0,1.0)).normalized()
  var transform := Transform3D(Basis.IDENTITY,direction*rng.randf_range(330.0,470.0))
  var size := rng.randf_range(0.55,1.8)
  transform.basis = Basis.IDENTITY.scaled(Vector3.ONE*size)
  multimesh.set_instance_transform(i,transform)
 field.multimesh = multimesh
 var material := StandardMaterial3D.new()
 material.albedo_color = Color("#c6d9e9")
 material.emission_enabled = true
 material.emission = Color("#7f9ab0")
 material.emission_energy_multiplier = 0.6
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 star_mesh.material = material
 return field

func show_altitude(altitude: float, throttle: float, burning: bool, downrange_m: float = 0.0, pitch: float = 0.0, orbital: bool = false) -> void:
 # Compress astronomical distances only in the presentation layer; the flight model stays SI.
 var display_height: float = 40.0*log(1.0+maxf(altitude,0.0)/40.0)
 var angle := downrange_m/Flight.R
 var visual_radius := 300.0+display_height+rocket_base
 var radial := Vector3(sin(angle),cos(angle),0.0)
 rocket.position = Vector3(0,-300,0)+radial*visual_radius
 rocket.rotation.z = -(angle+deg_to_rad(pitch))
 var ignition := burning and throttle > 0.0
 for index in range(flames.size()):
  var flame := flames[index]
  flame.visible = ignition
  flame.scale.y = 0.7+0.75*throttle
  flame_cores[index].visible = ignition
  engine_lights[index].light_energy = (0.7+2.0*throttle) if ignition else 0.0
 deluge.emitting = ignition and altitude < 350.0
 pad.visible = altitude < 2500.0 and absf(angle) < 0.12
 ground.visible = altitude < 8000.0 and absf(angle) < 0.16
 atmosphere_shell.visible = altitude > 1200.0 and altitude < 240000.0
 var atmosphere: float = clampf(altitude/125000.0,0.0,1.0)
 var altitude_blend := smoothstep(0.0,1.0,atmosphere)
 sky_material.sky_top_color = Color("#12243b").lerp(Color("#02050c"),altitude_blend)
 sky_material.sky_horizon_color = Color("#537587").lerp(Color("#0b1724"),altitude_blend)
 sky_material.ground_horizon_color = Color("#526b70").lerp(Color("#0b1724"),altitude_blend)
 sky_material.ground_bottom_color = Color("#14232c").lerp(Color("#02040a"),altitude_blend)
 starfield.visible = altitude > 42000.0 or orbital
 starfield.position = rocket.position
 _camera(display_height,angle,altitude)

func _camera(height: float, angle: float = 0.0, altitude: float = 0.0) -> void:
 if camera == null: return
 var radial := Vector3(sin(angle),cos(angle),0.0)
 var target := rocket.position+radial*2.0
 if altitude < 12000.0:
  var zoom: float = clampf(altitude / 12000.0, 0.0, 1.0)
  var offset := Vector3(30,22,42).lerp(Vector3(16,12,23),zoom)
  camera.position = target + offset
  camera.look_at(target)
 else:
  camera.position = target+radial*14.0+Vector3(0,0,23)
  camera.look_at(target,radial)
