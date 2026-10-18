extends RefCounted
class_name OFStageSimulator
# Editor-only staging preview. Never modifies the saved craft dictionary.
const Parts = preload("res://scripts/core/parts_catalog.gd")
const Craft = preload("res://scripts/core/craft_document.gd")

static func preview(source: Dictionary, stage_index: int) -> Dictionary:
 var document: Dictionary = source.duplicate(true)
 var stages: Array = document.get("stages",[])
 if stage_index < 0 or stage_index >= stages.size():
  return {"ok":false,"message":"No stage action at this position.","craft":document}
 var stage: Dictionary = stages[stage_index]
 var uid: String = str(stage.get("part",""))
 var actor: Dictionary = Craft.find_part(document,uid)
 if actor.is_empty(): return {"ok":false,"message":"Staging part was removed.","craft":document}
 var kind: String = str(stage.get("action","none"))
 var actor_pos: Vector3 = _pos(actor)
 var cut: Array = []
 var release_direction := Vector3.UP
 for link in document.get("links",[]):
  var a: String = str(link.get("a",""))
  var b: String = str(link.get("b",""))
  if a != uid and b != uid: continue
  var other_id: String = b if a == uid else a
  var other: Dictionary = Craft.find_part(document,other_id)
  if other.is_empty(): continue
  var delta: Vector3 = _pos(other)-actor_pos
  var release := false
  match kind:
   "detach_above":
    release = delta.y > 0.01 or str(link.get("a_port" if a == uid else "b_port","")) == "top"
    release_direction = Vector3.UP
   "detach_side_children":
    release = absf(delta.x)+absf(delta.z) > 0.05
    if release: release_direction = Vector3(delta.x,0,delta.z).normalized()
   "split_shell":
    release = delta.y > 0.01
    release_direction = Vector3.UP
   "release_internal_payload":
    release = delta.y > 0.01
    release_direction = Vector3.UP
  if release: cut.append(link)
 if cut.is_empty():
  return {"ok":false,"message":"No eligible attached module. Snap a payload or booster onto this separator first.","craft":document}
 var anchor: String = str(cut[0]["b"]) if str(cut[0]["a"]) == uid else str(cut[0]["a"])
 for link in cut: document["links"].erase(link)
 # Check reachability after cutting. An alternate structural connection can keep
 # the payload attached; in that case do not animate a false release.
 var remaining: Array = Craft.connected_group(document,uid)
 if remaining.has(anchor):
  return {"ok":false,"message":"Payload is still attached by another structural connection.","craft":source.duplicate(true)}
 var detached: Array = Craft.connected_group(document,anchor)
 var offset: Vector3 = release_direction*1.3
 for member in detached:
  var piece: Dictionary = Craft.find_part(document,str(member))
  if piece.is_empty(): continue
  var p: Vector3 = _pos(piece)+offset
  piece["position"] = [p.x,p.y,p.z]
 return {"ok":true,"message":"TEST: %d component(s) released by %s. Original design unchanged." % [detached.size(),kind],"craft":document}

static func _pos(part: Dictionary) -> Vector3:
 var p: Array = part["position"]
 return Vector3(float(p[0]),float(p[1]),float(p[2]))
