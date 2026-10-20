extends RefCounted
class_name OFStageSimulator
# Construction-bay staging preview: a working copy, never the saved design.
const Craft = preload("res://scripts/core/craft_document.gd")

static func preview(source: Dictionary, stage_index: int) -> Dictionary:
 var doc: Dictionary = source.duplicate(true)
 var stages: Array = doc.get("stages",[])
 if stage_index < 0 or stage_index >= stages.size():
  return _fail(doc,"No stage at this position.")
 var stage: Dictionary = stages[stage_index]
 var uid: String = str(stage.get("part",""))
 var actor: Dictionary = Craft.find_part(doc,uid)
 if actor.is_empty():
  return _fail(doc,"Stage component no longer exists.")
 var action: String = str(stage.get("action","none"))
 var actor_pos: Vector3 = _pos(actor)
 var cut: Array = []
 var seeds: Array = []
 var directions: Dictionary = {}
 for link in doc.get("links",[]):
  var a: String = str(link.get("a",""))
  var b: String = str(link.get("b",""))
  if a != uid and b != uid: continue
  var other_id: String = b if a == uid else a
  var other: Dictionary = Craft.find_part(doc,other_id)
  if other.is_empty(): continue
  var delta: Vector3 = _pos(other)-actor_pos
  var direction := Vector3.UP
  var eligible := false
  match action:
   "detach_above":
    eligible = delta.y > 0.01
    direction = Vector3.UP
   "detach_side_children":
    eligible = absf(delta.x)+absf(delta.z) > 0.05
    direction = Vector3(delta.x,0,delta.z).normalized()
   "split_shell":
    eligible = delta.y > 0.01 or absf(delta.x)+absf(delta.z) > 0.05
    direction = delta.normalized() if delta.length() > 0.01 else Vector3.UP
   "release_internal_payload":
    eligible = delta.y > 0.01
    direction = Vector3.UP
  if eligible:
   cut.append(link)
   seeds.append(other_id)
   directions[other_id] = direction
 if cut.is_empty():
  return _fail(doc,"No releasable attachment on this stage. Connect a payload or booster first.")
 for link in cut: doc["links"].erase(link)
 var anchored: Array = Craft.connected_group(doc,uid)
 var released_ids: Dictionary = {}
 var released_groups: Array = []
 for seed in seeds:
  if anchored.has(seed) or released_ids.has(seed): continue
  var group: Array = Craft.connected_group(doc,str(seed))
  var dir: Vector3 = directions[seed]
  for member in group: released_ids[str(member)] = true
  released_groups.append({"members":group,"direction":dir})
 if released_groups.is_empty():
  return _fail(source.duplicate(true),"Another connection still holds the stage in place.")
 var moved := 0
 var released_uids: Array[String] = []
 var released_types: Array[String] = []
 for group in released_groups:
  var offset: Vector3 = group["direction"] * (1.7 if action == "detach_side_children" else 1.25)
  for member in group["members"]:
   var piece: Dictionary = Craft.find_part(doc,str(member))
   if piece.is_empty(): continue
   var p: Vector3 = _pos(piece)+offset
   piece["position"] = [p.x,p.y,p.z]
   moved += 1
   var released_uid := str(member)
   released_uids.append(released_uid)
   released_types.append(str(piece.get("type","")))
 return {"ok":true,"craft":doc,"action":action,"actor":uid,"released":moved,
	"released_uids":released_uids,"released_types":released_types,
  "message":"STAGE %d: %d component(s) released. Saved design is unchanged." % [stage_index+1,moved]}

static func _fail(doc: Dictionary, message: String) -> Dictionary:
 return {"ok":false,"craft":doc,"message":message}

static func _pos(part: Dictionary) -> Vector3:
 var p: Array = part["position"]
 return Vector3(float(p[0]),float(p[1]),float(p[2]))
