extends SubViewportContainer
class_name OFLaunchView
const Parts = preload("res://scripts/core/parts_catalog.gd")
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var rocket: Node3D
var flame: MeshInstance3D
var sky: WorldEnvironment
var pad: Node3D
var ground: Node3D
var rocket_base := 0.0

func _ready() -> void:
 stretch = true
 mouse_filter = Control.MOUSE_FILTER_STOP
 viewport = SubViewport.new()
 viewport.size = Vector2i(960,600)
 viewport.own_world_3d = true
 add_child(viewport)
 world = Node3D.new()
 viewport.add_child(world)
 sky = WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("#83b5cf")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#d4dce1")
 sky.environment = env
 world.add_child(sky)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-45,25,-25)
 sun.light_energy = 1.4
 world.add_child(sun)
 camera = Camera3D.new()
 camera.current = true
 camera.fov = 48.0
 world.add_child(camera)
 pad = Node3D.new()
 world.add_child(pad)
 _block(pad,Vector3(0,-0.28,0),Vector3(13,0.55,13),Color("#6b7070"))
 _block(pad,Vector3(0,0.08,0),Vector3(4.8,0.2,4.8),Color("#b9b8a7"))
 _block(pad,Vector3(0,0.2,0),Vector3(3.0,0.08,3.0),Color("#e1bc57"))
 for z in [-5.0,5.0]:
  _block(pad,Vector3(0,-0.08,z),Vector3(14,0.12,0.12),Color("#e3c265"))
 for x in [-6.0,6.0]:
  _block(pad,Vector3(x,-0.08,0),Vector3(0.12,0.12,14),Color("#e3c265"))
 # Low-poly gantry: rails, cross braces and access decks.
 for x in [-4.3,-2.3]:
  for z in [-1.25,1.25]:
   _block(pad,Vector3(x,5.0,z),Vector3(0.18,10,0.18),Color("#bd7160"))
 for y in [2.0,4.5,7.0,9.5]:
  _block(pad,Vector3(-3.3,y,0),Vector3(2.3,0.16,2.8),Color("#7c858d"))
  _block(pad,Vector3(-3.3,y+0.3,-1.2),Vector3(2.3,0.12,0.12),Color("#e3a45d"))
  _block(pad,Vector3(-3.3,y+0.3,1.2),Vector3(2.3,0.12,0.12),Color("#e3a45d"))
 _block(pad,Vector3(-1.1,5.0,0),Vector3(2.2,0.16,0.35),Color("#cb765c"))
 # Simple service building and cylindrical propellant silos.
 _block(pad,Vector3(5,1.1,-3.5),Vector3(2.8,2.2,3),Color("#9aa5a5"))
 for z in [-4.7,-2.3]:
  _cylinder(pad,Vector3(6.9,1.3,z),0.55,2.6,Color("#c8d1d0"))
 # A compact, authored-looking spaceport rather than an empty square.
 _block(pad,Vector3(0,-0.13,9),Vector3(7,0.12,12),Color("#858d88"))
 for x in [-2.9,2.9]:
  _block(pad,Vector3(x,-0.04,9),Vector3(0.11,0.03,11),Color("#dfa862"))
 for z in [6.0,9.0,12.0]:
  _block(pad,Vector3(0,-0.02,z),Vector3(1.6,0.04,0.13),Color("#eedbb2"))
 # Second lattice tower, much more substantial than the thin prototype poles.
 for x in [-7.5,-5.7]:
  for z in [-2.0,0.0]:
   _block(pad,Vector3(x,6,z),Vector3(0.28,12,0.28),Color("#867d78"))
 for y in [1.6,3.6,5.6,7.6,9.6,11.6]:
  _block(pad,Vector3(-6.6,y,-1),Vector3(2.15,0.15,2.2),Color("#b2a398"))
  _block(pad,Vector3(-6.6,y+0.2,-2),Vector3(2.15,0.12,0.12),Color("#d6b48a"))
 _block(pad,Vector3(-2.0,8.1,-0.2),Vector3(7.3,0.28,0.45),Color("#bc7764"))
 _block(pad,Vector3(-4.5,12.3,-1),Vector3(5.5,0.2,0.5),Color("#c2a391"))
 # Equipment buildings and stepped roofs.
 _block(pad,Vector3(5.1,1.1,4.0),Vector3(3.5,2.1,3),Color("#a9b5b4"))
 _block(pad,Vector3(5.1,2.27,4.0),Vector3(4.1,0.25,3.5),Color("#7e8484"))
 _block(pad,Vector3(-8.6,1.0,6.2),Vector3(4.6,2,3.1),Color("#8c9395"))
 _block(pad,Vector3(-8.6,2.1,6.2),Vector3(5,0.25,3.4),Color("#c4b8a7"))
 # Propellant farm: cylinders on support feet with a common pipe.
 for z in [-5.5,-3.5,-1.5]:
  _cylinder(pad,Vector3(10.5,2,z),0.95,3.6,Color("#dadbd5"))
  _block(pad,Vector3(10.5,0.1,z),Vector3(1.9,0.25,1.9),Color("#525d63"))
 _block(pad,Vector3(9,0.55,-3.5),Vector3(0.19,0.19,6.0),Color("#c49250"))
 _block(pad,Vector3(7.5,0.55,-3.5),Vector3(3.0,0.19,0.19),Color("#c49250"))
 # A small communications dish and mast, built from a shallow low-poly cone.
 _block(pad,Vector3(9,2.9,7),Vector3(0.16,5.8,0.16),Color("#9ca6ad"))
 var dish := MeshInstance3D.new()
 var dish_mesh := CylinderMesh.new()
 dish_mesh.top_radius = 1.35
 dish_mesh.bottom_radius = 0.25
 dish_mesh.height = 0.35
 dish_mesh.radial_segments = 12
 dish.mesh = dish_mesh
 dish.position = Vector3(9,6.0,7)
 dish.rotation.z = 0.5
 var dish_material := StandardMaterial3D.new()
 dish_material.albedo_color = Color("#d4d6cb")
 dish.material_override = dish_material
 pad.add_child(dish)
 # Ground equipment and barriers around pad.
 for x in [-10.0,-8.8,-7.6]:
  _block(pad,Vector3(x,0.28,11),Vector3(0.85,0.55,0.35),Color("#d1a968"))
 for x in [-5.0,5.0]:
  _block(pad,Vector3(x,0.4,7),Vector3(0.22,0.8,0.22),Color("#e8ba60"))
 ground = Node3D.new()
 world.add_child(ground)
 _block(ground,Vector3(0,-0.65,0),Vector3(250,0.2,250),Color("#6d826b"))
 rocket = Node3D.new()
 world.add_child(rocket)
 flame = MeshInstance3D.new()
 var exhaust := CylinderMesh.new()
 exhaust.top_radius = 0.12
 exhaust.bottom_radius = 0.7
 exhaust.height = 2.4
 exhaust.radial_segments = 10
 flame.mesh = exhaust
 var exhaust_material := StandardMaterial3D.new()
 exhaust_material.albedo_color = Color("#ffbd51")
 exhaust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 flame.material_override = exhaust_material
 rocket.add_child(flame)
 flame.visible = false
 _camera(0.0)

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

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, tint: Color) -> void:
 var mesh := CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = height
 mesh.radial_segments = 12
 var instance := MeshInstance3D.new()
 instance.mesh = mesh
 instance.position = pos
 var material := StandardMaterial3D.new()
 material.albedo_color = tint
 instance.material_override = material
 parent.add_child(instance)

func load_craft(craft: Dictionary) -> void:
 for child in rocket.get_children():
  if child != flame: child.queue_free()
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
  lowest = minf(lowest,root.position.y-float(def.get("length",1.0))*0.5*root.scale.x)
 rocket_base = 0.4-lowest if lowest < INF else 0.4
 flame.position = Vector3(0,-0.9-rocket_base,0)
 show_altitude(0.0,0.0,false)

func show_altitude(altitude: float, throttle: float, burning: bool) -> void:
 # Compress astronomical distances only in the presentation layer.
 var display_height: float = 40.0*log(1.0+maxf(altitude,0.0)/40.0)
 rocket.position.y = rocket_base+display_height
 flame.visible = burning and throttle > 0.0
 flame.scale.y = 0.65+0.55*throttle
 pad.visible = altitude < 2500.0
 ground.visible = altitude < 8000.0
 var atmosphere: float = clampf(altitude/110000.0,0.0,1.0)
 sky.environment.background_color = Color("#83b5cf").lerp(Color("#080e24"),atmosphere)
 _camera(display_height)

func _camera(height: float) -> void:
 if camera == null: return
 var target := Vector3(0,rocket_base+height+2.0,0)
 camera.position = target+Vector3(16,12,23)
 camera.look_at(target)
