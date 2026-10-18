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
 env.background_color = Color("#172337")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#526175")
 env.ambient_light_energy = 0.52
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.tonemap_exposure = 0.88
 sky.environment = env
 world.add_child(sky)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-45,25,-25)
 sun.light_color = Color("#e2c99b")
 sun.light_energy = 0.82
 sun.shadow_enabled = true
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
  _beam(pad,Vector3(-4.3,y-1.15,-1.2),Vector3(-2.3,y+1.15,-1.2),0.055,Color("#e6a45e"))
  _beam(pad,Vector3(-4.3,y-1.15,1.2),Vector3(-2.3,y+1.15,1.2),0.055,Color("#e6a45e"))
 _block(pad,Vector3(-1.1,5.0,0),Vector3(2.2,0.16,0.35),Color("#cb765c"))
 # Simple service building and cylindrical propellant silos.
 _block(pad,Vector3(5,1.1,-3.5),Vector3(2.8,2.2,3),Color("#9aa5a5"))
 for z in [-4.7,-2.3]:
  _silo(pad,Vector3(6.9,1.3,z),0.55,2.6,Color("#c8d1d0"))
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
  _beam(pad,Vector3(-7.5,y-0.9,-2),Vector3(-5.7,y+0.9,-2),0.065,Color("#e0bd95"))
  _beam(pad,Vector3(-7.5,y-0.9,0),Vector3(-5.7,y+0.9,0),0.065,Color("#e0bd95"))
 _block(pad,Vector3(-2.0,8.1,-0.2),Vector3(7.3,0.28,0.45),Color("#bc7764"))
 _block(pad,Vector3(-4.5,12.3,-1),Vector3(5.5,0.2,0.5),Color("#c2a391"))
 # Retractable service arms and flexible umbilicals meet the rocket at several decks.
 for y in [2.4,5.0,7.6,10.2]:
  _block(pad,Vector3(-1.65,y,0),Vector3(2.9,0.16,0.26),Color("#a7b0b1"))
  _block(pad,Vector3(-0.45,y-0.12,0),Vector3(0.18,0.42,0.18),Color("#d6a15d"))
  _beam(pad,Vector3(-2.65,y-0.5,0),Vector3(-1.1,y-0.08,0),0.055,Color("#626e74"))
 # Catwalk rails, access ladders and red obstruction lights break up the tall silhouettes.
 for x in [-4.15,-2.45]:
  for z in [-1.28,1.28]:
   _block(pad,Vector3(x,5.25,z),Vector3(0.08,9.6,0.08),Color("#d08b55"))
 for y in [2.0,4.5,7.0,9.5]:
  _block(pad,Vector3(-3.3,y+0.38,-1.3),Vector3(2.25,0.07,0.07),Color("#d9a063"))
  _block(pad,Vector3(-3.3,y+0.38,1.3),Vector3(2.25,0.07,0.07),Color("#d9a063"))
 for x in [-7.5,-5.7,-4.3,-2.3]:
  _signal_lamp(pad,Vector3(x,12.4,0),Color("#f25f52"))
 # Equipment buildings and stepped roofs.
 _block(pad,Vector3(5.1,1.1,4.0),Vector3(3.5,2.1,3),Color("#a9b5b4"))
 _block(pad,Vector3(5.1,2.27,4.0),Vector3(4.1,0.25,3.5),Color("#7e8484"))
 _block(pad,Vector3(-8.6,1.0,6.2),Vector3(4.6,2,3.1),Color("#8c9395"))
 _block(pad,Vector3(-8.6,2.1,6.2),Vector3(5,0.25,3.4),Color("#c4b8a7"))
 # Propellant farm: cylinders on support feet with a common pipe.
 for z in [-5.5,-3.5,-1.5]:
  _silo(pad,Vector3(10.5,2,z),0.95,3.6,Color("#dadbd5"))
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
 # Concrete flame trench with a dark heat channel, lip markings and exhaust deflector.
 _block(pad,Vector3(0,0.02,-4.5),Vector3(5.2,0.22,8.0),Color("#414b50"))
 _block(pad,Vector3(0,0.16,-4.5),Vector3(3.4,0.12,8.4),Color("#1e2930"))
 _block(pad,Vector3(0,0.26,-0.5),Vector3(4.3,0.08,0.26),Color("#e1b555"))
 for side in [-1.0,1.0]:
  _block(pad,Vector3(side*2.15,0.13,-4.5),Vector3(0.18,0.5,8.1),Color("#858c8c"))
  for z in [-7.4,-5.4,-3.4,-1.4]:
   _block(pad,Vector3(side*2.15,0.4,z),Vector3(0.23,0.05,0.65),Color("#d9a756"))
 # Fine pad markings, anchor bolts and recessed service covers.
 for x in [-1.8,-0.9,0.9,1.8]:
  for z in [-1.8,1.8]:
   _cylinder(pad,Vector3(x,0.19,z),0.055,0.055,0.035,Color("#4d5558"))
 for z in [-5.8,-3.8,-1.8]:
  _block(pad,Vector3(4.4,0.02,z),Vector3(0.85,0.035,0.48),Color("#485257"))
  _block(pad,Vector3(4.4,0.045,z),Vector3(0.62,0.025,0.08),Color("#d6ab5d"))
 # Four raised hold-down clamps surround the vehicle footprint with visible pivots.
 for x_sign in [-1.0,1.0]:
  for z_sign in [-1.0,1.0]:
   var anchor := Vector3(x_sign*1.45,0.42,z_sign*1.45)
   _block(pad,anchor,Vector3(0.68,0.48,0.68),Color("#535f64"))
   _block(pad,anchor+Vector3(0,0.27,0),Vector3(0.76,0.08,0.76),Color("#c1a05b"))
   _cylinder(pad,anchor+Vector3(-x_sign*0.18,0.42,-z_sign*0.18),0.12,0.12,0.38,Color("#737f82"),12)
   _beam(pad,anchor+Vector3(-x_sign*0.18,0.62,-z_sign*0.18),Vector3(x_sign*0.18,0.98,z_sign*0.18),0.065,Color("#d4b16b"))
   _cylinder(pad,Vector3(x_sign*1.15,0.96,z_sign*1.15),0.09,0.09,0.09,Color("#e5dbbc"),10)
 # Panel seams and inset access hatches add scale to the broad concrete deck.
 for offset in [-4.8,-2.4,2.4,4.8]:
  _block(pad,Vector3(offset,0.015,0),Vector3(0.035,0.025,9.8),Color("#596366"))
  _block(pad,Vector3(0,0.015,offset),Vector3(9.8,0.025,0.035),Color("#596366"))
 for x in [-4.0,-2.0,2.0,4.0]:
  for z in [-4.0,0.0,4.0]:
   _block(pad,Vector3(x,0.035,z),Vector3(0.7,0.045,0.52),Color("#4c565a"))
   _block(pad,Vector3(x,0.065,z),Vector3(0.48,0.025,0.07),Color("#bd9854"))
 # Tower feet, access ladder rungs and segmented hazard bands give the gantry more depth.
 for x in [-4.3,-2.3]:
  for z in [-1.25,1.25]:
   _block(pad,Vector3(x,0.42,z),Vector3(0.62,0.72,0.62),Color("#69757a"))
 for y in [0.9,1.3,1.7,2.1,2.5,2.9,3.3,3.7,4.1,4.5,4.9,5.3,5.7,6.1,6.5,6.9,7.3,7.7,8.1,8.5,8.9,9.3,9.7]:
  _block(pad,Vector3(-4.1,y,-1.34),Vector3(0.1,0.055,0.1),Color("#e7b162"))
  _block(pad,Vector3(-2.5,y,-1.34),Vector3(0.1,0.055,0.1),Color("#e7b162"))
 for y in [1.2,3.6,6.0,8.4,10.8]:
  _block(pad,Vector3(-4.3,y,0),Vector3(0.22,0.7,1.65),Color("#c77d62"))
  _block(pad,Vector3(-2.3,y,0),Vector3(0.22,0.7,1.65),Color("#c77d62"))
 # Raised feed lines route from the propellant farm to the launch structure.
 _beam(pad,Vector3(8.8,0.7,-3.5),Vector3(3.3,0.7,-3.5),0.11,Color("#c89c59"))
 _beam(pad,Vector3(3.3,0.7,-3.5),Vector3(3.3,1.0,0),0.11,Color("#c89c59"))
 for x in [8.2,8.8,9.4]:
  _cylinder(pad,Vector3(x,0.82,-3.5),0.055,0.055,0.42,Color("#75848a"),8)
 # Control-building windows, service doors and cooling louvers.
 for x in [4.2,5.1,6.0]:
  _block(pad,Vector3(x,1.25,-5.04),Vector3(0.56,0.62,0.055),Color("#315264"))
  _block(pad,Vector3(x,1.25,-5.08),Vector3(0.48,0.06,0.025),Color("#93b7c1"))
 _block(pad,Vector3(5.1,0.72,-5.06),Vector3(0.7,1.15,0.08),Color("#535e63"))
 for y in [0.55,0.72,0.89,1.06,1.23,1.4,1.57]:
  _block(pad,Vector3(-8.6,y,4.62),Vector3(1.0,0.05,0.06),Color("#647176"))
 for x in [-9.6,-8.6,-7.6]:
  _block(pad,Vector3(x,0.38,4.74),Vector3(0.12,0.35,0.08),Color("#d3aa65"))
 # A compact launch-control rover and cryogenic hose rack give the foreground scale.
 _block(pad,Vector3(-10.3,0.55,2.6),Vector3(1.45,0.66,0.9),Color("#d8d8cd"))
 _block(pad,Vector3(-10.3,0.96,2.6),Vector3(0.9,0.18,0.74),Color("#637982"))
 for x in [-10.75,-9.85]:
  for z in [2.2,3.0]: _cylinder(pad,Vector3(x,0.27,z),0.17,0.17,0.12,Color("#313b40"),10)
 _block(pad,Vector3(7.8,0.65,8.9),Vector3(1.2,1.2,0.45),Color("#646f73"))
 for y in [0.3,0.55,0.8,1.05]: _cylinder(pad,Vector3(7.8,y,8.65),0.24,0.24,0.045,Color("#d0a75e"),10)
 ground = Node3D.new()
 world.add_child(ground)
 # Dark coastal scrub keeps the concrete, safety paint, and white structures
 # readable at phone scale instead of washing out into one green plane.
 _block(ground,Vector3(0,-0.65,0),Vector3(250,0.2,250),Color("#303b42"))
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
 rocket_base = 0.4-lowest if lowest < INF else 0.4
 show_altitude(0.0,0.0,false)

func show_altitude(altitude: float, throttle: float, burning: bool) -> void:
 # Compress astronomical distances only in the presentation layer.
 var display_height: float = 40.0*log(1.0+maxf(altitude,0.0)/40.0)
 rocket.position.y = rocket_base+display_height
 for flame in flames:
  flame.visible = burning and throttle > 0.0
  flame.scale.y = 0.7+0.75*throttle
 pad.visible = altitude < 2500.0
 ground.visible = altitude < 8000.0
 var atmosphere: float = clampf(altitude/110000.0,0.0,1.0)
 sky.environment.background_color = Color("#172337").lerp(Color("#050812"),atmosphere)
 _camera(display_height)

func _camera(height: float) -> void:
 if camera == null: return
 var target := Vector3(0,rocket_base+height+2.0,0)
 camera.position = target+Vector3(16,12,23)
 camera.look_at(target)
