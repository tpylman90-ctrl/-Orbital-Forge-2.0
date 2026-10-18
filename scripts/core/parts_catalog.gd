extends RefCounted
class_name OFParts
# Procedural, Android-friendly component catalog. Existing IDs remain stable.
const ITEMS := {
 "command_pod":{"name":"Command Pod","kind":"core","color":"#66b9df","radius":0.6,"length":1.3,"action":"none"},
 "fuel_tank":{"name":"Fuel Tank","kind":"tank","color":"#e7e9ed","radius":0.52,"length":1.8,"action":"none"},
 "engine":{"name":"Rocket Engine","kind":"engine","color":"#df9b4d","radius":0.44,"length":0.85,"action":"none"},
 "truss":{"name":"Structural Truss","kind":"truss","color":"#7bc5ca","radius":0.24,"length":2.2,"action":"none"},
 "plate":{"name":"Deck Plate","kind":"plate","color":"#7486b5","radius":0.7,"length":0.18,"action":"none"},
 "ring":{"name":"Station Ring","kind":"ring","color":"#acc5f4","radius":1.25,"length":0.28,"action":"none"},
 "solar_panel":{"name":"Solar Array","kind":"panel","color":"#356aaf","radius":0.9,"length":0.12,"action":"none"},
 "thruster":{"name":"Vacuum Thruster","kind":"engine","color":"#be75db","radius":0.32,"length":0.65,"action":"none"},
 "capsule":{"name":"Orbital Crew Capsule","kind":"core","color":"#79aacf","radius":0.7,"length":1.15,"action":"none"},
 "probe_core":{"name":"AI Probe Sphere","kind":"sphere","color":"#b3d5dc","radius":0.52,"length":0.95,"action":"none"},
 "spire_core":{"name":"Aether Spire Core","kind":"spire","color":"#ab78f4","radius":0.42,"length":1.7,"action":"none"},
 "tank_short":{"name":"Compact Fuel Tank","kind":"tank","color":"#edf0f1","radius":0.56,"length":0.9,"action":"none"},
 "tank_long":{"name":"Long Fuel Tank","kind":"tank","color":"#dbe6eb","radius":0.55,"length":2.7,"action":"none"},
 "tank_wide":{"name":"Heavy Booster Tank","kind":"tank","color":"#c7d6e0","radius":0.85,"length":2.2,"action":"none"},
 "cryo_tank":{"name":"Cryogenic Tank","kind":"tank","color":"#83bedd","radius":0.65,"length":1.85,"action":"none"},
 "engine_heavy":{"name":"Titan Launch Engine","kind":"engine","color":"#ce8157","radius":0.7,"length":1.3,"action":"none"},
 "engine_vac":{"name":"Vacuum Bell Engine","kind":"engine","color":"#a2afb9","radius":0.7,"length":0.95,"action":"none"},
 "engine_ion":{"name":"Ion Drive","kind":"ion","color":"#8b8bea","radius":0.52,"length":0.85,"action":"none"},
 "engine_plasma":{"name":"Plasma Vortex Drive","kind":"ion","color":"#9a6de0","radius":0.72,"length":1.25,"action":"none"},
 "truss_short":{"name":"Short Truss","kind":"truss","color":"#8cbac0","radius":0.24,"length":0.9,"action":"none"},
 "adapter":{"name":"Tapered Adapter","kind":"adapter","color":"#a5b2bc","radius":0.7,"length":0.65,"action":"none"},
 "engine_plate":{"name":"Engine Mount Plate","kind":"plate","color":"#6f8296","radius":0.85,"length":0.22,"action":"none"},
 "decoupler":{"name":"Inline Separation Disk","kind":"decoupler_inline","color":"#eda83e","radius":0.63,"length":0.22,"action":"detach_above"},
 "radial_decoupler":{"name":"Radial Ejector Block","kind":"decoupler_radial","color":"#efa34a","radius":0.24,"length":0.65,"action":"detach_side_children"},
 "separator_tube":{"name":"Split Separator Tube","kind":"separator_tube","color":"#e0af55","radius":0.65,"length":0.95,"action":"split_shell"},
 "payload_bay":{"name":"Deployable Payload Tube","kind":"payload_bay","color":"#9faebb","radius":0.78,"length":1.8,"action":"release_internal_payload"},
 "fairing":{"name":"Jettison Fairing","kind":"fairing","color":"#c4d6e9","radius":0.82,"length":1.6,"action":"split_shell"},
 "docking_port":{"name":"Docking Port","kind":"decoupler_inline","color":"#84b5bc","radius":0.5,"length":0.22,"action":"detach_above"},
 "gravity_ring":{"name":"Gravitic Halo","kind":"ring","color":"#ad89f6","radius":1.1,"length":0.25,"action":"none"}
}
static func ports(item: Dictionary) -> Dictionary:
 var h: float = float(item.get("length",1.0))*0.5
 var r: float = float(item.get("radius",0.5))
 var k: String = str(item.get("kind","tank"))
 if k == "decoupler_radial":
  return {"inner":Vector3(-r,0,0),"outer":Vector3(r,0,0)}
 return {"top":Vector3(0,h,0),"bottom":Vector3(0,-h,0),"right":Vector3(r,0,0),"left":Vector3(-r,0,0),"front":Vector3(0,0,r),"back":Vector3(0,0,-r)}

static func make_mesh(item: Dictionary) -> Mesh:
 var kind: String = str(item.get("kind","tank"))
 var radius: float = float(item.get("radius",0.5))
 var length: float = float(item.get("length",1.0))
 if kind == "ring":
  var ring := TorusMesh.new()
  ring.inner_radius = radius*0.7
  ring.outer_radius = radius
  ring.rings = 20
  ring.ring_segments = 32
  return ring
 if kind in ["truss","plate","panel","decoupler_radial"]:
  var box := BoxMesh.new()
  box.size = Vector3(radius*2.0,length,radius*(3.0 if kind == "panel" else 2.0))
  return box
 if kind == "sphere":
  var sphere := SphereMesh.new()
  sphere.radius = radius
  sphere.height = length
  return sphere
 var cylinder := CylinderMesh.new()
 cylinder.height = length
 cylinder.radial_segments = 32
 cylinder.top_radius = radius*(0.4 if kind == "engine" else 0.45 if kind == "core" else 0.1 if kind == "spire" else 0.7 if kind == "adapter" else 1.0)
 cylinder.bottom_radius = radius*(0.8 if kind == "ion" else 1.0)
 return cylinder

static func add_visual(holder: Node3D, item: Dictionary) -> void:
 var main := MeshInstance3D.new()
 main.mesh = make_mesh(item)
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(str(item.get("color","#ffffff")))
 mat.metallic = 0.4
 mat.roughness = 0.35
 main.material_override = mat
 holder.add_child(main)
 var kind: String = str(item.get("kind","tank"))
 var radius: float = float(item.get("radius",0.5))
 var length: float = float(item.get("length",1.0))
 if kind in ["tank","core","engine","ion","separator_tube","payload_bay","fairing","decoupler_inline","spire"]:
  var trim := StandardMaterial3D.new()
  trim.albedo_color = Color("#263e55") if kind not in ["ion","spire"] else Color("#44cddd")
  trim.metallic = 0.75
  for fraction in [-0.38,0.38]:
   var band := MeshInstance3D.new()
   var band_mesh := CylinderMesh.new()
   band_mesh.height = minf(0.09,length*0.14)
   band_mesh.top_radius = radius*1.035
   band_mesh.bottom_radius = radius*1.035
   band_mesh.radial_segments = 32
   band.mesh = band_mesh
   band.position.y = length*fraction
   band.material_override = trim
   holder.add_child(band)
 if kind in ["engine","ion"]:
  var nozzle := MeshInstance3D.new()
  var bell := CylinderMesh.new()
  bell.top_radius = radius*0.45
  bell.bottom_radius = radius*0.86
  bell.height = length*0.42
  bell.radial_segments = 32
  nozzle.mesh = bell
  nozzle.position.y = -length*0.35
  var dark := StandardMaterial3D.new()
  dark.albedo_color = Color("#293441")
  dark.metallic = 0.8
  nozzle.material_override = dark
  holder.add_child(nozzle)
 if kind in ["separator_tube","payload_bay","fairing","decoupler_radial"]:
  var marker := MeshInstance3D.new()
  var mark := BoxMesh.new()
  mark.size = Vector3(radius*1.65,0.085,0.07)
  marker.mesh = mark
  marker.position = Vector3(0,0,radius*1.02)
  var warning := StandardMaterial3D.new()
  warning.albedo_color = Color("#f0a73b")
  marker.material_override = warning
  holder.add_child(marker)

 # Visual trim below is deliberately cheap: solid meshes, no image textures.
 if kind in ["tank","payload_bay","fairing"]:
  for side in [-1.0,1.0]:
   var rib := MeshInstance3D.new()
   var strip := BoxMesh.new()
   strip.size = Vector3(0.075,length*0.72,0.11)
   rib.mesh = strip
   rib.position = Vector3(side*radius*0.98,0,0)
   var metal := StandardMaterial3D.new()
   metal.albedo_color = Color("#667c87")
   metal.metallic = 0.65
   rib.material_override = metal
   holder.add_child(rib)
 if kind in ["truss","decoupler_radial"]:
  var brace_material := StandardMaterial3D.new()
  brace_material.albedo_color = Color("#d8e5e6")
  brace_material.metallic = 0.65
  for side in [-1.0,1.0]:
   var brace := MeshInstance3D.new()
   var bar := CylinderMesh.new()
   bar.top_radius = 0.045
   bar.bottom_radius = 0.045
   bar.height = sqrt(length*length+radius*radius*4.0)
   bar.radial_segments = 6
   brace.mesh = bar
   brace.position.z = side*radius*0.85
   brace.rotation.z = atan2(radius*2.0,length)
   brace.material_override = brace_material
   holder.add_child(brace)
 if kind in ["core","sphere"]:
  var viewport_lens := MeshInstance3D.new()
  var lens_mesh := SphereMesh.new()
  lens_mesh.radius = radius*0.22
  lens_mesh.height = radius*0.18
  viewport_lens.mesh = lens_mesh
  viewport_lens.position = Vector3(0,length*0.15,radius*0.96)
  var glass := StandardMaterial3D.new()
  glass.albedo_color = Color("#15364b")
  glass.metallic = 0.65
  viewport_lens.material_override = glass
  holder.add_child(viewport_lens)
 if kind in ["ring","ion","spire"]:
  var accent := MeshInstance3D.new()
  var accent_mesh := TorusMesh.new()
  accent_mesh.inner_radius = radius*0.38
  accent_mesh.outer_radius = radius*0.52
  accent_mesh.rings = 12
  accent_mesh.ring_segments = 20
  accent.mesh = accent_mesh
  accent.rotation.x = PI*0.5 if kind == "ion" else 0.0
  var glow := StandardMaterial3D.new()
  glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  glow.albedo_color = Color("#5bd5e8") if kind != "spire" else Color("#bd8aff")
  accent.material_override = glow
  holder.add_child(accent)
