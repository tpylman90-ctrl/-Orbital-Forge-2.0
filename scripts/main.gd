extends Control

const Craft = preload("res://scripts/core/craft_document.gd")
const Parts = preload("res://scripts/core/parts_catalog.gd")
const VehicleBay = preload("res://scripts/ui/vehicle_bay.gd")
const StageSimulator = preload("res://scripts/core/stage_simulator.gd")
const LaunchPhysics = preload("res://scripts/core/launch_physics.gd")
const LaunchView = preload("res://scripts/ui/launch_view.gd")
const FlightSteeringPad = preload("res://scripts/ui/flight_steering_pad.gd")
const PartCatalogIcon = preload("res://scripts/ui/part_catalog_icon.gd")
const SolarSystemScreen = preload("res://scripts/ui/solar_system_screen.gd")
const AssetShowroom = preload("res://scripts/ui/asset_showroom.gd")
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
var touch_throttle: VSlider
var touch_throttle_label: Label
var flight_hud: Label
var launch_window: Control
var solar_window: Control
var asset_window: Control
var launch_throttle := 1.0
var craft_profile := "ROCKET"
var profile_button: Button
var pad_status: Label
var builder_mode := "BUILD"
var build_panel: VBoxContainer
var systems_panel: VBoxContainer
var systems_routes: VBoxContainer
var systems_tank_label: Label
var systems_diagnostics: Label
var pending_fuel_tank := ""
var stage_widgets: Array[Control] = []
var multi_select_button: Button
var multi_select_enabled := false
var selected_uids: Array[String] = []
var drag_group: Array[String] = []
var performance_label: Label
var editor_hint: Label
var catalog_scroll: ScrollContainer
var catalog_tabs: HBoxContainer
var catalog_grid: GridContainer
var catalog_category_group: ButtonGroup
var catalog_category := "ALL"
const CATALOG_CATEGORY_ORDER := ["ALL","CREW","TANKS","ENGINES","HULL","AERO","STRUCTURE","STAGING","SYSTEMS"]

func _ready() -> void:
 active_craft = Craft.load(SAVE)
 if active_craft.is_empty():
  active_craft = Craft.create("Starter Rocket","earth")
  selected_uid = Craft.add_part(active_craft,"command_pod",Vector3(0,1.3,0))
  Craft.save(active_craft,SAVE)
 elif not active_craft["parts"].is_empty():
  selected_uid = str(active_craft["parts"][0]["uid"])
 if selected_uid != "": selected_uids.append(selected_uid)
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
 var solar_button := Button.new()
 solar_button.text = "SOLAR SYSTEM"
 solar_button.pressed.connect(_show_solar_system)
 header.add_child(solar_button)
 var asset_button := Button.new()
 asset_button.text = "3D ASSET LAB"
 asset_button.pressed.connect(_show_asset_lab)
 header.add_child(asset_button)
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
 var mode_tabs := HBoxContainer.new()
 left.add_child(mode_tabs)
 var build_tab := Button.new()
 build_tab.text = "BUILD"
 build_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 build_tab.pressed.connect(_set_builder_mode.bind("BUILD"))
 mode_tabs.add_child(build_tab)
 var systems_tab := Button.new()
 systems_tab.text = "SYSTEMS"
 systems_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 systems_tab.pressed.connect(_set_builder_mode.bind("SYSTEMS"))
 mode_tabs.add_child(systems_tab)
 build_panel = VBoxContainer.new()
 build_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
 left.add_child(build_panel)
 var catalog_heading := HBoxContainer.new()
 build_panel.add_child(catalog_heading)
 var catalog_title := _label("PART INVENTORY",16)
 catalog_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 catalog_heading.add_child(catalog_title)
 var catalog_count := _label("%02d PARTS" % Parts.ITEMS.size(),10)
 catalog_count.add_theme_color_override("font_color",Color("#7e9aab"))
 catalog_heading.add_child(catalog_count)
 profile_button = Button.new()
 profile_button.custom_minimum_size.y = 45
 profile_button.pressed.connect(_toggle_craft_profile)
 _update_profile_button()
 build_panel.add_child(profile_button)
 var profile_hint := _label("Parts attach at the selected connector. Rotate the craft to build side-on ships; add wings from open side mounts.",12)
 profile_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 build_panel.add_child(profile_hint)
 var category_scroll := ScrollContainer.new()
 category_scroll.custom_minimum_size.y = 38
 category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 category_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 build_panel.add_child(category_scroll)
 catalog_tabs = HBoxContainer.new()
 catalog_tabs.add_theme_constant_override("separation",4)
 category_scroll.add_child(catalog_tabs)
 catalog_category_group = ButtonGroup.new()
 for category in CATALOG_CATEGORY_ORDER:
  var tab := Button.new()
  tab.text = category
  tab.toggle_mode = true
  tab.button_group = catalog_category_group
  tab.custom_minimum_size = Vector2(68,34)
  tab.add_theme_font_size_override("font_size",10)
  tab.button_pressed = category == catalog_category
  tab.pressed.connect(_select_catalog_category.bind(category))
  catalog_tabs.add_child(tab)
 catalog_scroll = ScrollContainer.new()
 catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 catalog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 build_panel.add_child(catalog_scroll)
 catalog_grid = GridContainer.new()
 catalog_grid.columns = 2
 catalog_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 catalog_grid.add_theme_constant_override("h_separation",5)
 catalog_grid.add_theme_constant_override("v_separation",5)
 catalog_scroll.add_child(catalog_grid)
 _populate_catalog_grid()
 systems_panel = VBoxContainer.new()
 systems_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
 systems_panel.visible = false
 left.add_child(systems_panel)
 systems_panel.add_child(_label("SHIP SYSTEMS",17))
 var systems_help := _label("Select parts in the craft view. Choose a tank, then select an engine and connect them. Stage breakpoints are assigned here too.",12)
 systems_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 systems_panel.add_child(systems_help)
 systems_tank_label = _label("FUEL TANK: NONE",13)
 systems_tank_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 systems_panel.add_child(systems_tank_label)
 systems_diagnostics = _label("",12)
 systems_diagnostics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 systems_panel.add_child(systems_diagnostics)
 var choose_tank := Button.new()
 choose_tank.text = "USE SELECTED AS FUEL TANK"
 choose_tank.pressed.connect(_choose_fuel_tank)
 systems_panel.add_child(choose_tank)
 var connect_fuel := Button.new()
 connect_fuel.text = "CONNECT TANK TO SELECTED ENGINE"
 connect_fuel.pressed.connect(_connect_fuel_route)
 systems_panel.add_child(connect_fuel)
 var clear_tank := Button.new()
 clear_tank.text = "CLEAR TANK SELECTION"
 clear_tank.pressed.connect(func(): pending_fuel_tank = ""; _refresh_systems())
 systems_panel.add_child(clear_tank)
 var auto_fuel := Button.new()
 auto_fuel.text = "RESET TO AUTO FUEL FLOW"
 auto_fuel.pressed.connect(_reset_fuel_routing)
 systems_panel.add_child(auto_fuel)
 systems_panel.add_child(_label("FUEL LINES",14))
 var route_scroll := ScrollContainer.new()
 route_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 systems_panel.add_child(route_scroll)
 systems_routes = VBoxContainer.new()
 route_scroll.add_child(systems_routes)
 var center := VBoxContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_stretch_ratio = 3.0
 body.add_child(center)
 bay = VehicleBay.new()
 bay.custom_minimum_size = Vector2(280,280)
 bay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 bay.size_flags_vertical = Control.SIZE_EXPAND_FILL
 bay.selected.connect(_on_part_selected)
 center.add_child(bay)
 bay.piece_dragged.connect(_on_piece_dragged)
 editor_hint = _label("1 finger on empty space: rotate / tilt. Drag a part to move it. 2 fingers: pan / pinch zoom.",13)
 editor_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 center.add_child(editor_hint)
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
 multi_select_button = Button.new()
 multi_select_button.text = "MULTI-SELECT: OFF"
 multi_select_button.toggle_mode = true
 multi_select_button.toggled.connect(_set_multi_select_enabled)
 right.add_child(multi_select_button)
 performance_label = _label("",12)
 performance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 right.add_child(performance_label)
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
 stage_widgets.append(stage_button)
 var stage_scroll := ScrollContainer.new()
 stage_scroll.custom_minimum_size.y = 120
 right.add_child(stage_scroll)
 stage_widgets.append(stage_scroll)
 stage_list = VBoxContainer.new()
 stage_scroll.add_child(stage_list)
 var test_stage := Button.new()
 test_stage.text = "TEST NEXT STAGE"
 test_stage.pressed.connect(_test_next_stage)
 right.add_child(test_stage)
 stage_widgets.append(test_stage)
 var restore := Button.new()
 restore.text = "RESTORE DESIGN"
 restore.pressed.connect(_restore_design)
 right.add_child(restore)
 stage_widgets.append(restore)
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
 duplicate.text = "DUPLICATE SELECTED"
 duplicate.pressed.connect(_duplicate)
 right.add_child(duplicate)
 var delete := Button.new()
 delete.text = "REMOVE SELECTED"
 delete.pressed.connect(_remove)
 right.add_child(delete)
 info = _label("",13)
 info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 right.add_child(info)
 _set_builder_mode("BUILD")

func _select_catalog_category(category: String) -> void:
 catalog_category = category
 _populate_catalog_grid()

func _catalog_category_for(part: Dictionary) -> String:
 var kind := str(part.get("kind","misc"))
 if kind in ["core","crew_capsule","cockpit","sphere","spire"]: return "CREW"
 if kind == "tank": return "TANKS"
 if kind in ["engine","ion","booster","booster_engine"]: return "ENGINES"
 if kind in ["nose","adapter","fuselage","cargo_pod","payload_bay","fairing","service_module","heat_shield"]: return "HULL"
 if kind in ["wing","tail_fin","landing_legs"]: return "AERO"
 if kind in ["truss","plate","crossfeed","ring"]: return "STRUCTURE"
 if kind in ["decoupler_inline","decoupler_radial","separator_tube"]: return "STAGING"
 return "SYSTEMS"

func _populate_catalog_grid() -> void:
 if catalog_grid == null: return
 for child in catalog_grid.get_children():
  catalog_grid.remove_child(child)
  child.queue_free()
 var part_ids: Array[String] = []
 for part_id in Parts.ITEMS:
  var part: Dictionary = Parts.ITEMS[part_id]
  if catalog_category == "ALL" or _catalog_category_for(part) == catalog_category:
   part_ids.append(str(part_id))
 part_ids.sort_custom(func(a: String,b: String) -> bool:
  var part_a: Dictionary = Parts.ITEMS[a]
  var part_b: Dictionary = Parts.ITEMS[b]
  if catalog_category == "ALL":
   var category_rank_a: int = CATALOG_CATEGORY_ORDER.find(_catalog_category_for(part_a))
   var category_rank_b: int = CATALOG_CATEGORY_ORDER.find(_catalog_category_for(part_b))
   if category_rank_a != category_rank_b: return category_rank_a < category_rank_b
  return str(part_a.get("name",a)).nocasecmp_to(str(part_b.get("name",b))) < 0
 )
 for part_id in part_ids:
  var part: Dictionary = Parts.ITEMS[part_id]
  var tile := Button.new()
  tile.text = ""
  tile.custom_minimum_size = Vector2(96,96)
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tile.focus_mode = Control.FOCUS_ALL
  tile.tooltip_text = "%s\n%s" % [str(part.get("name",part_id)),_catalog_category_for(part)]
  tile.set_meta("part_type",part_id)
  tile.set_meta("part_category",_catalog_category_for(part))
  _style_catalog_tile(tile)
  tile.pressed.connect(_add_part.bind(part_id))
  catalog_grid.add_child(tile)
  var content := VBoxContainer.new()
  content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  content.offset_left = 3
  content.offset_top = 3
  content.offset_right = -3
  content.offset_bottom = -3
  content.add_theme_constant_override("separation",0)
  content.mouse_filter = Control.MOUSE_FILTER_IGNORE
  tile.add_child(content)
  var icon := PartCatalogIcon.new()
  icon.custom_minimum_size = Vector2(0,60)
  icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  icon.configure(part)
  content.add_child(icon)
  var name := Label.new()
  name.text = str(part.get("name",part_id))
  name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  name.clip_text = true
  name.custom_minimum_size.y = 28
  name.add_theme_font_size_override("font_size",9)
  name.add_theme_color_override("font_color",Color("#d6e3e9"))
  name.mouse_filter = Control.MOUSE_FILTER_IGNORE
  content.add_child(name)

func _style_catalog_tile(button: Button) -> void:
 var normal := StyleBoxFlat.new()
 normal.bg_color = Color("#102131")
 normal.border_color = Color("#233d50")
 normal.set_border_width_all(1)
 normal.set_corner_radius_all(7)
 normal.set_content_margin_all(3)
 var hover := normal.duplicate() as StyleBoxFlat
 hover.bg_color = Color("#183246")
 hover.border_color = Color("#5da9bd")
 var pressed := normal.duplicate() as StyleBoxFlat
 pressed.bg_color = Color("#1d3845")
 pressed.border_color = Color("#e2b867")
 button.add_theme_stylebox_override("normal",normal)
 button.add_theme_stylebox_override("hover",hover)
 button.add_theme_stylebox_override("pressed",pressed)
 button.add_theme_stylebox_override("focus",hover)

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
 if multi_select_enabled:
  if not selected_uids.has(selected_uid): selected_uids.append(selected_uid)
 else:
  selected_uids.clear()
  selected_uids.append(selected_uid)
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

func _set_builder_mode(mode: String) -> void:
 builder_mode = "SYSTEMS" if mode == "SYSTEMS" else "BUILD"
 if builder_mode == "SYSTEMS" and multi_select_enabled:
  multi_select_button.button_pressed = false
  _set_multi_select_enabled(false)
 if build_panel != null: build_panel.visible = builder_mode == "BUILD"
 if systems_panel != null: systems_panel.visible = builder_mode == "SYSTEMS"
 if multi_select_button != null: multi_select_button.visible = builder_mode == "BUILD"
 if performance_label != null: performance_label.visible = builder_mode == "BUILD"
 for widget in stage_widgets:
  widget.visible = builder_mode == "SYSTEMS"
 if bay != null:
  bay.placement_mode = builder_mode == "BUILD"
  bay.set_systems_overlay_enabled(builder_mode == "SYSTEMS")
 if editor_hint != null:
  if builder_mode == "SYSTEMS": editor_hint.text = "Tap a tank or engine to select a systems endpoint. Tap empty space to rotate / tilt; 2 fingers to pan / zoom."
  elif multi_select_enabled: editor_hint.text = "Tap new parts to select; use the part list to remove selections. Drag a selected part to move the group."
  else: editor_hint.text = "1 finger on empty space: rotate / tilt. Drag a part to move it. 2 fingers: pan / pinch zoom."
 _refresh_systems()

func _set_multi_select_enabled(enabled: bool) -> void:
 multi_select_enabled = enabled and builder_mode == "BUILD"
 if multi_select_button != null:
  multi_select_button.text = "MULTI-SELECT: ON (%d)" % selected_uids.size() if multi_select_enabled else "MULTI-SELECT: OFF"
 if editor_hint != null and builder_mode == "BUILD":
  editor_hint.text = "Tap new parts to select; use the part list to remove selections. Drag a selected part to move the group." if multi_select_enabled else "1 finger on empty space: rotate / tilt. Drag a part to move it. 2 fingers: pan / pinch zoom."
 if not multi_select_enabled:
  selected_uids.clear()
  if selected_uid != "" and not Craft.find_part(active_craft,selected_uid).is_empty(): selected_uids.append(selected_uid)
 elif selected_uid != "" and not selected_uids.has(selected_uid):
  selected_uids.clear()
  selected_uids.append(selected_uid)
 if bay != null:
  bay.multi_select_mode = multi_select_enabled
  bay.selection_ids = _selection_ids()
 _refresh()

func _on_part_selected(uid: String) -> void:
 if multi_select_enabled and builder_mode == "BUILD":
  if selected_uids.has(uid): selected_uids.erase(uid)
  else: selected_uids.append(uid)
  if selected_uids.has(uid): selected_uid = uid
  elif not selected_uids.is_empty(): selected_uid = selected_uids.back()
  else: selected_uid = ""
  if multi_select_button != null: multi_select_button.text = "MULTI-SELECT: ON (%d)" % selected_uids.size()
 else:
  selected_uid = uid
  selected_uids.clear()
  selected_uids.append(uid)
 _refresh()

func _selection_ids() -> Array[String]:
 var ids: Array[String] = []
 if multi_select_enabled and not selected_uids.is_empty():
  for uid in selected_uids: ids.append(uid)
 elif selected_uid != "":
  ids.append(selected_uid)
 return ids

func _selected_parts() -> Array[Dictionary]:
 var ids := _selection_ids()
 var result: Array[Dictionary] = []
 for part in active_craft.get("parts",[]):
  if ids.has(str(part.get("uid",""))): result.append(part)
 return result

func _choose_fuel_tank() -> void:
 var part := _selected()
 if part.is_empty():
  info.text = "Select a fuel tank first."
  return
 var ratings: Array = LaunchPhysics.RATINGS.get(str(part.get("type","")),[0.0,0.0,0.0,0.0])
 if float(ratings[1]) <= 0.0:
  info.text = "The selected part does not hold propellant."
  return
 pending_fuel_tank = selected_uid
 _refresh_systems()
 info.text = "FUEL SOURCE SELECTED. Now choose an engine and connect it."

func _connect_fuel_route() -> void:
 var engine := _selected()
 if engine.is_empty() or pending_fuel_tank == "":
  info.text = "Select a tank, then select an engine to connect."
  return
 var ratings: Array = LaunchPhysics.RATINGS.get(str(engine.get("type","")),[0.0,0.0,0.0,0.0])
 if float(ratings[2]) <= 0.0:
  info.text = "Select an engine or thruster as the connection target."
  return
 if engine["uid"] == pending_fuel_tank:
  info.text = "A part cannot feed itself. Select an engine."
  return
 var routes: Dictionary = active_craft.get("fuel_routes",{})
 if not routes.has(selected_uid): routes[selected_uid] = []
 var tanks: Array = routes[selected_uid]
 if not tanks.has(pending_fuel_tank): tanks.append(pending_fuel_tank)
 routes[selected_uid] = tanks
 active_craft["fuel_routes"] = routes
 active_craft["fuel_routing_enabled"] = true
 _commit()
 info.text = "FUEL LINE CONNECTED. Add another tank to this engine or choose another engine."

func _remove_fuel_route(engine_uid: String, tank_uid: String) -> void:
 var routes: Dictionary = active_craft.get("fuel_routes",{})
 if not routes.has(engine_uid): return
 var tanks: Array = routes[engine_uid]
 tanks.erase(tank_uid)
 if tanks.is_empty(): routes.erase(engine_uid)
 else: routes[engine_uid] = tanks
 active_craft["fuel_routes"] = routes
 _commit()

func _move_fuel_route(engine_uid: String, tank_uid: String, direction: int) -> void:
 var routes: Dictionary = active_craft.get("fuel_routes",{})
 if not routes.has(engine_uid): return
 var tanks: Array = routes[engine_uid]
 var index := tanks.find(tank_uid)
 var target := index+direction
 if index < 0 or target < 0 or target >= tanks.size(): return
 var moved: Variant = tanks[index]
 tanks.remove_at(index)
 tanks.insert(target,moved)
 routes[engine_uid] = tanks
 active_craft["fuel_routes"] = routes
 _commit()

func _reset_fuel_routing() -> void:
 active_craft["fuel_routes"] = {}
 active_craft["fuel_routing_enabled"] = false
 _commit()
 info.text = "AUTO FUEL FLOW RESTORED."

func _refresh_systems() -> void:
 if systems_routes == null: return
 systems_tank_label.text = "FUEL TANK: %s" % _part_name(pending_fuel_tank) if pending_fuel_tank != "" else "FUEL TANK: NONE"
 for child in systems_routes.get_children(): child.queue_free()
 var routes: Dictionary = active_craft.get("fuel_routes",{})
 systems_diagnostics.text = _fuel_diagnostics(routes)
 systems_diagnostics.add_theme_color_override("font_color",Color("#79d6a5") if not systems_diagnostics.text.contains("CHECK") else Color("#f0bd69"))
 if routes.is_empty():
  var message := "No assigned fuel lines. Engines cannot access tank propellant." if bool(active_craft.get("fuel_routing_enabled",false)) else "No assigned fuel lines. Engines use automatic fuel flow."
  systems_routes.add_child(_label(message,12))
  return
 for engine_uid in routes:
  for index in range(routes[engine_uid].size()):
   var tank_uid: String = str(routes[engine_uid][index])
   var row := VBoxContainer.new()
   systems_routes.add_child(row)
   var route_label := Button.new()
   route_label.text = "%d  %s  →  %s" % [index+1,_part_name(tank_uid),_part_name(str(engine_uid))]
   route_label.pressed.connect(_select_stage_part.bind(str(engine_uid)))
   row.add_child(route_label)
   var controls := HBoxContainer.new()
   row.add_child(controls)
   var up := Button.new()
   up.text = "DRAIN FIRST ↑"
   up.disabled = index == 0
   up.pressed.connect(_move_fuel_route.bind(str(engine_uid),tank_uid,-1))
   controls.add_child(up)
   var down := Button.new()
   down.text = "DRAIN LATER ↓"
   down.disabled = index == routes[engine_uid].size()-1
   down.pressed.connect(_move_fuel_route.bind(str(engine_uid),tank_uid,1))
   controls.add_child(down)
   var remove := Button.new()
   remove.text = "X"
   remove.pressed.connect(_remove_fuel_route.bind(str(engine_uid),tank_uid))
   controls.add_child(remove)

func _fuel_diagnostics(routes: Dictionary) -> String:
 var engines: Array[String] = []
 var tanks: Array[String] = []
 for part in active_craft.get("parts",[]):
  var rating: Array = LaunchPhysics.RATINGS.get(str(part.get("type","")),[0.0,0.0,0.0,0.0])
  if float(rating[2]) > 0.0: engines.append(str(part["uid"]))
  if float(rating[1]) > 0.0: tanks.append(str(part["uid"]))
 if not bool(active_craft.get("fuel_routing_enabled",not routes.is_empty())):
  return "AUTO FLOW · %d engine(s) · %d tank(s)" % [engines.size(),tanks.size()]
 var fed: Dictionary = {}
 var used: Dictionary = {}
 for engine_uid in routes:
  var assigned: Array = routes[engine_uid]
  if not assigned.is_empty() and engines.has(str(engine_uid)): fed[str(engine_uid)] = true
  for tank_uid in assigned:
   if tanks.has(str(tank_uid)): used[str(tank_uid)] = true
 var unfed: Array[String] = []
 var unused: Array[String] = []
 for engine_uid in engines:
  if not fed.has(engine_uid): unfed.append(_part_name(engine_uid))
 for tank_uid in tanks:
  if not used.has(tank_uid): unused.append(_part_name(tank_uid))
 if unfed.is_empty() and unused.is_empty() and not engines.is_empty():
  return "ROUTING READY · %d/%d engines fed · %d/%d tanks assigned" % [fed.size(),engines.size(),used.size(),tanks.size()]
 var warnings: Array[String] = []
 if not unfed.is_empty(): warnings.append("CHECK unfed: "+_join_names(unfed))
 if not unused.is_empty(): warnings.append("CHECK unused: "+_join_names(unused))
 if engines.is_empty(): warnings.append("CHECK no engines")
 return "FUEL ROUTING · %d/%d engines fed\n%s" % [fed.size(),engines.size(),_join_names(warnings," · ")]

func _join_names(values: Array[String], separator: String = ", ") -> String:
 var output := ""
 for value in values:
  if output != "": output += separator
  output += value
 return output

func _part_name(uid: String) -> String:
 var part := Craft.find_part(active_craft,uid)
 if part.is_empty(): return "Missing part"
 return str(Parts.ITEMS.get(str(part.get("type","")),{}).get("name","Part"))

func _refresh_performance() -> void:
 if performance_label == null: return
 var analysis := LaunchPhysics.new()
 analysis.configure(active_craft,Parts.ITEMS)
 var engine_count := 0
 for engine in analysis.engine_specs:
  if bool(engine.get("enabled",false)): engine_count += 1
 if analysis.status.begins_with("NEEDS"):
  performance_label.text = "DESIGN ANALYSIS\n%s\nWet mass %.0f kg · thrust %.0f N" % [analysis.status,analysis.mass_kg(),analysis.thrust_n]
  performance_label.add_theme_color_override("font_color",Color("#efbd73"))
 else:
  performance_label.text = "DESIGN ANALYSIS\nWet %.0f kg · Dry %.0f kg · Fuel %.0f kg\nTWR %.2f · Δv %.2f km/s\n%d engine(s) connected" % [analysis.mass_kg(),analysis.dry_kg,analysis.fuel_kg,analysis.twr(),analysis.delta_v_estimate()/1000.0,engine_count]
  performance_label.add_theme_color_override("font_color",Color("#b7d9cf"))

func _selected() -> Dictionary:
 return Craft.find_part(active_craft,selected_uid)

func _turn(axis: String) -> void:
 var index := ["X","Y","Z"].find(axis)
 if index < 0: return
 var parts := _selected_parts()
 if parts.is_empty(): return
 var axis_vector: Vector3 = [Vector3.RIGHT,Vector3.UP,Vector3.BACK][index]
 var turn := Basis(axis_vector,PI/4.0)
 var center := Vector3.ZERO
 for part in parts: center += _part_position(part)
 center /= float(parts.size())
 for part in parts:
  var position := center+turn*(_part_position(part)-center)
  part["position"] = [position.x,position.y,position.z]
  var rotation: Vector3 = (turn*Basis.from_euler(_part_rotation(part))).get_euler()
  part["rotation"] = [rotation.x,rotation.y,rotation.z]
 _commit()

func _resize(delta: float) -> void:
 var parts := _selected_parts()
 if parts.is_empty(): return
 var center := Vector3.ZERO
 for part in parts: center += _part_position(part)
 center /= float(parts.size())
 var old_scale: float = float(parts[0].get("scale",1.0))
 var new_scale: float = clampf(old_scale+delta,0.5,4.0)
 var ratio := new_scale/maxf(old_scale,0.001)
 for part in parts:
  var position := center+(_part_position(part)-center)*ratio
  part["position"] = [position.x,position.y,position.z]
  part["scale"] = clampf(float(part.get("scale",1.0))*ratio,0.5,4.0)
 _commit()

func _depth_step(signum: float) -> void:
 var toward_camera := Vector3(sin(bay.yaw),0.0,cos(bay.yaw))
 _move(toward_camera*0.25*signum)

func _detach_selected() -> void:
 if selected_uid == "": return
 var ids := _selection_ids()
 active_craft["links"] = active_craft["links"].filter(func(link): return not ids.has(str(link["a"])) and not ids.has(str(link["b"])))
 _commit()

func _move(offset: Vector3) -> void:
 var parts := _selected_parts()
 if parts.is_empty(): return
 if parts.size() == 1:
  _detach_links(str(parts[0]["uid"]))
 else:
  var ids := _selection_ids()
  var selected_set := {}
  for uid in ids: selected_set[uid] = true
  var kept: Array = []
  for link in active_craft["links"]:
   var a_in: bool = selected_set.has(str(link.get("a","")))
   var b_in: bool = selected_set.has(str(link.get("b","")))
   if not (a_in != b_in): kept.append(link)
  active_craft["links"] = kept
 for part in parts: _move_single(str(part["uid"]),offset)
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
  if dragging_active and drag_group.size() > 1:
   dragging_active = false
   drag_group.clear()
   _commit()
   return
  dragging_active = false
  drag_group.clear()
  if drag_was_attached:
   drag_was_attached = false
   _commit()
  else:
   _snap(0.85)
  return
 if not dragging_active:
  dragging_active = true
  drag_was_attached = false
  drag_group.clear()
  if multi_select_enabled and selected_uids.has(uid):
   for member in selected_uids: drag_group.append(member)
  else:
   drag_group.append(uid)
  if drag_group.size() > 1:
   var group_set := {}
   for member in drag_group: group_set[member] = true
   var kept_links: Array = []
   for link in active_craft["links"]:
    var a_in: bool = group_set.has(str(link.get("a","")))
    var b_in: bool = group_set.has(str(link.get("b","")))
    if a_in != b_in: drag_was_attached = true
    else: kept_links.append(link)
   active_craft["links"] = kept_links
  else:
   for link in active_craft["links"]:
    if str(link["a"]) == uid or str(link["b"]) == uid:
     drag_was_attached = true
     break
   _detach_links(uid)
 for member in drag_group: _move_single(member,offset)
 if drag_group.size() > 1: bay.move_selection_preview(drag_group,uid,offset)

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
 var touch_controls := HBoxContainer.new()
 touch_controls.anchor_left = 0.0
 touch_controls.anchor_top = 1.0
 touch_controls.anchor_right = 1.0
 touch_controls.anchor_bottom = 1.0
 touch_controls.offset_left = 12.0
 touch_controls.offset_top = -178.0
 touch_controls.offset_right = -12.0
 touch_controls.offset_bottom = -12.0
 touch_controls.z_index = 3
 touch_controls.add_theme_constant_override("separation",12)
 launch_window.add_child(touch_controls)
 var steering_pad: OFFlightSteeringPad = FlightSteeringPad.new()
 steering_pad.steering_changed.connect(_set_touch_steering)
 touch_controls.add_child(steering_pad)
 var control_spacer := Control.new()
 control_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 touch_controls.add_child(control_spacer)
 flight_hud = _label("DRAG TO STEER  /  RELEASE TO HOLD\nALT 0 km  /  FUEL 100%",13)
 flight_hud.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
 flight_hud.add_theme_color_override("font_color",Color("#e0edf4"))
 touch_controls.add_child(flight_hud)
 var throttle_box := VBoxContainer.new()
 throttle_box.custom_minimum_size = Vector2(82,0)
 touch_controls.add_child(throttle_box)
 touch_throttle_label = _label("THROTTLE 100%",11)
 touch_throttle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 throttle_box.add_child(touch_throttle_label)
 touch_throttle = VSlider.new()
 touch_throttle.min_value = 0.0
 touch_throttle.max_value = 1.0
 touch_throttle.step = 0.01
 touch_throttle.value = launch_throttle
 touch_throttle.custom_minimum_size = Vector2(64,145)
 touch_throttle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 touch_throttle.size_flags_vertical = Control.SIZE_EXPAND_FILL
 touch_throttle.value_changed.connect(_set_touch_throttle)
 throttle_box.add_child(touch_throttle)
 launch_view.load_craft(active_craft)

func _show_asset_lab() -> void:
 if asset_window != null: return
 asset_window = AssetShowroom.new()
 asset_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 asset_window.z_index = 65
 asset_window.return_to_builder.connect(_close_asset_lab)
 add_child(asset_window)

func _close_asset_lab() -> void:
 if asset_window != null:
  asset_window.queue_free()
 asset_window = null

func _show_solar_system() -> void:
 if solar_window != null: return
 solar_window = SolarSystemScreen.new()
 solar_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 solar_window.z_index = 60
 solar_window.return_to_builder.connect(_close_solar_system)
 add_child(solar_window)

func _close_solar_system() -> void:
 if solar_window != null:
  solar_window.queue_free()
 solar_window = null

func _close_launch_pad() -> void:
 _stop_launch_test()
 if launch_window != null:
  launch_window.queue_free()
 launch_window = null
 launch_view = null
 touch_throttle = null
 touch_throttle_label = null
 flight_hud = null

func _start_launch_test() -> void:
 if launch_view == null: _show_launch_pad()
 if stage_preview_active: _restore_design()
 if flight_running: return
 flight = LaunchPhysics.new()
 flight.configure(active_craft,Parts.ITEMS)
 if flight.status.begins_with("NEEDS"):
  flight_readout.text = "Connect at least one propellant tank to an engine, and ensure the craft contains fuel and thrust."
  if pad_status != null: pad_status.text = "PREFLIGHT HOLD  /  %s" % flight.status
  return
 flight.throttle = launch_throttle
 flight_readout.text = "READY TO IGNITE  /  USE THE PAD CONTROL WHEN READY."
 if pad_status != null: pad_status.text = "VEHICLE READY  /  ENGINES STANDBY"

func _ignite_launch_engines() -> void:
 if flight == null: _start_launch_test()
 if flight == null or flight.status.begins_with("NEEDS"):
  if pad_status != null: pad_status.text = "IGNITION INHIBITED  /  %s" % (flight.status if flight != null else "ENGINE OR FUEL MISSING")
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
 if touch_throttle != null and not is_equal_approx(touch_throttle.value,value): touch_throttle.set_value_no_signal(value)
 if touch_throttle_label != null: touch_throttle_label.text = "THROTTLE %d%%" % roundi(value*100.0)
 if flight != null: flight.throttle = value

func _set_touch_throttle(value: float) -> void:
 _set_throttle(value)

func _set_touch_steering(value: float) -> void:
 if flight != null: flight.steering_input = value

func _process(delta: float) -> void:
 if not flight_running or flight == null: return
 flight.step(minf(delta,0.1))
 if launch_view != null: launch_view.show_altitude(flight.altitude,flight.throttle,flight.launched and flight.fuel_kg > 0.0,flight.downrange,flight.pitch_degrees,flight.is_in_orbit())
 if flight_hud != null:
  flight_hud.text = "ALT %.1f km  /  SPEED %.0f m/s\nFUEL %.0f%%  /  PITCH %+.0f°\n%s" % [flight.altitude/1000.0,sqrt(flight.vertical_speed*flight.vertical_speed+flight.horizontal_speed*flight.horizontal_speed),100.0*flight.fuel_kg/maxf(flight.initial_fuel_kg,1.0),flight.pitch_degrees,flight.status]
 _update_flight_readout()
 if not flight.launched:
  flight_running = false
  if pad_status != null: pad_status.text = "TEST COMPLETE  /  %s" % flight.status

func _update_flight_readout() -> void:
 if flight == null: return
 flight_readout.text = "STATUS: %s | T+%.1f s\nALT: %.1f km | VERT: %.0f m/s | EAST: %.0f m/s\nFUEL: %.1f kg | MASS: %.0f kg | PITCH: %+.0f°\nTHRUST: %.0f N | TWR: %.2f | DOWNRANGE: %.1f km\nMAX Q: %.1f kPa @ %.1f km | LOAD: %.2f g\nGRAVITY: %.3f m/s² | AIR: %.5f kg/m³" % [flight.status,flight.time_s,flight.altitude/1000.0,flight.vertical_speed,flight.horizontal_speed,flight.fuel_kg,flight.mass_kg(),flight.pitch_degrees,flight.actual_thrust_n,flight.twr(),flight.downrange/1000.0,flight.max_q_pa/1000.0,flight.max_q_altitude_m/1000.0,flight.g_load,flight.gravity(),flight.density()]

func _duplicate() -> void:
 var sources := _selected_parts()
 if sources.is_empty(): return
 var original_links: Array = active_craft.get("links",[]).duplicate(true)
 var copies: Dictionary = {}
 for part in sources:
  var rotation := _part_rotation(part)
  var copy_id: String = Craft.add_part(active_craft,str(part["type"]),_part_position(part)+Vector3(0.8,0,0),rotation,float(part["scale"]))
  copies[str(part["uid"])] = copy_id
 var selected_ids := _selection_ids()
 for link in original_links:
  var a := str(link.get("a",""))
  var b := str(link.get("b",""))
  if copies.has(a) and copies.has(b) and Craft.link_parts(active_craft,copies[a],copies[b]):
   var copied_link: Dictionary = active_craft["links"].back()
   for port_key in ["a_port","b_port","kind"]:
    if link.has(port_key): copied_link[port_key] = link[port_key]
 selected_uids.clear()
 for old_uid in selected_ids:
  selected_uids.append(str(copies[old_uid]))
 selected_uid = selected_uids.back() if not selected_uids.is_empty() else ""
 _commit()

func _remove() -> void:
 if selected_uid == "": return
 var remove_ids := _selection_ids()
 for uid in remove_ids:
  Craft.remove_part(active_craft,uid)
  if pending_fuel_tank == uid: pending_fuel_tank = ""
 selected_uid = str(active_craft["parts"][0]["uid"]) if not active_craft["parts"].is_empty() else ""
 selected_uids.clear()
 if selected_uid != "": selected_uids.append(selected_uid)
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
  bay.placement_mode = builder_mode == "BUILD"
  bay.multi_select_mode = multi_select_enabled
  bay.selection_ids = _selection_ids()
  bay.set_systems_overlay_enabled(builder_mode == "SYSTEMS")
  bay.set_craft(active_craft)
 if selected_label != null:
  var part := _selected()
  selected_label.text = "SELECTED: NONE" if part.is_empty() else "%s  /  %.2fx" % [str(Parts.ITEMS.get(str(part["type"]),{}).get("name","Part")),float(part["scale"])]
  if multi_select_enabled: selected_label.text = "%d PARTS SELECTED" % selected_uids.size()
 if multi_select_button != null and multi_select_enabled:
  multi_select_button.text = "MULTI-SELECT: ON (%d)" % selected_uids.size()
 if part_list != null:
  for child in part_list.get_children(): child.queue_free()
  for part in active_craft["parts"]:
   var button := Button.new()
   var uid := str(part["uid"])
   var marker := ("[x] " if _selection_ids().has(uid) else "[ ] ") if multi_select_enabled else ("> " if uid == selected_uid else "  ")
   button.text = marker + str(Parts.ITEMS.get(str(part["type"]),{}).get("name","Part"))
   button.pressed.connect(_on_part_selected.bind(str(part["uid"])))
   part_list.add_child(button)
 _refresh_stages()
 _refresh_systems()
 _refresh_performance()
 if info != null:
  info.text = "%d PARTS  /  %d STRUCTURAL LINKS  /  %d FUEL LINES  /  %d BREAKPOINTS" % [active_craft["parts"].size(),active_craft["links"].size(),_fuel_route_count(),active_craft.get("stages",[]).size()]

func _fuel_route_count() -> int:
 var count := 0
 for engine_uid in active_craft.get("fuel_routes",{}): count += active_craft["fuel_routes"][engine_uid].size()
 return count
