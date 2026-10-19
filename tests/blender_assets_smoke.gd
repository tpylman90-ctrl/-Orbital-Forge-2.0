extends SceneTree

const Parts = preload("res://scripts/core/parts_catalog.gd")
const EXPECTED := {
 "command_pod":"command_pod",
 "fuel_tank":"fuel_tank",
 "engine":"rocket_engine",
 "ring":"station_ring"
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
  for child in meshes:
   var mesh_node := child as MeshInstance3D
   if mesh_node != null and mesh_node.mesh != null:
    usable_meshes += 1
  if usable_meshes < 3:
   push_error("Blender model has too little usable geometry: "+part_id)
   quit(1)
   return
  holder.queue_free()
 print("BLENDER_ASSETS_SMOKE_PASS: generated GLBs import and render as builder components")
 quit(0)
