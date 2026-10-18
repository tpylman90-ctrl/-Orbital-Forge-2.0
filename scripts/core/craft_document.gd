extends RefCounted
class_name CraftDocument

const VERSION := 1

static func create(name: String = "New Spacecraft", environment: String = "earth") -> Dictionary:
	return {"version":VERSION,"name":name,"environment":environment,"parts":[],"links":[],"fuel_routes":{},"stages":[]}

static func add_part(document: Dictionary, type_id: String, pos: Vector3 = Vector3.ZERO, orientation: Vector3 = Vector3.ZERO, scale_factor: float = 1.0) -> String:
	var uid := "p_%05d" % int(document.get("parts",[]).size()+1)
	for part in document.get("parts",[]):
		if str(part.get("uid","")) == uid:
			uid = "p_%d" % Time.get_ticks_usec()
			break
	document["parts"].append({"uid":uid,"type":type_id,"position":[pos.x,pos.y,pos.z],"rotation":[orientation.x,orientation.y,orientation.z],"scale":clampf(scale_factor,0.5,4.0)})
	return uid

static func find_part(document: Dictionary, uid: String) -> Dictionary:
	for part in document.get("parts",[]):
		if str(part.get("uid","")) == uid: return part
	return {}

static func link_parts(document: Dictionary, a: String, b: String) -> bool:
	if a == b or find_part(document,a).is_empty() or find_part(document,b).is_empty(): return false
	for link in document["links"]:
		if (str(link["a"]) == a and str(link["b"]) == b) or (str(link["a"]) == b and str(link["b"]) == a): return false
	document["links"].append({"a":a,"b":b,"kind":"structural"})
	return true

static func remove_part(document: Dictionary, uid: String) -> void:
	document["parts"] = document["parts"].filter(func(p): return str(p["uid"]) != uid)
	document["links"] = document["links"].filter(func(link): return str(link["a"]) != uid and str(link["b"]) != uid)
	document["fuel_routes"].erase(uid)
	for engine in document["fuel_routes"]:
		document["fuel_routes"][engine].erase(uid)

static func connected_group(document: Dictionary, uid: String) -> Array:
	if find_part(document,uid).is_empty(): return []
	var found := [uid]
	var cursor := 0
	while cursor < found.size():
		var current: String = str(found[cursor])
		for link in document.get("links",[]):
			var next := ""
			if str(link.get("a","")) == current: next = str(link.get("b",""))
			elif str(link.get("b","")) == current: next = str(link.get("a",""))
			if next != "" and not found.has(next): found.append(next)
		cursor += 1
	return found

static func move_group(document: Dictionary, uid: String, delta: Vector3) -> void:
	for member in connected_group(document,uid):
		var part: Dictionary = find_part(document,str(member))
		var p: Array = part["position"]
		part["position"] = [float(p[0])+delta.x,float(p[1])+delta.y,float(p[2])+delta.z]

static func validate(document: Dictionary) -> bool:
	if int(document.get("version",0)) != VERSION or not document.get("parts",null) is Array: return false
	var ids := {}
	for part in document["parts"]:
		if not part is Dictionary: return false
		var uid := str(part.get("uid",""))
		if uid == "" or ids.has(uid): return false
		if not part.get("position",null) is Array or part["position"].size() != 3: return false
		if not part.get("rotation",null) is Array or part["rotation"].size() != 3: return false
		if float(part.get("scale",0.0)) < 0.5 or float(part.get("scale",0.0)) > 4.0: return false
		ids[uid] = true
	for link in document.get("links",[]):
		if not ids.has(str(link.get("a",""))) or not ids.has(str(link.get("b",""))): return false
	return true

static func save(document: Dictionary, path: String) -> bool:
	if not validate(document): return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(document,"  "))
	return true

static func load(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null: return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and validate(parsed): return parsed
	return {}
