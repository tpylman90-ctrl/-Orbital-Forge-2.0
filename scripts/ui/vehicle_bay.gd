extends SubViewportContainer
class_name OFVehicleBay
signal selected(uid: String)
const Parts = preload("res://scripts/core/parts_catalog.gd")
var viewport: SubViewport
var root3d: Node3D
var camera: Camera3D
var nodes: Dictionary = {}
var selected_id := ""
var yaw := 0.6
var distance := 9.0
var drag_start := Vector2.ZERO

func _ready() -> void:
 stretch = true
 mouse_filter = Control.MOUSE_FILTER_STOP
 viewport = SubViewport.new()
 viewport.size = Vector2i(960,600)
 viewport.own_world_3d = true
 add_child(viewport)
 root3d = Node3D.new()
 viewport.add_child(root3d)
 var environment := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("#102338")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#8aa4bf")
 environment.environment = env
 root3d.add_child(environment)
 camera = Camera3D.new()
 camera.current = true
 root3d.add_child(camera)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-40,40,0)
 root3d.add_child(light)
 _camera()

func _camera() -> void:
 if camera == null: return
 camera.position = Vector3(sin(yaw)*distance,4.5,cos(yaw)*distance)
 camera.look_at(Vector3(0,1,0))

func set_craft(doc: Dictionary) -> void:
 if root3d == null: return
 for item in nodes.values():
  (item as Node3D).queue_free()
 nodes.clear()
 for part in doc.get("parts",[]):
  var id: String = str(part.get("type",""))
  if not Parts.ITEMS.has(id): continue
  var data: Dictionary = Parts.ITEMS[id]
  var holder := Node3D.new()
  holder.name = str(part["uid"])
  root3d.add_child(holder)
  var p: Array = part["position"]
  var r: Array = part["rotation"]
  holder.position = Vector3(float(p[0]),float(p[1]),float(p[2]))
  holder.rotation = Vector3(float(r[0]),float(r[1]),float(r[2]))
  holder.scale = Vector3.ONE*float(part["scale"])
  var body := MeshInstance3D.new()
  body.mesh = Parts.make_mesh(data)
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color(str(data["color"]))
  mat.metallic = 0.35
  body.material_override = mat
  holder.add_child(body)
  if str(part["uid"]) == selected_id:
   var highlight := OmniLight3D.new()
   highlight.light_color = Color("#f0cf75")
   highlight.omni_range = 2.5
   highlight.light_energy = 1.2
   holder.add_child(highlight)
  nodes[str(part["uid"])] = holder

func _gui_input(event: InputEvent) -> void:
 if event is InputEventScreenTouch:
  if event.pressed: drag_start = event.position
  elif event.position.distance_to(drag_start) < 18.0: _pick(event.position)
 elif event is InputEventScreenDrag:
  yaw -= event.relative.x*0.009
  distance = clampf(distance+event.relative.y*0.015,3.0,25.0)
  _camera()
 elif event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_LEFT and event.pressed: _pick(event.position)
  if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: distance = maxf(3.0,distance-0.6); _camera()
  if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: distance = minf(25.0,distance+0.6); _camera()

func _pick(position: Vector2) -> void:
 if camera == null or nodes.is_empty(): return
 var p := position*Vector2(viewport.size)/size
 var origin := camera.project_ray_origin(p)
 var direction := camera.project_ray_normal(p)
 var best := 1.3
 var found := ""
 for id in nodes:
  var holder: Node3D = nodes[id]
  var diff: Vector3 = holder.global_position-origin
  var projected: float = maxf(0.0,diff.dot(direction))
  var closest: Vector3 = origin+projected*direction
  var d: float = closest.distance_to(holder.global_position)
  if d < best:
   best = d
   found = str(id)
 if found != "":
  selected_id = found
  selected.emit(found)
