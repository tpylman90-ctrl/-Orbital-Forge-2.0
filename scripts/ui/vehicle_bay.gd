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
var selection_ids: Array[String] = []
var multi_select_mode := false
var yaw := 0.6
var distance := 9.0
var pitch := 0.35
var camera_target := Vector3(0,1,0)
var touches: Dictionary = {}
var gesture_active := false
var gesture_center := Vector2.ZERO
var gesture_span := 0.0
var drag_start := Vector2.ZERO
var placement_mode := true
var depth_mode := false
var grid_visible := true
var grid_root: Node3D
var system_overlay := false
var system_visuals: Array[Node3D] = []
var current_craft: Dictionary = {}
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
 camera.position = camera_target + Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
 camera.look_at(camera_target)

func set_craft(doc: Dictionary) -> void:
 if root3d == null: return
 current_craft = doc
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
  Parts.add_visual(holder,data)
  if str(part["uid"]) == selected_id or selection_ids.has(str(part["uid"])):
   var highlight := OmniLight3D.new()
   highlight.light_color = Color("#42d8e8") if str(part["uid"]) != selected_id else Color("#f0cf75")
   highlight.omni_range = 2.5
   highlight.light_energy = 1.2
   holder.add_child(highlight)
  nodes[str(part["uid"])] = holder
 _rebuild_system_visuals(doc)

func set_systems_overlay_enabled(enabled: bool) -> void:
 system_overlay = enabled
 if enabled:
  _rebuild_system_visuals(current_craft)
 else:
  for visual in system_visuals:
   visual.visible = false

func move_selection_preview(ids: Array[String], skip_uid: String, offset: Vector3) -> void:
 for uid in ids:
  if uid == skip_uid or not nodes.has(uid): continue
  (nodes[uid] as Node3D).position += offset

func _rebuild_system_visuals(doc: Dictionary) -> void:
 for visual in system_visuals:
  if is_instance_valid(visual): visual.queue_free()
 system_visuals.clear()
 if not system_overlay: return
 var routes: Dictionary = doc.get("fuel_routes",{})
 for engine_uid in routes:
  if not nodes.has(str(engine_uid)): continue
  var engine: Node3D = nodes[str(engine_uid)]
  for tank_uid in routes[engine_uid]:
   if not nodes.has(str(tank_uid)): continue
   var tank: Node3D = nodes[str(tank_uid)]
   _add_system_line(tank.position+Vector3(0,0.12,0),engine.position+Vector3(0,-0.12,0),Color("#38d7e8"))
 for stage in doc.get("stages",[]):
  var uid := str(stage.get("part",""))
  if not nodes.has(uid): continue
  var marker := MeshInstance3D.new()
  var sphere := SphereMesh.new()
  sphere.radius = 0.105
  sphere.height = 0.21
  marker.mesh = sphere
  var material := StandardMaterial3D.new()
  material.albedo_color = Color("#ffc55d")
  material.emission_enabled = true
  material.emission = Color("#a85c15")
  marker.material_override = material
  marker.position = nodes[uid].position+Vector3(0,0.75,0)
  root3d.add_child(marker)
  system_visuals.append(marker)

func _add_system_line(start: Vector3, finish: Vector3, color: Color) -> void:
 var direction := finish-start
 if direction.length_squared() < 0.0001: return
 var line := MeshInstance3D.new()
 var mesh := CylinderMesh.new()
 mesh.top_radius = 0.028
 mesh.bottom_radius = 0.028
 mesh.height = direction.length()
 mesh.radial_segments = 8
 line.mesh = mesh
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.emission_enabled = true
 material.emission = color*0.55
 line.material_override = material
 line.position = (start+finish)*0.5
 var axis := Vector3.UP.cross(direction.normalized())
 if axis.length_squared() > 0.0001:
  line.basis = Basis(axis.normalized(),Vector3.UP.angle_to(direction.normalized()))
 elif direction.y < 0.0:
  line.basis = Basis(Vector3.RIGHT,PI)
 root3d.add_child(line)
 system_visuals.append(line)

func show_stage_preview(original: Dictionary, preview: Dictionary, action: String = "", actor: String = "") -> void:
 # Animate the preview without changing the serialized craft.
 set_craft(preview)
 var start_positions := {}
 for part in original.get("parts",[]):
  var p: Array = part["position"]
  start_positions[str(part["uid"])] = Vector3(float(p[0]),float(p[1]),float(p[2]))
 for part in preview.get("parts",[]):
  var uid: String = str(part["uid"])
  if not nodes.has(uid) or not start_positions.has(uid): continue
  var node: Node3D = nodes[uid]
  var destination: Vector3 = node.position
  node.position = start_positions[uid]
  if node.position.distance_squared_to(destination) > 0.0001:
   var tween := create_tween()
   tween.tween_property(node,"position",destination,0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 if action in ["split_shell","release_internal_payload"] and nodes.has(actor):
  _animate_shell(nodes[actor],action)

func _animate_shell(source: Node3D, action: String) -> void:
 # Cosmetic demonstration panels: they are not serialized vehicle parts.
 for sign_value in [-1.0,1.0]:
  var panel := MeshInstance3D.new()
  var mesh := BoxMesh.new()
  mesh.size = Vector3(0.12,1.25,0.8)
  panel.mesh = mesh
  var material := StandardMaterial3D.new()
  material.albedo_color = Color("#a6c7db") if action == "split_shell" else Color("#e3b76b")
  material.metallic = 0.5
  panel.material_override = material
  root3d.add_child(panel)
  panel.position = source.position+Vector3(sign_value*0.55,0,0)
  var tween := create_tween()
  tween.set_parallel(true)
  tween.tween_property(panel,"position",panel.position+Vector3(sign_value*1.8,0.25,0),1.1)
  tween.tween_property(panel,"rotation:z",sign_value*0.6,1.1)
  tween.set_parallel(false)
  tween.tween_callback(panel.queue_free)

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
  var hit := _hit_part(pos)
  if multi_select_mode:
   if hit != "" and selection_ids.has(hit): active_drag = hit
  else:
   active_drag = hit
  if active_drag != "" and not multi_select_mode:
   selected_id = active_drag
   selected.emit(active_drag)
   drag_plane_height = nodes[active_drag].position.y
  elif active_drag != "" and multi_select_mode:
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
  var delta: Vector3 = (right*relative.x+Vector3.UP*(-relative.y))*meters_per_pixel
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

func _orbit(delta: Vector2) -> void:
 yaw -= delta.x*0.009
 pitch = clampf(pitch+delta.y*0.006,-1.35,1.35)
 _camera()

func _pan(delta: Vector2) -> void:
 var factor: float = distance*0.95/maxf(size.y,1.0)
 # Pan follows the view plane without dragging or rotating spacecraft parts.
 camera_target -= (camera.global_transform.basis.x*delta.x-camera.global_transform.basis.y*delta.y)*factor
 _camera()

func _zoom(ratio: float) -> void:
 if ratio <= 0.001: return
 distance = clampf(distance/ratio,2.5,35.0)
 _camera()

func reset_camera() -> void:
 yaw = 0.6
 pitch = 0.35
 distance = 9.0
 camera_target = Vector3(0,1,0)
 _camera()

func _touch_geometry() -> void:
 if touches.size() < 2: return
 var keys: Array = touches.keys()
 var a: Vector2 = touches[keys[0]]
 var b: Vector2 = touches[keys[1]]
 var center: Vector2 = (a+b)*0.5
 var span: float = a.distance_to(b)
 if gesture_span > 1.0:
  _pan(center-gesture_center)
  _zoom(span/gesture_span)
 gesture_center = center
 gesture_span = span

func _gui_input(event: InputEvent) -> void:
 # Input is delivered in viewport space; convert it to the bay's local space
 # before mapping pointer positions into the embedded 3D viewport.
 var local_event := make_input_local(event)
 if local_event is InputEventScreenTouch:
  if local_event.pressed:
   touches[local_event.index] = local_event.position
   if touches.size() == 1:
    gesture_active = false
    _begin_touch(local_event.position)
   elif touches.size() >= 2:
    # A second finger cancels part manipulation, never snaps it.
    active_drag = ""
    gesture_active = true
    gesture_span = 0.0
    _touch_geometry()
  else:
   touches.erase(local_event.index)
   if touches.is_empty():
    if not gesture_active: _finish_touch(local_event.position)
    active_drag = ""
    gesture_active = false
    gesture_span = 0.0
   else:
    # Lift the remaining finger before starting another drag.
    active_drag = ""
    gesture_active = true
    gesture_span = 0.0
 elif local_event is InputEventScreenDrag:
  if touches.has(local_event.index):
   touches[local_event.index] = local_event.position
   if touches.size() >= 2:
    _touch_geometry()
   elif not gesture_active:
    if active_drag != "":
     _continue_drag(local_event.position,local_event.relative)
    else:
     _orbit(local_event.relative)
 elif local_event is InputEventMouseButton:
  if local_event.button_index == MOUSE_BUTTON_LEFT:
   if local_event.pressed: _begin_touch(local_event.position)
   else: _finish_touch(local_event.position)
  elif local_event.button_index == MOUSE_BUTTON_MIDDLE:
   if local_event.pressed: drag_start = local_event.position
  elif local_event.button_index == MOUSE_BUTTON_WHEEL_UP and local_event.pressed:
   _zoom(1.12)
  elif local_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and local_event.pressed:
   _zoom(1.0/1.12)
 elif local_event is InputEventMouseMotion:
  if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
   _pan(local_event.relative)
  elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
   if active_drag != "": _continue_drag(local_event.position,local_event.relative)
   else: _orbit(local_event.relative)

func _hit_part(position: Vector2) -> String:
 if camera == null or nodes.is_empty() or size.x <= 0.0 or size.y <= 0.0: return ""
 var p: Vector2 = position*Vector2(viewport.size)/size
 var origin: Vector3 = camera.project_ray_origin(p)
 var direction: Vector3 = camera.project_ray_normal(p)
 var best_depth := INF
 var found := ""
 for id in nodes:
  var holder: Node3D = nodes[id]
  # Test against the primary visible mesh's projected volume. A generous
  # center sphere made adjacent tanks and engines steal each other's taps.
  var hit_mesh: MeshInstance3D
  for child in holder.get_children():
   if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
    hit_mesh = child as MeshInstance3D
    break
  if hit_mesh == null: continue
  var mesh_transform := hit_mesh.global_transform
  var inverse := mesh_transform.affine_inverse()
  var local_origin: Vector3 = inverse * origin
  var local_direction: Vector3 = inverse.basis * direction
  var local_hit: Variant = hit_mesh.get_aabb().grow(0.05).intersects_ray(local_origin,local_direction)
  if not local_hit is Vector3: continue
  var world_hit: Vector3 = mesh_transform * (local_hit as Vector3)
  var depth: float = (world_hit-origin).dot(direction)
  if depth >= 0.0 and depth < best_depth:
   best_depth = depth
   found = str(id)
 return found

func _pick(position: Vector2) -> void:
 var found := _hit_part(position)
 if found != "":
  selected_id = found
  selected.emit(found)
