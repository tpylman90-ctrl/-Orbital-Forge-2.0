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
var drag_moved := false
var drag_anchor_position := Vector3.ZERO
var drag_anchor_plane_point := Vector3.ZERO
var drag_plane_normal := Vector3.BACK
const DRAG_DEADZONE := 8.0
const ORBIT_DEADZONE := 8.0
enum PointerMode { IDLE, PART_PENDING, PART_DRAGGING, CAMERA_PENDING, CAMERA_ORBITING, MULTI_GESTURE }
var pointer_mode: PointerMode = PointerMode.IDLE
var pointer_last := Vector2.ZERO
var drag_world_per_screen_x := 0.0
var drag_world_per_screen_y := 0.0

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
 var live_ids: Dictionary = {}
 for part in doc.get("parts",[]):
  var uid := str(part.get("uid",""))
  var id := str(part.get("type",""))
  if uid == "" or not Parts.ITEMS.has(id): continue
  live_ids[uid] = true
  var holder: Node3D
  if nodes.has(uid) and str((nodes[uid] as Node3D).get_meta("part_type","")) == id:
   holder = nodes[uid]
  else:
   if nodes.has(uid):
    (nodes[uid] as Node3D).queue_free()
    nodes.erase(uid)
   holder = Node3D.new()
   holder.name = uid
   holder.set_meta("part_type",id)
   root3d.add_child(holder)
   Parts.add_visual(holder,Parts.ITEMS[id])
   nodes[uid] = holder
  var p: Array = part["position"]
  var r: Array = part["rotation"]
  holder.position = Vector3(float(p[0]),float(p[1]),float(p[2]))
  holder.rotation = Vector3(float(r[0]),float(r[1]),float(r[2]))
  holder.scale = Vector3.ONE*float(part["scale"])
  _sync_selection_highlight(holder,uid)
 for uid in nodes.keys():
  if not live_ids.has(str(uid)):
   (nodes[uid] as Node3D).queue_free()
   nodes.erase(uid)
 _rebuild_system_visuals(doc)

func _sync_selection_highlight(holder: Node3D, uid: String) -> void:
 var highlight := holder.get_node_or_null("BuilderSelectionHighlight") as OmniLight3D
 var is_selected := uid == selected_id or selection_ids.has(uid)
 if not is_selected:
  if highlight != null: highlight.queue_free()
  return
 if highlight == null:
  highlight = OmniLight3D.new()
  highlight.name = "BuilderSelectionHighlight"
  highlight.omni_range = 2.5
  highlight.light_energy = 1.2
  holder.add_child(highlight)
 highlight.light_color = Color("#f0cf75") if uid == selected_id else Color("#42d8e8")

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

func _begin_touch(pos: Vector2) -> void:
 drag_start = pos
 pointer_last = pos
 drag_moved = false
 active_drag = ""
 var hit := _hit_part(pos)
 if multi_select_mode:
  if hit != "" and selection_ids.has(hit):
   active_drag = hit
 else:
  active_drag = hit
 if active_drag != "":
  if not multi_select_mode:
   selected_id = active_drag
   selected.emit(active_drag)
  pointer_mode = PointerMode.PART_PENDING
  _start_drag_plane(pos)
 else:
  pointer_mode = PointerMode.CAMERA_PENDING

func _start_drag_plane(_pos: Vector2) -> void:
 if camera == null or not nodes.has(active_drag): return
 drag_anchor_position = (nodes[active_drag] as Node3D).global_position
 var camera_transform := camera.global_transform
 var depth: float = maxf(-camera.to_local(drag_anchor_position).z,camera.near+0.01)
 var viewport_center := Vector2(viewport.size)*0.5
 var world_center: Vector3 = camera.project_position(viewport_center,depth)
 var viewport_per_ui_pixel := Vector2(
  float(viewport.size.x)/maxf(size.x,1.0),
  float(viewport.size.y)/maxf(size.y,1.0)
 )
 var world_right: Vector3 = camera.project_position(viewport_center+Vector2(viewport_per_ui_pixel.x,0),depth)-world_center
 var world_down: Vector3 = camera.project_position(viewport_center+Vector2(0,viewport_per_ui_pixel.y),depth)-world_center
 drag_world_per_screen_x = absf(world_right.dot(camera_transform.basis.x.normalized()))
 drag_world_per_screen_y = absf(world_down.dot(camera_transform.basis.y.normalized()))
 if drag_world_per_screen_x < 0.000001: drag_world_per_screen_x = 0.001
 if drag_world_per_screen_y < 0.000001: drag_world_per_screen_y = 0.001

func _finish_touch(pos: Vector2) -> void:
 if pointer_mode == PointerMode.PART_DRAGGING and active_drag != "":
  piece_dragged.emit(active_drag,Vector3.ZERO,true)
 active_drag = ""
 drag_moved = false
 pointer_mode = PointerMode.IDLE
 pointer_last = pos

func _continue_drag(pos: Vector2, _relative: Vector2) -> void:
 var total_delta := pos-drag_start
 if pointer_mode == PointerMode.PART_PENDING:
  if total_delta.length() < DRAG_DEADZONE: return
  pointer_mode = PointerMode.PART_DRAGGING
  drag_moved = true
 if pointer_mode == PointerMode.PART_DRAGGING and active_drag != "" and placement_mode:
  var camera_basis := camera.global_transform.basis
  var target_position := drag_anchor_position
  target_position += camera_basis.x.normalized()*(total_delta.x*drag_world_per_screen_x)
  target_position -= camera_basis.y.normalized()*(total_delta.y*drag_world_per_screen_y)
  if not nodes.has(active_drag): return
  var node := nodes[active_drag] as Node3D
  var delta := target_position-node.global_position
  if not target_position.is_finite() or not delta.is_finite(): return
  if delta.length_squared() > 0.000001:
   node.global_position = target_position
   piece_dragged.emit(active_drag,delta,false)
  return
 if pointer_mode == PointerMode.CAMERA_PENDING:
  if total_delta.length() < ORBIT_DEADZONE: return
  pointer_mode = PointerMode.CAMERA_ORBITING
  _orbit(total_delta)
 elif pointer_mode == PointerMode.CAMERA_ORBITING:
  _orbit(pos-pointer_last)
 pointer_last = pos

func _orbit(delta: Vector2) -> void:
 yaw -= delta.x*0.009
 pitch = clampf(pitch+delta.y*0.006,-1.35,1.35)
 _camera()

func _pan(delta: Vector2) -> void:
 var factor: float = distance*0.95/maxf(size.y,1.0)
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
 var local_event := make_input_local(event)
 if local_event is InputEventScreenTouch:
  if local_event.pressed:
   touches[local_event.index] = local_event.position
   if touches.size() == 1:
    gesture_active = false
    _begin_touch(local_event.position)
   else:
    if pointer_mode == PointerMode.PART_DRAGGING and active_drag != "":
     piece_dragged.emit(active_drag,Vector3.ZERO,true)
    active_drag = ""
    drag_moved = false
    pointer_mode = PointerMode.MULTI_GESTURE
    gesture_active = true
    gesture_span = 0.0
    _touch_geometry()
  else:
   touches.erase(local_event.index)
   if touches.is_empty():
    if not gesture_active: _finish_touch(local_event.position)
    else:
     active_drag = ""
     pointer_mode = PointerMode.IDLE
    gesture_active = false
    gesture_span = 0.0
   else:
    active_drag = ""
    pointer_mode = PointerMode.MULTI_GESTURE
    gesture_active = true
    gesture_span = 0.0
 elif local_event is InputEventScreenDrag:
  if touches.has(local_event.index):
   touches[local_event.index] = local_event.position
   if touches.size() >= 2:
    _touch_geometry()
   elif not gesture_active:
    _continue_drag(local_event.position,local_event.relative)
 elif local_event is InputEventMouseButton:
  if local_event.button_index == MOUSE_BUTTON_LEFT:
   if local_event.pressed: _begin_touch(local_event.position)
   else: _finish_touch(local_event.position)
  elif local_event.button_index == MOUSE_BUTTON_MIDDLE:
   if local_event.pressed:
    drag_start = local_event.position
    pointer_last = local_event.position
  elif local_event.button_index == MOUSE_BUTTON_WHEEL_UP and local_event.pressed:
   _zoom(1.12)
  elif local_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and local_event.pressed:
   _zoom(1.0/1.12)
 elif local_event is InputEventMouseMotion:
  if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
   _pan(local_event.relative)
  elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
   _continue_drag(local_event.position,local_event.relative)

func _hit_part(position: Vector2) -> String:
 if camera == null or nodes.is_empty() or size.x <= 0.0 or size.y <= 0.0: return ""
 var p: Vector2 = position*Vector2(viewport.size)/size
 var origin: Vector3 = camera.project_ray_origin(p)
 var direction: Vector3 = camera.project_ray_normal(p)
 var best_surface_depth := INF
 var best_assisted_screen_distance := INF
 var best_fallback_depth := INF
 var best_assisted_center_depth := INF
 var surface_found := ""
 var fallback_found := ""
 var screen_assisted_found := ""
 for id in nodes:
  var holder: Node3D = nodes[id]
  # A single catalog-sized pick volume avoids tiny Blender mesh details stealing grabs.
  var part_id := str(holder.get_meta("part_type",""))
  if not Parts.ITEMS.has(part_id): continue
  var item: Dictionary = Parts.ITEMS[part_id]
  var radius: float = float(item.get("radius",0.5))
  var half_height: float = float(item.get("length",1.0))*0.5
  var kind := str(item.get("kind",""))
  var half_width: float = radius*2.0 if kind in ["wing","tail_fin","panel","radiator","boom","landing_legs"] else radius
  var local_bounds := AABB(Vector3(-half_width,-half_height,-radius),Vector3(half_width*2.0,half_height*2.0,radius*2.0))
  var part_transform := holder.global_transform
  var inverse := part_transform.affine_inverse()
  var local_origin: Vector3 = inverse*origin
  var local_direction: Vector3 = inverse.basis*direction
  var exact_hit: Variant = local_bounds.intersects_ray(local_origin,local_direction)
  if exact_hit is Vector3:
   var exact_world: Vector3 = part_transform*(exact_hit as Vector3)
   var bounds_depth: float = (exact_world-origin).dot(direction)
   var meshes: Array[Node] = holder.find_children("*","MeshInstance3D",true,false)
   for mesh_node in meshes:
    var mesh_instance := mesh_node as MeshInstance3D
    if mesh_instance == null or mesh_instance.mesh == null: continue
    var surface_depth := _ray_mesh_depth(mesh_instance.mesh,mesh_instance.global_transform,origin,direction)
    if surface_depth < best_surface_depth:
     best_surface_depth = surface_depth
     surface_found = str(id)
   # If a part has no triangle mesh (or its mesh has a small opening at this
   # exact point), keep its catalog-sized proxy as the forgiving fallback.
   if bounds_depth >= 0.0 and bounds_depth < best_fallback_depth:
    best_fallback_depth = bounds_depth
    fallback_found = str(id)
  # Keep the touch target a fixed size in screen pixels at close and distant zoom.
  var min_screen := Vector2(INF,INF)
  var max_screen := Vector2(-INF,-INF)
  var visible_corners := 0
  for x_side in range(2):
   for y_side in range(2):
    for z_side in range(2):
     var local_corner := local_bounds.position+Vector3(
      local_bounds.size.x*float(x_side),
      local_bounds.size.y*float(y_side),
      local_bounds.size.z*float(z_side)
     )
     var world_corner: Vector3 = part_transform*local_corner
     if camera.is_position_behind(world_corner): continue
     var screen_corner: Vector2 = camera.unproject_position(world_corner)*size/Vector2(viewport.size)
     min_screen = min_screen.min(screen_corner)
     max_screen = max_screen.max(screen_corner)
     visible_corners += 1
  if visible_corners == 0: continue
  var screen_bounds := Rect2(min_screen,max_screen-min_screen)
  var closest_screen := Vector2(
   clampf(position.x,screen_bounds.position.x,screen_bounds.end.x),
   clampf(position.y,screen_bounds.position.y,screen_bounds.end.y)
  )
  var screen_distance := position.distance_to(closest_screen)
  var depth: float = camera.global_position.distance_to(holder.global_position)
  if screen_distance <= 28.0 and (
   screen_distance < best_assisted_screen_distance-0.01
   or (absf(screen_distance-best_assisted_screen_distance) <= 0.01 and depth < best_assisted_center_depth)
  ):
   best_assisted_screen_distance = screen_distance
   best_assisted_center_depth = depth
   screen_assisted_found = str(id)
 if surface_found != "": return surface_found
 if screen_assisted_found != "": return screen_assisted_found
 return fallback_found

func _ray_mesh_depth(mesh: Mesh, mesh_transform: Transform3D, origin: Vector3, direction: Vector3) -> float:
 var faces := mesh.get_faces()
 if faces.size() < 3: return INF
 var inverse := mesh_transform.affine_inverse()
 var local_origin: Vector3 = inverse*origin
 var local_direction: Vector3 = inverse.basis*direction
 var nearest_depth := INF
 for index in range(0,faces.size()-2,3):
  var a: Vector3 = faces[index]
  var edge_one: Vector3 = faces[index+1]-a
  var edge_two: Vector3 = faces[index+2]-a
  var cross := local_direction.cross(edge_two)
  var determinant := edge_one.dot(cross)
  if absf(determinant) < 0.000001: continue
  var inverse_determinant := 1.0/determinant
  var from_a := local_origin-a
  var u := from_a.dot(cross)*inverse_determinant
  if u < 0.0 or u > 1.0: continue
  var q := from_a.cross(edge_one)
  var v := local_direction.dot(q)*inverse_determinant
  if v < 0.0 or u+v > 1.0: continue
  var ray_distance := edge_two.dot(q)*inverse_determinant
  if ray_distance < 0.0: continue
  var local_hit := local_origin+local_direction*ray_distance
  var world_hit: Vector3 = mesh_transform*local_hit
  var depth := (world_hit-origin).dot(direction)
  if depth >= 0.0 and depth < nearest_depth: nearest_depth = depth
 return nearest_depth

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
  if active_drag != "" and drag_moved:
   piece_dragged.emit(active_drag,Vector3.ZERO,true)
  active_drag = ""
  drag_moved = false
  touches.clear()
  gesture_active = false
  pointer_mode = PointerMode.IDLE
  pointer_last = Vector2.ZERO

func _pick(position: Vector2) -> void:
 var found := _hit_part(position)
 if found != "":
  selected_id = found
  selected.emit(found)
