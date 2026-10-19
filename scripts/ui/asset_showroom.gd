extends Control
class_name OFAssetShowroom

signal return_to_builder

const ASSETS := [
 {"name":"COMMAND POD","file":"command_pod.glb","info":"Crew cabin / docking assembly"},
 {"name":"FUEL TANK","file":"fuel_tank.glb","info":"Reinforced propellant tank"},
 {"name":"ROCKET ENGINE","file":"rocket_engine.glb","info":"Combustion chamber / expansion bell"},
 {"name":"STATION RING","file":"station_ring.glb","info":"Orbital habitat / docking hub"}
]
const ROOT := "res://assets/blender/"
var model_root: Node3D
var camera: Camera3D
var status: Label
var chosen := 0
var rotation_x := -0.22
var rotation_y := 0.45
var camera_distance := 5.0
var pointer_down := false

func _ready() -> void:
 _make_3d()
 _make_ui()
 _show_asset(0)
 set_process(true)

func _make_3d() -> void:
 var viewport_box := SubViewportContainer.new()
 viewport_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 viewport_box.stretch = true
 viewport_box.mouse_filter = Control.MOUSE_FILTER_PASS
 add_child(viewport_box)
 var view := SubViewport.new()
 view.size = Vector2i(960,640)
 view.own_world_3d = true
 view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 view.transparent_bg = false
 viewport_box.add_child(view)
 var world := Node3D.new()
 view.add_child(world)
 var environment_node := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("#081625")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("#c3d4eb")
 env.ambient_light_energy = 0.65
 environment_node.environment = env
 world.add_child(environment_node)
 model_root = Node3D.new()
 world.add_child(model_root)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-45,35,0)
 light.light_energy = 1.7
 world.add_child(light)
 var fill := DirectionalLight3D.new()
 fill.rotation_degrees = Vector3(35,-125,0)
 fill.light_energy = 0.65
 world.add_child(fill)
 camera = Camera3D.new()
 camera.current = true
 camera.fov = 45
 world.add_child(camera)
 _update_camera()

func _make_ui() -> void:
 var top := HBoxContainer.new()
 top.anchor_left = 0.02
 top.anchor_top = 0.025
 top.anchor_right = 0.98
 top.anchor_bottom = 0.12
 add_child(top)
 var back := Button.new()
 back.text = "← BACK TO BUILDER"
 back.custom_minimum_size.x = 205
 back.pressed.connect(func(): return_to_builder.emit())
 top.add_child(back)
 var heading := Label.new()
 heading.text = "  BLENDER / 3D ASSET LAB"
 heading.add_theme_font_size_override("font_size",23)
 heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 top.add_child(heading)
 var reset := Button.new()
 reset.text = "RESET VIEW"
 reset.pressed.connect(_reset_view)
 top.add_child(reset)
 var right := VBoxContainer.new()
 right.anchor_left = 0.75
 right.anchor_top = 0.19
 right.anchor_right = 0.98
 right.anchor_bottom = 0.84
 right.add_theme_constant_override("separation",8)
 add_child(right)
 right.add_child(_text("GENERATED COMPONENTS",18))
 for i in range(ASSETS.size()):
  var button := Button.new()
  button.text = ASSETS[i]["name"]
  button.custom_minimum_size.y = 48
  button.pressed.connect(_show_asset.bind(i))
  right.add_child(button)
 status = _text("",14)
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 right.add_child(status)
 var controls := HBoxContainer.new()
 controls.anchor_left = 0.22
 controls.anchor_right = 0.70
 controls.anchor_top = 0.88
 controls.anchor_bottom = 0.97
 add_child(controls)
 for data in [["ROTATE LEFT",-0.3,0.0],["ROTATE RIGHT",0.3,0.0],["ZOOM +",0.0,-0.65],["ZOOM -",0.0,0.65]]:
  var button := Button.new()
  button.text = str(data[0])
  button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  button.pressed.connect(_change_view.bind(float(data[1]),float(data[2])))
  controls.add_child(button)

func _text(value: String, font_size: int) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("#e0ecf6"))
 return label

func _show_asset(index: int) -> void:
 chosen = index
 for child in model_root.get_children():
  child.queue_free()
 var record: Dictionary = ASSETS[index]
 var path := ROOT + str(record["file"])
 if not ResourceLoader.exists(path):
  status.text = str(record["name"]) + "\nModel not bundled into this build."
  return
 var packed := load(path) as PackedScene
 if packed == null:
  status.text = "Could not open " + path
  return
 var instance := packed.instantiate()
 model_root.add_child(instance)
 status.text = str(record["name"]) + "\n" + str(record["info"]) + "\nDrag to rotate. Pinch or buttons to zoom."
 _reset_view()

func _reset_view() -> void:
 rotation_x = -0.22
 rotation_y = 0.45
 camera_distance = 5.0
 _update_camera()

func _change_view(turn: float, zoom: float) -> void:
 rotation_y += turn
 camera_distance = clampf(camera_distance + zoom,2.0,12.0)
 _update_camera()

func _update_camera() -> void:
 if model_root != null:
  model_root.rotation = Vector3(rotation_x,rotation_y,0)
 if camera != null:
  camera.position = Vector3(0,0,camera_distance)
  camera.look_at(Vector3.ZERO,Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_LEFT:
   pointer_down = event.pressed
  elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
   _change_view(0,-0.4)
  elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   _change_view(0,0.4)
 elif event is InputEventMouseMotion and pointer_down:
  rotation_y += event.relative.x*0.008
  rotation_x = clampf(rotation_x+event.relative.y*0.005,-1.3,1.3)
  _update_camera()
 elif event is InputEventScreenDrag:
  rotation_y += event.relative.x*0.008
  rotation_x = clampf(rotation_x+event.relative.y*0.005,-1.3,1.3)
  _update_camera()
 elif event is InputEventMagnifyGesture:
  camera_distance = clampf(camera_distance/maxf(event.factor,0.1),2.0,12.0)
  _update_camera()
