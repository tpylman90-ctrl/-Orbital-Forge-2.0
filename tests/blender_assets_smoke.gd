extends SceneTree

const Parts = preload("res://scripts/core/parts_catalog.gd")
const Craft = preload("res://scripts/core/craft_document.gd")
const VehicleBay = preload("res://scripts/ui/vehicle_bay.gd")
const EXPECTED := {
 "command_pod":"command_pod",
 "fuel_tank":"fuel_tank",
 "engine":"rocket_engine",
 "ring":"station_ring",
 "tank_wide":"heavy_booster_tank",
 "cryo_tank":"cryo_tank",
 "spherical_tank":"spherical_tank",
 "engine_heavy":"heavy_engine",
 "engine_vac":"vacuum_engine",
 "engine_ion":"ion_drive",
 "engine_plasma":"plasma_drive",
 "cockpit_canopy":"panoramic_cockpit",
 "cockpit_bubble":"bubble_cockpit",
 "spaceplane_wing":"spaceplane_wing",
 "delta_wing":"delta_wing",
 "nose_cone":"nose_cone",
 "needle_tip":"needle_tip",
 "orbital_fuselage":"orbital_fuselage",
 "cargo_fuselage":"cargo_fuselage"
}

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 for part_id in EXPECTED:
  var asset_name: String = str(EXPECTED[part_id])
  var path := "res://assets/blender/"+asset_name+".glb"
  if not ResourceLoader.exists(path):
   push_error("Missing generated Blender model: "+path)
   quit(1)
   return
  var packed := load(path) as PackedScene
  if packed == null:
   push_error("Blender GLB did not import as a Godot scene: "+path)
   quit(1)
   return
  var holder := Node3D.new()
  root.add_child(holder)
  Parts.add_visual(holder,Parts.ITEMS[part_id])
  var model := holder.get_node_or_null("BlenderModel_"+asset_name)
  if model == null:
   push_error("Builder did not use its Blender model for "+part_id)
   quit(1)
   return
  var meshes: Array[Node] = model.find_children("*","MeshInstance3D",true,false)
  var usable_meshes := 0
  var material_surfaces := 0
  for child in meshes:
   var mesh_node := child as MeshInstance3D
   if mesh_node != null and mesh_node.mesh != null:
    usable_meshes += 1
    material_surfaces += mesh_node.mesh.get_surface_count()
  if usable_meshes < 1 or material_surfaces < 3:
   push_error("Blender model is missing a consolidated multi-material mesh: "+part_id)
   quit(1)
   return
  holder.queue_free()
 # Exercise the real builder picker with composite Blender geometry, then
 # drag the front of two visually overlapping parts without moving the rear one.
 var bay := VehicleBay.new()
 bay.size = Vector2(960,600)
 root.add_child(bay)
 await process_frame
 var craft := Craft.create("Blender picking regression","earth")
 var camera_back: Vector3 = bay.camera.global_transform.basis.z.normalized()
 var front_uid := Craft.add_part(craft,"command_pod",bay.camera_target+camera_back*0.35)
 var rear_uid := Craft.add_part(craft,"command_pod",bay.camera_target-camera_back*0.35)
 bay.selected_id = front_uid
 bay.set_craft(craft)
 await process_frame
 var front_node: Node3D = bay.nodes[front_uid]
 var rear_node: Node3D = bay.nodes[rear_uid]
 var grab: Vector2 = bay.camera.unproject_position(front_node.global_position)*bay.size/Vector2(bay.viewport.size)
 var rear_before: Vector3 = rear_node.global_position
 if bay._hit_part(grab) != front_uid:
  push_error("Blender-built overlapping part did not select the visible front part")
  quit(1)
  return
 bay._begin_touch(grab)
 bay._continue_drag(grab+Vector2(60,0),Vector2(60,0))
 bay._finish_touch(grab+Vector2(60,0))
 if rear_node.global_position.distance_to(rear_before) > 0.001:
  push_error("Dragging a Blender-built part moved an unselected overlapping part")
  quit(1)
  return
 var front_after := bay.camera.unproject_position(front_node.global_position)*bay.size/Vector2(bay.viewport.size)
 if front_after.distance_to(grab+Vector2(60,0)) > 3.0:
  push_error("Blender-built part drag did not follow the pointer")
  quit(1)
  return
 print("BLENDER_ASSETS_SMOKE_PASS: GLBs import, render, select and drag without moving overlapping parts")
 quit(0)
