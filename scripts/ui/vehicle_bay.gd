extends SubViewportContainer
class_name OFVehicleBay
signal selected(uid: String)
signal piece_dragged(uid: String, offset: Vector3, finished: bool)
const Parts = preload("res://scripts/core/parts_catalog.gd")
var viewport: SubViewport
var root3d: Node3D
var camera: Camera3D
var nodes: Dictionary = {}
var selected_id := ""
var yaw := 0.6
var distance := 9.0
var drag_start := Vector2.ZERO
var placement_mode := false
var depth_mode := false
var grid_visible := true
var grid_root: Node3D
const GRID_STEP := 0.5
var active_drag := ""
var drag_plane_height := 0.0
var last_plane_point := Vector3.ZERO

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
 _make_grid()
 _camera()

func _make_grid() -> void:
 grid_root = Node3D.new()
 root3d.add_child(grid_root)
 var mesh := ImmediateMesh.new()
 mesh.surface_begin(Mesh.PRIMITIVE_LINES)
 for i in range(-20,21):
  var p: float = float(i)*GRID_STEP
  var color := Color("#557c9a55") if i != 0 else Color("#54afd0")
  for a in [Vector3(p,0,-10),Vector3(p,0,10),Vector3(-10,0,p),Vector3(10,0,p)]:
   mesh.surface_set_color(color)
   mesh.surface_add_vertex(a)
 mesh.surface_end()
 var lines := MeshInstance3D.new()
 lines.mesh = mesh
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.vertex_color_use_as_albedo = true
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.no_depth_test = false
 lines.material_override = material
 grid_root.add_child(lines)

func set_depth_mode(enabled: bool) -> void:
 depth_mode = enabled

func set_grid_visible(enabled: bool) -> void:
 grid_visible = enabled
 if grid_root != null: grid_root.visible = enabled

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

func set_placement_mode(enabled: bool) -> void:
 placement_mode = enabled

func _plane_point(screen_pos: Vector2, plane_y: float) -> Vector3:
 var p: Vector2 = screen_pos*Vector2(viewport.size)/size
 var origin: Vector3 = camera.project_ray_origin(p)
 var ray: Vector3 = camera.project_ray_normal(p)
 if absf(ray.y) < 0.005: return origin
 var t: float = (plane_y-origin.y)/ray.y
 return origin+ray*maxf(t,0.0)

func _begin_touch(pos: Vector2) -> void:
 drag_start = pos
 active_drag = ""
 if placement_mode:
  active_drag = _hit_part(pos)
  if active_drag != "":
   selected_id = active_drag
   selected.emit(active_drag)
   drag_plane_height = nodes[active_drag].position.y

func _finish_touch(pos: Vector2) -> void:
 if active_drag != "":
  piece_dragged.emit(active_drag,Vector3.ZERO,true)
 elif pos.distance_to(drag_start) < 18.0:
  _pick(pos)
 active_drag = ""

func _continue_drag(pos: Vector2, relative: Vector2) -> void:
 if active_drag != "" and placement_mode:
  # Move in camera-relative horizontal directions. Do not intersect rays with
  # the construction plane: at shallow camera angles that explodes into depth.
  var right: Vector3 = camera.global_transform.basis.x
  right.y = 0.0
  right = right.normalized()
  # Drag follows the visible screen plane: left/right and up/down.
  # Depth stays fixed, avoiding accidental motion far into the background.
  var meters_per_pixel: float = distance*0.95/maxf(size.y,1.0)
  var depth_axis := Vector3(-right.z,0.0,right.x)
  var delta: Vector3 = (right*relative.x+(depth_axis if depth_mode else Vector3.UP)*(-relative.y))*meters_per_pixel
  if not delta.is_finite(): return
  delta = delta.limit_length(0.65)
  if delta.length_squared() > 0.000001:
   # Update the preview immediately; the document and links follow the signal.
   nodes[active_drag].position += delta
   piece_dragged.emit(active_drag,delta,false)
 else:
  yaw -= relative.x*0.009
  distance = clampf(distance+relative.y*0.015,3.0,25.0)
  _camera()

func _gui_input(event: InputEvent) -> void:
 if event is InputEventScreenTouch:
  if event.pressed: _begin_touch(event.position)
  else: _finish_touch(event.position)
 elif event is InputEventScreenDrag:
  _continue_drag(event.position,event.relative)
 elif event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_LEFT:
   if event.pressed: _begin_touch(event.position)
   else: _finish_touch(event.position)
  if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
   distance = maxf(3.0,distance-0.6)
   _camera()
  if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
   distance = minf(25.0,distance+0.6)
   _camera()
 elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
  _continue_drag(event.position,event.relative)

func _hit_part(position: Vector2) -> String:
 if camera == null or nodes.is_empty() or size.x <= 0.0 or size.y <= 0.0: return ""
 var p: Vector2 = position*Vector2(viewport.size)/size
 var origin: Vector3 = camera.project_ray_origin(p)
 var direction: Vector3 = camera.project_ray_normal(p)
 var best := INF
 var found := ""
 for id in nodes:
  var holder: Node3D = nodes[id]
  var diff: Vector3 = holder.global_position-origin
  var projected: float = diff.dot(direction)
  if projected < 0.0: continue
  var closest: Vector3 = origin+projected*direction
  var d: float = closest.distance_to(holder.global_position)
  var hit_radius: float = maxf(0.45,0.75*holder.scale.x)
  if d < hit_radius and d < best:
   best = d
   found = str(id)
 return found

func _pick(position: Vector2) -> void:
 var found := _hit_part(position)
 if found != "":
  selected_id = found
  selected.emit(found)
