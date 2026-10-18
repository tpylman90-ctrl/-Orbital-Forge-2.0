extends RefCounted
class_name OFParts
const ITEMS := {
 "command_pod":{"name":"Command Pod","kind":"core","color":"#66b9df","radius":0.60,"length":1.3},
 "fuel_tank":{"name":"Fuel Tank","kind":"tank","color":"#e7e9ed","radius":0.52,"length":1.8},
 "engine":{"name":"Rocket Engine","kind":"engine","color":"#df9b4d","radius":0.44,"length":0.85},
 "truss":{"name":"Structural Truss","kind":"truss","color":"#7bc5ca","radius":0.24,"length":2.2},
 "plate":{"name":"Deck Plate","kind":"plate","color":"#7486b5","radius":0.7,"length":0.18},
 "ring":{"name":"Station Ring","kind":"ring","color":"#acc5f4","radius":1.25,"length":0.28},
 "solar_panel":{"name":"Solar Array","kind":"panel","color":"#356aaf","radius":0.9,"length":0.12},
 "thruster":{"name":"Vacuum Thruster","kind":"engine","color":"#be75db","radius":0.32,"length":0.65}
}
static func make_mesh(item: Dictionary) -> Mesh:
 var kind: String = str(item.get("kind","tank"))
 var radius: float = float(item.get("radius",0.5))
 var length: float = float(item.get("length",1.0))
 if kind == "ring":
  var m := TorusMesh.new()
  m.inner_radius = radius*0.68
  m.outer_radius = radius
  m.rings = 12
  m.ring_segments = 24
  return m
 if kind in ["truss","plate","panel"]:
  var m := BoxMesh.new()
  if kind == "truss": m.size = Vector3(radius*2,length,radius*2)
  elif kind == "panel": m.size = Vector3(radius*2,length,radius*3.2)
  else: m.size = Vector3(radius*2,length,radius*2)
  return m
 var m := CylinderMesh.new()
 m.top_radius = radius*(0.55 if kind == "engine" else 0.72 if kind == "core" else 1.0)
 m.bottom_radius = radius
 m.height = length
 m.radial_segments = 20
 return m
