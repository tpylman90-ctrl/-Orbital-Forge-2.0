extends SceneTree
const Craft = preload("res://scripts/core/craft_document.gd")
func _initialize() -> void:
 var d := Craft.create("Attached vehicle")
 var core := Craft.add_part(d,"command_pod",Vector3(0,1,0))
 var beam := Craft.add_part(d,"truss",Vector3(0,2,0))
 var panel := Craft.add_part(d,"plate",Vector3(2,2,0))
 var free := Craft.add_part(d,"engine",Vector3(5,1,0))
 if not Craft.link_parts(d,core,beam) or not Craft.link_parts(d,beam,panel):
  push_error("Links not established")
  quit(1)
  return
 Craft.move_group(d,beam,Vector3(2,0,-1))
 if float(Craft.find_part(d,core)["position"][0]) != 2.0 or float(Craft.find_part(d,panel)["position"][2]) != -1.0 or float(Craft.find_part(d,free)["position"][0]) != 5.0:
  push_error("Connected group movement altered unlinked geometry")
  quit(1)
  return
 if not Craft.validate(d):
  push_error("Connected craft invalid")
  quit(1)
  return
 if not Craft.save(d,"user://group_smoke.json") or Craft.load("user://group_smoke.json").get("links",[]).size() != 2:
  push_error("Connected craft failed persistence")
  quit(1)
  return
 print("ATTACHMENT_SMOKE_PASS")
 quit(0)
