extends SubViewportContainer
class_name OFLaunchView
const Parts = preload("res://scripts/core/parts_catalog.gd")
const Flight = preload("res://scripts/core/launch_physics.gd")
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var rocket: Node3D
var flames: Array[MeshInstance3D] = []
var sky: WorldEnvironment
var pad: Node3D
var ground: Node3D
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
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("#18283e")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#526579")
 env.ambient_light_energy = 0.46
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.tonemap_exposure = 0.92
 sky.environment = env
 world.add_child(sky)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-45,25,-25)
 sun.light_color = Color("#b7d3e8")
 sun.light_energy = 0.68
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
 _block(ground,Vector3(0,-0.65,0),Vector3(280,0.2,280),Color("#111c2b"))
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
 for flame in flames:
  flame.visible = burning and throttle > 0.0
  flame.scale.y = 0.7+0.75*throttle
 pad.visible = altitude < 2500.0 and absf(angle) < 0.12
 ground.visible = altitude < 8000.0 and absf(angle) < 0.16
 atmosphere_shell.visible = altitude > 1200.0 and altitude < 240000.0
 var atmosphere: float = clampf(altitude/125000.0,0.0,1.0)
 sky.environment.background_color = Color("#18283e").lerp(Color("#030711"),atmosphere)
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
