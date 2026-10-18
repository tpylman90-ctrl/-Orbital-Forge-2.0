extends Control

const Craft = preload("res://scripts/core/craft_document.gd")
const Parts = preload("res://scripts/core/parts_catalog.gd")
const VehicleBay = preload("res://scripts/ui/vehicle_bay.gd")
const SAVE := "user://earth_craft_v2.json"

var active_craft: Dictionary = {}
var selected_uid := ""
var bay: OFVehicleBay
var info: Label
var selected_label: Label
var part_list: VBoxContainer
var drag_mode_button: Button
var dragging_active := false

func _ready() -> void:
 active_craft = Craft.load(SAVE)
 if active_craft.is_empty():
  active_craft = Craft.create("Starter Rocket","earth")
  selected_uid = Craft.add_part(active_craft,"command_pod",Vector3(0,1.3,0))
  Craft.save(active_craft,SAVE)
 elif not active_craft["parts"].is_empty():
  selected_uid = str(active_craft["parts"][0]["uid"])
 _build_ui()
 _refresh()

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
 var catalog_scroll := ScrollContainer.new()
 catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 left.add_child(catalog_scroll)
 var catalog := VBoxContainer.new()
 catalog.add_theme_constant_override("separation",5)
 catalog_scroll.add_child(catalog)
 for part_id in Parts.ITEMS:
  var part: Dictionary = Parts.ITEMS[part_id]
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
 drag_mode_button = Button.new()
 drag_mode_button.text = "MODE: ORBIT CAMERA — TAP TO MOVE PARTS"
 drag_mode_button.custom_minimum_size.y = 44
 drag_mode_button.pressed.connect(func():
  bay.set_placement_mode(not bay.placement_mode)
  drag_mode_button.text = "MODE: MOVE PARTS — DRAG TO PLACE" if bay.placement_mode else "MODE: ORBIT CAMERA — TAP TO MOVE PARTS"
 )
 center.add_child(drag_mode_button)
 center.add_child(_label("MOVE PARTS: drag left/right/up/down; depth stays fixed. Use Z +/- for depth.",13))
 var right := VBoxContainer.new()
 right.custom_minimum_size.x = 235
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(right)
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
 var move_tools := HFlowContainer.new()
 right.add_child(move_tools)
 for item in [["X-",Vector3(-0.5,0,0)],["X+",Vector3(0.5,0,0)],["Y-",Vector3(0,-0.5,0)],["Y+",Vector3(0,0.5,0)],["Z-",Vector3(0,0,-0.5)],["Z+",Vector3(0,0,0.5)]]:
  var move := Button.new()
  move.text = str(item[0])
  move.pressed.connect(_move.bind(item[1]))
  move_tools.add_child(move)
 var snap := Button.new()
 snap.text = "SNAP TO NEAREST"
 snap.pressed.connect(_snap)
 right.add_child(snap)
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
 var i: int = active_craft["parts"].size()
 selected_uid = Craft.add_part(active_craft,id,Vector3(0.0,1.2+float(i)*1.0,0.0))
 _commit()

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

func _move(offset: Vector3) -> void:
 var part := _selected()
 if part.is_empty(): return
 var p: Array = part["position"]
 Craft.move_group(active_craft,selected_uid,offset)
 _commit()

func _on_piece_dragged(uid: String, offset: Vector3, finished: bool) -> void:
 if finished:
  _commit()
  return
 Craft.move_group(active_craft,uid,offset)
 # Refresh only once upon release to avoid interrupting touchscreen dragging.
 for member in Craft.connected_group(active_craft,uid):
  if str(member) != uid and bay.nodes.has(str(member)):
   bay.nodes[str(member)].position += offset

func _snap() -> void:
 var part: Dictionary = _selected()
 if part.is_empty(): return
 var pos: Array = part["position"]
 var here := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
 var chosen := {}
 var proposed := here
 var best := INF
 var dims: Dictionary = Parts.ITEMS.get(str(part["type"]),{})
 var radius: float = float(dims.get("radius",0.5))*float(part["scale"])
 var height: float = float(dims.get("length",1.0))*float(part["scale"])
 for candidate in active_craft["parts"]:
  if str(candidate["uid"]) == selected_uid: continue
  if Craft.connected_group(active_craft,selected_uid).has(str(candidate["uid"])): continue
  var arr: Array = candidate["position"]
  var there := Vector3(float(arr[0]),float(arr[1]),float(arr[2]))
  var target_dims: Dictionary = Parts.ITEMS.get(str(candidate["type"]),{})
  var other_radius: float = float(target_dims.get("radius",0.5))*float(candidate["scale"])
  var other_height: float = float(target_dims.get("length",1.0))*float(candidate["scale"])
  var y_clearance: float = (height+other_height)*0.5
  var side_clearance: float = radius+other_radius
  for placement in [Vector3(0,y_clearance,0),Vector3(0,-y_clearance,0),Vector3(side_clearance,0,0),Vector3(-side_clearance,0,0),Vector3(0,0,side_clearance),Vector3(0,0,-side_clearance)]:
   var suggestion: Vector3 = there+placement
   var error: float = here.distance_to(suggestion)
   if error < best:
    best = error
    proposed = suggestion
    chosen = candidate
 if chosen.is_empty(): return
 Craft.move_group(active_craft,selected_uid,proposed-here)
 Craft.link_parts(active_craft,str(chosen["uid"]),selected_uid)
 _commit()

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
 if info != null:
  info.text = "%d PARTS  /  %d CONNECTIONS\nEarth spacecraft editor. Flight simulator and physics coming next." % [active_craft["parts"].size(),active_craft["links"].size()]
