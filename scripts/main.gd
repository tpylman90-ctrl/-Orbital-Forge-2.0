extends Control

const Craft = preload("res://scripts/core/craft_document.gd")
const Parts = preload("res://scripts/core/parts_catalog.gd")
const VehicleBay = preload("res://scripts/ui/vehicle_bay.gd")
const StageSimulator = preload("res://scripts/core/stage_simulator.gd")
const LaunchPhysics = preload("res://scripts/core/launch_physics.gd")
const LaunchView = preload("res://scripts/ui/launch_view.gd")
const SAVE := "user://earth_craft_v2.json"

var active_craft: Dictionary = {}
var selected_uid := ""
var bay: OFVehicleBay
var info: Label
var selected_label: Label
var part_list: VBoxContainer
var drag_mode_button: Button
var depth_mode_button: Button
var dragging_active := false
var drag_was_attached := false
var stage_preview_active := false
var stage_test_index := 0
var stage_preview_doc: Dictionary = {}
var stage_list: VBoxContainer
var flight: OFLaunchPhysics
var launch_panel: VBoxContainer
var flight_readout: Label
var flight_running := false
var launch_view: OFLaunchView
var launch_window: Control
var launch_throttle := 1.0
var craft_profile := "ROCKET"
var profile_button: Button
var pad_status: Label

func _ready() -> void:
 active_craft = Craft.load(SAVE)
 if active_craft.is_empty():
  active_craft = Craft.create("Starter Rocket","earth")
  selected_uid = Craft.add_part(active_craft,"command_pod",Vector3(0,1.3,0))
  Craft.save(active_craft,SAVE)
 elif not active_craft["parts"].is_empty():
  selected_uid = str(active_craft["parts"][0]["uid"])
 craft_profile = str(active_craft.get("profile","ROCKET"))
 _build_ui()
 _refresh()
 set_process(true)

func _build_ui() -> void:
 var bg := ColorRect.new()
 bg.color = Color("#081520")
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(bg)
 var column := VBoxContainer.new()
 column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 column.add_theme_constant_override("separation",4)
 add_child(column)
 var header := HBoxContainer.new()
 header.custom_minimum_size.y = 52
 column.add_child(header)
 var title := Label.new()
 title.text = "  ORBITAL FORGE 2.0  /  EARTH VEHICLE BAY"
 title.add_theme_font_size_override("font_size",22)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(title)
 var save := Button.new()
 save.text = "SAVE DESIGN"
 save.pressed.connect(_save)
 header.add_child(save)
 var body := HBoxContainer.new()
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(body)
 var left := VBoxContainer.new()
 left.custom_minimum_size.x = 210
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(left)
 left.add_child(_label("PART CATALOG",17))
 profile_button = Button.new()
 profile_button.custom_minimum_size.y = 45
 profile_button.pressed.connect(_toggle_craft_profile)
 _update_profile_button()
 left.add_child(profile_button)
 var profile_hint := _label("Parts attach at the selected connector. Rotate the craft to build side-on ships; add wings from open side mounts.",12)
 profile_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 left.add_child(profile_hint)
 var catalog_scroll := ScrollContainer.new()
 catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 left.add_child(catalog_scroll)
 var catalog := VBoxContainer.new()
 catalog.add_theme_constant_override("separation",5)
 catalog_scroll.add_child(catalog)
 var last_category := ""
 for part_id in Parts.ITEMS:
  var part: Dictionary = Parts.ITEMS[part_id]
  var category: String = str(part.get("kind","misc")).replace("_"," ").to_upper()
  if category != last_category:
   catalog.add_child(_label(category,13))
   last_category = category
  var button := Button.new()
  button.text = "+ " + str(part["name"])
  button.custom_minimum_size.y = 45
  button.pressed.connect(_add_part.bind(str(part_id)))
  catalog.add_child(button)
 var center := VBoxContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_stretch_ratio = 3.0
 body.add_child(center)
 bay = VehicleBay.new()
 bay.custom_minimum_size = Vector2(280,280)
 bay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 bay.size_flags_vertical = Control.SIZE_EXPAND_FILL
 bay.selected.connect(func(uid: String):
  selected_uid = uid
  _refresh()
 )
 center.add_child(bay)
 bay.piece_dragged.connect(_on_piece_dragged)
 center.add_child(_label("1 finger on empty space: rotate / tilt. 2 fingers: pan / pinch zoom.",13))
 var reset_view := Button.new()
 reset_view.text = "RESET CAMERA"
 reset_view.pressed.connect(func(): bay.reset_camera())
 center.add_child(reset_view)
 var right_scroll := ScrollContainer.new()
 right_scroll.custom_minimum_size.x = 265
 right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body.add_child(right_scroll)
 var right := VBoxContainer.new()
 right.custom_minimum_size.x = 245
 right_scroll.add_child(right)
 right.add_child(_label("CRAFT TOOLS",17))
 selected_label = _label("",15)
 right.add_child(selected_label)
 var part_scroll := ScrollContainer.new()
 part_scroll.custom_minimum_size.y = 112
 right.add_child(part_scroll)
 part_list = VBoxContainer.new()
 part_scroll.add_child(part_list)
 var edit_tools := HFlowContainer.new()
 right.add_child(edit_tools)
 for axis in ["X","Y","Z"]:
  var turn := Button.new()
  turn.text = "ROT " + axis
  turn.pressed.connect(_turn.bind(axis))
  edit_tools.add_child(turn)
 for scale_delta in [-0.25,0.25]:
  var resize := Button.new()
  resize.text = "SIZE -" if scale_delta < 0 else "SIZE +"
  resize.pressed.connect(_resize.bind(scale_delta))
  edit_tools.add_child(resize)
 var depth_tools := HBoxContainer.new()
 right.add_child(depth_tools)
 for item in [["CLOSER",1.0],["FARTHER",-1.0]]:
  var shift := Button.new()
  shift.text = str(item[0])
  shift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  shift.pressed.connect(_depth_step.bind(float(item[1])))
  depth_tools.add_child(shift)
 var snap := Button.new()
 snap.text = "SNAP TO NEAREST"
 snap.pressed.connect(func(): _snap())
 right.add_child(snap)
 var detach := Button.new()
 detach.text = "DETACH SELECTED"
 detach.pressed.connect(_detach_selected)
 right.add_child(detach)
 var stage_button := Button.new()
 stage_button.text = "ADD TO STAGING"
 stage_button.pressed.connect(_stage_selected)
 right.add_child(stage_button)
 var stage_scroll := ScrollContainer.new()
 stage_scroll.custom_minimum_size.y = 120
 right.add_child(stage_scroll)
 stage_list = VBoxContainer.new()
 stage_scroll.add_child(stage_list)
 var test_stage := Button.new()
 test_stage.text = "TEST NEXT STAGE"
 test_stage.pressed.connect(_test_next_stage)
 right.add_child(test_stage)
 var restore := Button.new()
 restore.text = "RESTORE DESIGN"
 restore.pressed.connect(_restore_design)
 right.add_child(restore)
 right.add_child(_label("EARTH FLIGHT TEST",15))
 launch_panel = VBoxContainer.new()
 right.add_child(launch_panel)
 var launch_controls := HBoxContainer.new()
 launch_panel.add_child(launch_controls)
 var simulate := Button.new()
 simulate.text = "LAUNCH TEST"
 simulate.pressed.connect(_start_launch_test)
 launch_controls.add_child(simulate)
 var stop := Button.new()
 stop.text = "STOP TEST"
 stop.pressed.connect(_stop_launch_test)
 launch_controls.add_child(stop)
 var throttle_row := HBoxContainer.new()
 launch_panel.add_child(throttle_row)
 throttle_row.add_child(_label("THROTTLE",12))
 var throttle_slider := HSlider.new()
 throttle_slider.min_value = 0.0
 throttle_slider.max_value = 1.0
 throttle_slider.step = 0.05
 throttle_slider.value = 1.0
 throttle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 throttle_slider.value_changed.connect(_set_throttle)
 throttle_row.add_child(throttle_slider)
 flight_readout = _label("Mass / TWR / altitude available during launch test.",12)
 flight_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 launch_panel.add_child(flight_readout)
 var view_button := Button.new()
 view_button.text = "VIEW LAUNCH PAD"
 view_button.pressed.connect(_show_launch_pad)
 launch_panel.add_child(view_button)
 var duplicate := Button.new()
 duplicate.text = "DUPLICATE PART"
 duplicate.pressed.connect(_duplicate)
 right.add_child(duplicate)
 var delete := Button.new()
 delete.text = "REMOVE SELECTED"
 delete.pressed.connect(_remove)
 right.add_child(delete)
 info = _label("",13)
 info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 right.add_child(info)

func _label(value: String, font_size: int) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("#d0e5f3"))
 return label

func _add_part(id: String) -> void:
 var target: Dictionary = _selected()
 var target_uid := selected_uid
 var spec: Dictionary = Parts.ITEMS.get(id,{})
 var target_port := "top"
 var source_port := "bottom"
 var orientation := Vector3.ZERO
 var position := Vector3(0.0,1.2+float(active_craft["parts"].size())*1.0,0.0)
 if not target.is_empty():
  orientation = _part_rotation(target)
  var target_spec: Dictionary = Parts.ITEMS.get(str(target.get("type","")),{})
  var target_ports: Dictionary = Parts.ports(target_spec)
  var own_ports: Dictionary = Parts.ports(spec)
  if str(spec.get("kind","")) == "wing" and craft_profile == "SPACECRAFT":
   target_port = _free_side_port(target_uid,target_ports)
   source_port = "left" if target_port == "right" else "right"
   if target_port == "left": orientation.y = PI
  elif str(spec.get("kind","")) in ["engine","ion","booster_engine"] and target_ports.has("bottom") and own_ports.has("top"):
   target_port = "bottom"
   source_port = "top"
  if target_ports.has(target_port) and own_ports.has(source_port):
   var target_basis := Basis.from_euler(_part_rotation(target))
   var source_basis := Basis.from_euler(orientation)
   position = _part_position(target) + target_basis * (target_ports[target_port] * float(target.get("scale",1.0))) - source_basis * (own_ports[source_port] * 1.0)
 selected_uid = Craft.add_part(active_craft,id,position,orientation)
 if target_uid != "" and not target.is_empty() and Craft.link_parts(active_craft,target_uid,selected_uid):
  var link: Dictionary = active_craft["links"].back()
  link["a_port"] = target_port
  link["b_port"] = source_port
 _commit()

func _free_side_port(uid: String, ports: Dictionary) -> String:
 for key in ["right","left"]:
  var occupied := false
  for link in active_craft.get("links",[]):
   if str(link.get("a","")) == uid and str(link.get("a_port","")) == key: occupied = true
   if str(link.get("b","")) == uid and str(link.get("b_port","")) == key: occupied = true
  if ports.has(key) and not occupied: return key
 return "right"

func _toggle_craft_profile() -> void:
 var root: Dictionary = Craft.find_part(active_craft,selected_uid)
 if not root.is_empty():
  var pivot := _part_position(root)
  var turn := PI*0.5 if craft_profile == "ROCKET" else -PI*0.5
  for part in active_craft.get("parts",[]):
   var offset := _part_position(part)-pivot
   var moved := Basis(Vector3.BACK,turn)*offset
   part["position"] = [pivot.x+moved.x,pivot.y+moved.y,pivot.z+moved.z]
   var rotation: Array = part["rotation"]
   rotation[2] = float(rotation[2])+turn
  craft_profile = "SPACECRAFT" if craft_profile == "ROCKET" else "ROCKET"
  active_craft["profile"] = craft_profile
  _commit()
 _update_profile_button()

func _update_profile_button() -> void:
 if profile_button != null:
  profile_button.text = "PROFILE: %s  /  ROTATE AXIS" % craft_profile

func _selected() -> Dictionary:
 return Craft.find_part(active_craft,selected_uid)

func _turn(axis: String) -> void:
 var part := _selected()
 if part.is_empty(): return
 var a: Array = part["rotation"]
 var index := ["X","Y","Z"].find(axis)
 if index < 0: return
 a[index] = float(a[index])+PI/4.0
 _commit()

func _resize(delta: float) -> void:
 var part := _selected()
 if part.is_empty(): return
 part["scale"] = clampf(float(part["scale"])+delta,0.5,4.0)
 _commit()

func _depth_step(signum: float) -> void:
 var toward_camera := Vector3(sin(bay.yaw),0.0,cos(bay.yaw))
 _move(toward_camera*0.25*signum)

func _detach_selected() -> void:
 if selected_uid == "": return
 active_craft["links"] = active_craft["links"].filter(func(link): return str(link["a"]) != selected_uid and str(link["b"]) != selected_uid)
 _commit()

func _move(offset: Vector3) -> void:
 var part := _selected()
 if part.is_empty(): return
 _detach_links(selected_uid)
 _move_single(selected_uid,offset)
 _commit()

func _detach_links(uid: String) -> void:
 active_craft["links"] = active_craft["links"].filter(func(link): return str(link["a"]) != uid and str(link["b"]) != uid)

func _move_single(uid: String, offset: Vector3) -> void:
 var part: Dictionary = Craft.find_part(active_craft,uid)
 if part.is_empty(): return
 var p: Array = part["position"]
 part["position"] = [float(p[0])+offset.x,float(p[1])+offset.y,float(p[2])+offset.z]

func _on_piece_dragged(uid: String, offset: Vector3, finished: bool) -> void:
 if finished:
  selected_uid = uid
  dragging_active = false
  if drag_was_attached:
   drag_was_attached = false
   _commit()
  else:
   _snap(0.85)
  return
 if not dragging_active:
  dragging_active = true
  drag_was_attached = false
  for link in active_craft["links"]:
   if str(link["a"]) == uid or str(link["b"]) == uid:
    drag_was_attached = true
    break
  _detach_links(uid)
 _move_single(uid,offset)

func _snap(max_error: float = INF) -> void:
 var part: Dictionary = _selected()
 if part.is_empty(): return
 var own_def: Dictionary = Parts.ITEMS.get(str(part["type"]),{})
 var own_ports: Dictionary = Parts.ports(own_def)
 var own_pos: Vector3 = _part_position(part)
 var own_basis := Basis.from_euler(_part_rotation(part))
 var own_scale: float = float(part["scale"])
 var best := INF
 var target_id := ""
 var target_port := ""
 var source_port := ""
 var proposed := own_pos
 var opposites := {"top":"bottom","bottom":"top","left":"right","right":"left","front":"back","back":"front","inner":"outer","outer":"inner"}
 for candidate in active_craft["parts"]:
  if str(candidate["uid"]) == selected_uid: continue
  if Craft.connected_group(active_craft,selected_uid).has(str(candidate["uid"])): continue
  var target_def: Dictionary = Parts.ITEMS.get(str(candidate["type"]),{})
  var ports: Dictionary = Parts.ports(target_def)
  var target_basis := Basis.from_euler(_part_rotation(candidate))
  var target_scale: float = float(candidate["scale"])
  for own_key in own_ports:
   var match_key: String = str(opposites.get(str(own_key),""))
   if not ports.has(match_key): continue
   var own_offset: Vector3 = own_basis * (own_ports[own_key] * own_scale)
   var target_position: Vector3 = _part_position(candidate) + target_basis * (ports[match_key] * target_scale)
   var snapped_center: Vector3 = target_position - own_offset
   var error: float = own_pos.distance_to(snapped_center)
   if error < best:
    best = error
    target_id = str(candidate["uid"])
    target_port = match_key
    source_port = str(own_key)
    proposed = snapped_center
 if target_id == "" or best > max_error:
  _commit()
  return
 _move_single(selected_uid,proposed-own_pos)
 if Craft.link_parts(active_craft,target_id,selected_uid):
  var link: Dictionary = active_craft["links"].back()
  link["a_port"] = target_port
  link["b_port"] = source_port
  link["kind"] = "structural"
 _commit()

func _part_position(part: Dictionary) -> Vector3:
 var p: Array = part["position"]
 return Vector3(float(p[0]),float(p[1]),float(p[2]))

func _part_rotation(part: Dictionary) -> Vector3:
 var r: Array = part["rotation"]
 return Vector3(float(r[0]),float(r[1]),float(r[2]))

func _move_stage(index: int, direction: int) -> void:
 var stages: Array = active_craft.get("stages",[])
 var target: int = index+direction
 if target < 0 or target >= stages.size(): return
 var entry: Variant = stages[index]
 stages[index] = stages[target]
 stages[target] = entry
 _commit()

func _remove_stage(index: int) -> void:
 var stages: Array = active_craft.get("stages",[])
 if index < 0 or index >= stages.size(): return
 stages.remove_at(index)
 _commit()

func _refresh_stages() -> void:
 if stage_list == null: return
 for child in stage_list.get_children(): child.queue_free()
 var stages: Array = active_craft.get("stages",[])
 for i in range(stages.size()):
  var stage: Dictionary = stages[i]
  var part: Dictionary = Craft.find_part(active_craft,str(stage.get("part","")))
  var name: String = str(Parts.ITEMS.get(str(part.get("type","")),{}).get("name","Missing part"))
  var line := HBoxContainer.new()
  stage_list.add_child(line)
  var pick := Button.new()
  pick.text = "%d. %s" % [i+1,name]
  pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  pick.pressed.connect(_select_stage_part.bind(str(stage.get("part",""))))
  line.add_child(pick)
  var up := Button.new()
  up.text = "^"
  up.pressed.connect(_move_stage.bind(i,-1))
  line.add_child(up)
  var down := Button.new()
  down.text = "v"
  down.pressed.connect(_move_stage.bind(i,1))
  line.add_child(down)
  var remove := Button.new()
  remove.text = "X"
  remove.pressed.connect(_remove_stage.bind(i))
  line.add_child(remove)

func _select_stage_part(uid: String) -> void:
 selected_uid = uid
 if stage_preview_active: _restore_design()
 else: _refresh()

func _stage_selected() -> void:
 var part: Dictionary = _selected()
 if part.is_empty(): return
 var definition: Dictionary = Parts.ITEMS.get(str(part["type"]),{})
 var action: String = str(definition.get("action","none"))
 if action == "none":
  info.text = "Select a decoupler, separator tube or payload module."
  return
 var stages: Array = active_craft.get("stages",[])
 var stage := {"part":selected_uid,"action":action,"armed":true}
 var exists := false
 for existing in stages:
  if str(existing.get("part","")) == selected_uid:
   existing["action"] = action
   exists = true
   break
 if not exists: stages.append(stage)
 active_craft["stages"] = stages
 _commit()
 info.text = "STAGE ARMED: %s / %d actions" % [action,stages.size()]

func _test_next_stage() -> void:
 var stages: Array = active_craft.get("stages",[])
 if stages.is_empty():
  info.text = "Add a decoupler or payload module to staging first."
  return
 if stage_test_index >= stages.size():
  info.text = "Sequence complete. Restore design to test again."
  return
 var starting: Dictionary = stage_preview_doc if stage_preview_active else active_craft
 var result: Dictionary = StageSimulator.preview(starting,stage_test_index)
 if bool(result.get("ok",false)):
  stage_preview_active = true
  bay.placement_mode = false
  bay.selected_id = ""
  bay.show_stage_preview(starting,result["craft"],str(result.get("action","")),str(result.get("actor","")))
  stage_preview_doc = result["craft"]
  stage_test_index += 1
 info.text = str(result.get("message","Stage test unavailable."))

func _restore_design() -> void:
 stage_preview_active = false
 stage_test_index = 0
 stage_preview_doc = {}
 bay.placement_mode = true
 _refresh()
 info.text = "Original saved design restored. Ready to edit."

func _show_launch_pad() -> void:
 if launch_window != null: return
 launch_window = Control.new()
 launch_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 launch_window.mouse_filter = Control.MOUSE_FILTER_STOP
 launch_window.z_index = 50
 add_child(launch_window)
 var backdrop := ColorRect.new()
 backdrop.color = Color("#0c1723")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.z_index = 0
 launch_window.add_child(backdrop)
 launch_view = LaunchView.new()
 launch_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 launch_view.z_index = 1
 launch_window.add_child(launch_view)
 var overlay := VBoxContainer.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 overlay.z_index = 2
 launch_window.add_child(overlay)
 var return_button := Button.new()
 return_button.text = "RETURN TO BUILDER"
 return_button.pressed.connect(_close_launch_pad)
 overlay.add_child(return_button)
 var fire_button := Button.new()
 fire_button.text = "IGNITE ENGINES"
 fire_button.pressed.connect(_ignite_launch_engines)
 overlay.add_child(fire_button)
 pad_status = _label("VEHICLE ON PAD  /  ENGINES STANDBY",16)
 pad_status.add_theme_color_override("font_color",Color("#f1d08a"))
 overlay.add_child(pad_status)
 var label := Label.new()
 label.text = "EARTH LAUNCH COMPLEX / VERTICAL TEST"
 overlay.add_child(label)
 launch_view.load_craft(active_craft)

func _close_launch_pad() -> void:
 _stop_launch_test()
 if launch_window != null:
  launch_window.queue_free()
 launch_window = null
 launch_view = null

func _start_launch_test() -> void:
 if launch_view == null: _show_launch_pad()
 if stage_preview_active: _restore_design()
 if flight_running: return
 flight = LaunchPhysics.new()
 flight.configure(active_craft,Parts.ITEMS)
 if flight.status == "NEEDS ENGINE AND FUEL":
  flight_readout.text = "Add at least one engine and one fuel tank to test."
  if pad_status != null: pad_status.text = "PREFLIGHT HOLD  /  ADD ENGINE AND FUEL"
  return
 flight.throttle = launch_throttle
 flight_readout.text = "READY TO IGNITE  /  USE THE PAD CONTROL WHEN READY."
 if pad_status != null: pad_status.text = "VEHICLE READY  /  ENGINES STANDBY"

func _ignite_launch_engines() -> void:
 if flight == null: _start_launch_test()
 if flight == null or flight.status == "NEEDS ENGINE AND FUEL":
  if pad_status != null: pad_status.text = "IGNITION INHIBITED  /  ENGINE OR FUEL MISSING"
  return
 if flight.launched:
  if pad_status != null: pad_status.text = "ENGINES ALREADY RUNNING"
  return
 flight.throttle = launch_throttle
 flight.ignite()
 flight_running = flight.launched
 if pad_status != null: pad_status.text = "ENGINES IGNITED  /  LIFTOFF SEQUENCE ACTIVE"
 _update_flight_readout()

func _stop_launch_test() -> void:
 flight_running = false
 flight = null
 if launch_view != null: launch_view.show_altitude(0.0,launch_throttle,false)
 if flight_readout != null: flight_readout.text = "Flight test stopped. Design preserved."
 if pad_status != null: pad_status.text = "TEST STOPPED  /  VEHICLE SAFE"

func _set_throttle(value: float) -> void:
 launch_throttle = value
 if flight != null: flight.throttle = value

func _process(delta: float) -> void:
 if not flight_running or flight == null: return
 flight.step(minf(delta,0.1))
 if launch_view != null: launch_view.show_altitude(flight.altitude,flight.throttle,flight.launched and flight.fuel_kg > 0.0)
 _update_flight_readout()
 if not flight.launched:
  flight_running = false
  if pad_status != null: pad_status.text = "TEST COMPLETE  /  %s" % flight.status

func _update_flight_readout() -> void:
 if flight == null: return
 flight_readout.text = "STATUS: %s | T+%.1f s\nALT: %.1f m | VERTICAL: %.1f m/s\nMASS: %.0f kg | FUEL: %.0f kg\nTHRUST: %.0f N | TWR: %.2f\nGRAVITY: %.3f m/s2 | AIR: %.4f kg/m3" % [flight.status,flight.time_s,flight.altitude,flight.vertical_speed,flight.mass_kg(),flight.fuel_kg,flight.thrust_n*flight.throttle,flight.twr(),flight.gravity(),flight.density()]

func _duplicate() -> void:
 var part := _selected()
 if part.is_empty(): return
 var current: Array = part["position"]
 var copy_id: String = Craft.add_part(active_craft,str(part["type"]),Vector3(float(current[0])+0.8,float(current[1]),float(current[2])),Vector3(float(part["rotation"][0]),float(part["rotation"][1]),float(part["rotation"][2])),float(part["scale"]))
 selected_uid = copy_id
 _commit()

func _remove() -> void:
 if selected_uid == "": return
 Craft.remove_part(active_craft,selected_uid)
 selected_uid = str(active_craft["parts"][0]["uid"]) if not active_craft["parts"].is_empty() else ""
 _commit()

func _save() -> void:
 if Craft.save(active_craft,SAVE):
  info.text = "DESIGN SAVED  /  %d PARTS" % active_craft["parts"].size()

func _commit() -> void:
 stage_preview_active = false
 stage_test_index = 0
 stage_preview_doc = {}
 if bay != null: bay.placement_mode = true
 Craft.save(active_craft,SAVE)
 _refresh()

func _refresh() -> void:
 if bay != null:
  bay.selected_id = selected_uid
  bay.set_craft(active_craft)
 if selected_label != null:
  var part := _selected()
  selected_label.text = "SELECTED: NONE" if part.is_empty() else "%s  /  %.2fx" % [str(Parts.ITEMS.get(str(part["type"]),{}).get("name","Part")),float(part["scale"])]
 if part_list != null:
  for child in part_list.get_children(): child.queue_free()
  for part in active_craft["parts"]:
   var button := Button.new()
   button.text = ("> " if str(part["uid"]) == selected_uid else "  ") + str(Parts.ITEMS.get(str(part["type"]),{}).get("name","Part"))
   button.pressed.connect(func():
    selected_uid = str(part["uid"])
    _refresh()
   )
   part_list.add_child(button)
 _refresh_stages()
 if info != null:
  info.text = "%d PARTS  /  %d CONNECTIONS  /  %d STAGES\nUse separation modules to plan stage events; flight physics coming later." % [active_craft["parts"].size(),active_craft["links"].size(),active_craft.get("stages",[]).size()]
