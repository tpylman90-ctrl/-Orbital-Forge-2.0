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
 "gravity_ring":{"name":"Gravitic Halo","kind":"ring","color":"#ad89f6","radius":1.1,"length":0.25,"action":"none"},
 "nose_cone":{"name":"Aerodynamic Nose Cone","kind":"nose","color":"#d8e0e4","radius":0.62,"length":1.2,"action":"none"},
 "solid_booster":{"name":"Solid Rocket Booster","kind":"booster","color":"#c8c9c5","radius":0.72,"length":2.8,"action":"none"},
 "booster_nozzle":{"name":"Booster Thrust Bell","kind":"booster_engine","color":"#b77b56","radius":0.62,"length":1.0,"action":"none"},
 "crew_capsule_mk2":{"name":"Crew Capsule Mk II","kind":"crew_capsule","color":"#e2e3df","radius":0.72,"length":1.45,"action":"none"},
 "lander_stage":{"name":"Lunar Descent Stage","kind":"lander","color":"#c5a45e","radius":0.92,"length":1.25,"action":"none"},
 "landing_legs":{"name":"Deployable Landing Legs","kind":"landing_legs","color":"#bac4c5","radius":0.82,"length":1.1,"action":"none"},
 "rcs_block":{"name":"Four-Way RCS Cluster","kind":"rcs","color":"#aebdc3","radius":0.44,"length":0.56,"action":"none"},
 "service_module":{"name":"Crew Service Module","kind":"service_module","color":"#b9c3c8","radius":0.66,"length":1.35,"action":"none"},
 "heat_shield":{"name":"Reentry Heat Shield","kind":"heat_shield","color":"#6d737a","radius":0.86,"length":0.34,"action":"none"},
 "cargo_pod":{"name":"Pressurized Cargo Pod","kind":"cargo_pod","color":"#b5c4c7","radius":0.74,"length":1.65,"action":"none"},
 "radiator_panel":{"name":"Deployable Radiator Wing","kind":"radiator","color":"#c17b54","radius":0.85,"length":0.16,"action":"none"},
 "comms_dish":{"name":"Long-Range Comms Dish","kind":"antenna","color":"#d4d8d5","radius":0.72,"length":0.9,"action":"none"},
 "deployable_boom":{"name":"Survey Instrument Boom","kind":"boom","color":"#d2a84c","radius":0.18,"length":1.8,"action":"none"},
 "fuel_crossfeed":{"name":"Fuel Crossfeed Manifold","kind":"crossfeed","color":"#d6d9d5","radius":0.35,"length":1.25,"action":"none"}
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
 if kind in ["truss","plate","panel","decoupler_radial","radiator","boom","landing_legs"]:
  var box := BoxMesh.new()
  if kind == "radiator":
   box.size = Vector3(radius*1.94,length*0.7,radius*1.4)
  elif kind == "landing_legs":
   box.size = Vector3(radius*0.5,length*0.22,radius*0.5)
  elif kind == "boom":
   box.size = Vector3(radius*0.7,length,radius*0.7)
  else:
   box.size = Vector3(radius*2.0,length,radius*(3.0 if kind == "panel" else 2.0))
  return box
 if kind == "sphere":
  var sphere := SphereMesh.new()
  sphere.radius = radius
  sphere.height = length
  return sphere
 var cylinder := CylinderMesh.new()
 cylinder.height = length
 cylinder.radial_segments = 28
 cylinder.top_radius = radius*(0.4 if kind == "engine" else 0.45 if kind == "core" else 0.1 if kind == "spire" else 0.7 if kind == "adapter" else 1.0)
 cylinder.bottom_radius = radius*(0.8 if kind == "ion" else 1.0)
 if kind in ["nose","booster_engine"]:
  cylinder.top_radius = radius*0.08 if kind == "nose" else radius*0.42
  cylinder.bottom_radius = radius
 if kind == "fairing":
  cylinder.top_radius = radius*0.055
  cylinder.bottom_radius = radius
 if kind == "heat_shield":
  cylinder.top_radius = radius*0.72
  cylinder.bottom_radius = radius
 if kind in ["crew_capsule","service_module","cargo_pod","booster"]:
  cylinder.top_radius = radius*0.94
  cylinder.bottom_radius = radius
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
 if kind in ["tank","core","engine","ion","separator_tube","payload_bay","fairing","decoupler_inline","spire","booster","crew_capsule","service_module","cargo_pod"]:
  var trim := StandardMaterial3D.new()
  trim.albedo_color = Color("#263e55") if kind not in ["ion","spire"] else Color("#44cddd")
  trim.metallic = 0.75
  for fraction in [-0.38,0.38]:
   var band_radius: float = radius*1.035
   if kind == "fairing":
    band_radius = radius*lerpf(1.035,0.07,fraction+0.5)
   var band := MeshInstance3D.new()
   var band_mesh := CylinderMesh.new()
   band_mesh.height = minf(0.09,length*0.14)
   band_mesh.top_radius = band_radius
   band_mesh.bottom_radius = band_radius
   band_mesh.radial_segments = 28
   band.mesh = band_mesh
   band.position.y = length*fraction
   band.material_override = trim
   holder.add_child(band)
 if kind in ["engine","ion","booster_engine"]:
  var nozzle := MeshInstance3D.new()
  var bell := CylinderMesh.new()
  bell.top_radius = radius*(0.42 if kind != "booster_engine" else 0.55)
  bell.bottom_radius = radius*(0.86 if kind != "booster_engine" else 1.02)
  bell.height = length*0.42
  bell.radial_segments = 28
  nozzle.mesh = bell
  nozzle.position.y = -length*0.35
  var dark := StandardMaterial3D.new()
  dark.albedo_color = Color("#293441")
  dark.metallic = 0.8
  nozzle.material_override = dark
  holder.add_child(nozzle)
 if kind in ["separator_tube","payload_bay","fairing","decoupler_radial","booster"]:
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
 if kind in ["tank","payload_bay","booster","cargo_pod","service_module"]:
  for angle in [0.0,PI*0.5,PI,PI*1.5]:
   var rib := MeshInstance3D.new()
   var strip := BoxMesh.new()
   strip.size = Vector3(0.065,length*0.72,0.055)
   rib.mesh = strip
   rib.position = Vector3(sin(angle)*radius*0.99,0,cos(angle)*radius*0.99)
   rib.rotation.y = -angle
   var metal := StandardMaterial3D.new()
   metal.albedo_color = Color("#667c87")
   metal.metallic = 0.65
   rib.material_override = metal
   holder.add_child(rib)
 if kind in ["tank","payload_bay","booster","cargo_pod"]:
  for side in [-1.0,1.0]:
   _add_cylinder(holder,Vector3(0,side*length*0.445,0),radius*1.035,radius*1.035,0.095,Color("#77858c"),28)
   _add_fastener_ring(holder,side*length*0.445,radius*1.045,10,Color("#e1e5e2"))
 if kind in ["truss","decoupler_radial"]:
  var brace_material := StandardMaterial3D.new()
  brace_material.albedo_color = Color("#d8e5e6")
  brace_material.metallic = 0.65
  for side in [-1.0,1.0]:
   var brace := MeshInstance3D.new()
   var bar := CylinderMesh.new()
   bar.top_radius = 0.035
   bar.bottom_radius = 0.035
   bar.height = sqrt(length*length+radius*radius*4.0)
   bar.radial_segments = 8
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
  accent_mesh.rings = 20
  accent_mesh.ring_segments = 32
  accent.mesh = accent_mesh
  accent.rotation.x = PI*0.5 if kind == "ion" else 0.0
  var glow := StandardMaterial3D.new()
  glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  glow.albedo_color = Color("#5bd5e8") if kind != "spire" else Color("#bd8aff")
  accent.material_override = glow
  holder.add_child(accent)

 # Silhouette-specific finishing: designed hardware at low polygon budgets.
 if kind == "engine":
  var collar := MeshInstance3D.new()
  var collar_mesh := CylinderMesh.new()
  collar_mesh.top_radius = radius*0.79
  collar_mesh.bottom_radius = radius*0.79
  collar_mesh.height = length*0.17
  collar_mesh.radial_segments = 24
  collar.mesh = collar_mesh
  collar.position.y = length*0.35
  var collar_material := StandardMaterial3D.new()
  collar_material.albedo_color = Color("#545e6a")
  collar_material.metallic = 0.7
  collar.material_override = collar_material
  holder.add_child(collar)
  for angle in [0.0,PI*0.25,PI*0.5,PI*0.75,PI,PI*1.25,PI*1.5,PI*1.75]:
   var cooling_fin := MeshInstance3D.new()
   var fin_mesh := BoxMesh.new()
   fin_mesh.size = Vector3(radius*0.12,length*0.34,0.055)
   cooling_fin.mesh = fin_mesh
   cooling_fin.position = Vector3(sin(angle)*radius*0.87,-length*0.06,cos(angle)*radius*0.87)
   cooling_fin.rotation.y = -angle
   cooling_fin.material_override = _material(Color("#6c7479"),0.75,0.32)
   holder.add_child(cooling_fin)
  _add_fastener_ring(holder,length*0.35,radius*0.81,8,Color("#d7b477"))
  _add_cylinder(holder,Vector3(0,-length*0.56,0),radius*0.56,radius*0.56,0.035,Color("#17222c"),20)
 if kind == "panel":
  for t in [-0.72,-0.36,0.0,0.36,0.72]:
   var grid_line := MeshInstance3D.new()
   var thin := BoxMesh.new()
   thin.size = Vector3(radius*1.98,0.025,0.045)
   grid_line.mesh = thin
   grid_line.position.z = t*radius*2.5
   var line_material := StandardMaterial3D.new()
   line_material.albedo_color = Color("#9ec6d9")
   grid_line.material_override = line_material
   holder.add_child(grid_line)
  for x in [-1.0,1.0]:
   _add_box(holder,Vector3(x*radius*0.97,0,0),Vector3(0.055,0.08,radius*3.0),Color("#829ba5"))
  for z in [-1.0,1.0]:
   _add_box(holder,Vector3(0,0,z*radius*1.45),Vector3(radius*2.0,0.08,0.055),Color("#829ba5"))
 if kind in ["decoupler_inline","separator_tube","fairing"]:
  var warning_band := MeshInstance3D.new()
  var warning_mesh := CylinderMesh.new()
  warning_mesh.top_radius = radius*1.065
  warning_mesh.bottom_radius = radius*1.065
  warning_mesh.height = minf(length*0.12,0.12)
  warning_mesh.radial_segments = 28
  warning_band.mesh = warning_mesh
  var warning_material := StandardMaterial3D.new()
  warning_material.albedo_color = Color("#e4a345")
  warning_band.material_override = warning_material
  holder.add_child(warning_band)

 # New flight hardware uses a few authored silhouettes with restrained detail.
 # The parts remain solid mesh assets so the editor stays light on Android.
 if kind == "nose":
  _add_cylinder(holder,Vector3(0,length*0.43,0),radius*0.08,radius*0.12,0.24,Color("#c9d3d7"),28)
  _add_cylinder(holder,Vector3(0,-length*0.28,0),radius*1.035,radius*1.035,0.12,Color("#52616a"),28)
  _add_fastener_ring(holder,-length*0.34,radius*1.04,8,Color("#e0e4e3"))
 if kind == "booster":
  for y_fraction in [-0.43,-0.34,0.34,0.43]:
   _add_cylinder(holder,Vector3(0,length*y_fraction,0),radius*1.035,radius*1.035,0.065,Color("#5c6062"),20)
  _add_cylinder(holder,Vector3(0,length*0.18,0),radius*1.01,radius*1.01,0.1,Color("#e0e1dc"),20)
  _add_fastener_ring(holder,-length*0.43,radius*1.04,10,Color("#e2e0d9"))
  _add_fastener_ring(holder,length*0.43,radius*1.04,10,Color("#e2e0d9"))
 if kind == "booster_engine":
  _add_cylinder(holder,Vector3(0,length*0.35,0),radius*0.88,radius*0.88,0.16,Color("#4b5358"),16)
  _add_cylinder(holder,Vector3(0,-length*0.4,0),radius*0.72,radius*0.98,0.14,Color("#4c5258"),16)
  _add_fastener_ring(holder,length*0.34,radius*0.9,8,Color("#d5b581"))
 if kind == "crew_capsule":
  _add_sphere(holder,Vector3(0,length*0.34,0),Vector3(radius*0.9,length*0.3,radius*0.9),Color("#c7d4d8"))
  _add_cylinder(holder,Vector3(0,-length*0.35,0),radius*0.84,radius*0.96,0.14,Color("#505d67"),18)
  for angle in [0.0,PI*0.5,PI,PI*1.5]:
   var window := MeshInstance3D.new()
   var window_mesh := SphereMesh.new()
   window_mesh.radius = radius*0.12
   window_mesh.height = radius*0.12
   window.mesh = window_mesh
   window.position = Vector3(sin(angle)*radius*0.83,length*0.08,cos(angle)*radius*0.83)
   window.material_override = _material(Color("#24465a"),0.72,0.18)
   holder.add_child(window)
  _add_fastener_ring(holder,-length*0.36,radius*0.88,10,Color("#d4d9d7"))
 if kind == "service_module":
  _add_cylinder(holder,Vector3(0,-length*0.08,0),radius*1.04,radius*1.04,0.1,Color("#596773"),20)
  for angle in [0.0,PI*0.5,PI,PI*1.5]:
   var tank := MeshInstance3D.new()
   var tank_mesh := CylinderMesh.new()
   tank_mesh.top_radius = radius*0.16
   tank_mesh.bottom_radius = radius*0.16
   tank_mesh.height = length*0.52
   tank_mesh.radial_segments = 8
   tank.mesh = tank_mesh
   tank.position = Vector3(sin(angle)*radius*0.68,-length*0.24,cos(angle)*radius*0.68)
   tank.material_override = _material(Color("#c7cfd0"),0.55,0.35)
   holder.add_child(tank)
  _add_fastener_ring(holder,length*0.37,radius*1.04,8,Color("#dce0dd"))
 if kind == "lander":
  _add_cylinder(holder,Vector3(0,length*0.5,0),radius*0.62,radius*0.62,0.12,Color("#7b6747"),16)
  for angle in [0.0,PI*0.5,PI,PI*1.5]:
   var pod := MeshInstance3D.new()
   var pod_mesh := BoxMesh.new()
   pod_mesh.size = Vector3(radius*0.16,length*0.6,radius*0.16)
   pod.mesh = pod_mesh
   pod.position = Vector3(sin(angle)*radius*0.75,0,cos(angle)*radius*0.75)
   pod.material_override = _material(Color("#d3b873"),0.42,0.48)
   holder.add_child(pod)
 if kind == "landing_legs":
  for angle in [0.0,PI*0.5,PI,PI*1.5]:
   var leg := MeshInstance3D.new()
   var leg_mesh := CylinderMesh.new()
   leg_mesh.top_radius = 0.045
   leg_mesh.bottom_radius = 0.055
   leg_mesh.height = length
   leg_mesh.radial_segments = 6
   leg.mesh = leg_mesh
   var outward := Vector3(sin(angle),0,cos(angle))
   leg.position = outward*radius*0.74+Vector3(0,-length*0.14,0)
   leg.rotation.z = outward.x*0.42
   leg.rotation.x = -outward.z*0.42
   leg.material_override = _material(Color("#d0d7d6"),0.72,0.3)
   holder.add_child(leg)
   _add_box(holder,outward*(radius*1.28)+Vector3(0,-length*0.6,0),Vector3(0.35,0.1,0.26),Color("#475761"))
 if kind == "rcs":
  for angle in [0.0,PI*0.5,PI,PI*1.5]:
   var nozzle_part := MeshInstance3D.new()
   var nozzle_mesh := CylinderMesh.new()
   nozzle_mesh.top_radius = radius*0.13
   nozzle_mesh.bottom_radius = radius*0.2
   nozzle_mesh.height = length*0.62
   nozzle_mesh.radial_segments = 8
   nozzle_part.mesh = nozzle_mesh
   nozzle_part.position = Vector3(sin(angle)*radius*0.73,0,cos(angle)*radius*0.73)
   nozzle_part.rotation.z = sin(angle)*0.55
   nozzle_part.rotation.x = -cos(angle)*0.55
   nozzle_part.material_override = _material(Color("#4d5962"),0.82,0.24)
   holder.add_child(nozzle_part)
 if kind == "heat_shield":
  _add_cylinder(holder,Vector3(0,-length*0.18,0),radius*0.92,radius,0.1,Color("#343a40"),20)
  _add_fastener_ring(holder,length*0.12,radius*0.9,12,Color("#c0a56c"))
 if kind == "cargo_pod":
  _add_cylinder(holder,Vector3(0,length*0.36,0),radius*1.02,radius*1.02,0.09,Color("#53616b"),18)
  _add_cylinder(holder,Vector3(0,-length*0.36,0),radius*1.02,radius*1.02,0.09,Color("#53616b"),18)
  _add_fastener_ring(holder,length*0.36,radius*1.03,10,Color("#d8dedc"))
 if kind == "radiator":
  for z_fraction in [-0.72,-0.36,0.0,0.36,0.72]:
   _add_box(holder,Vector3(0,length*0.4,z_fraction*radius*0.9),Vector3(radius*1.8,0.025,0.035),Color("#d8a078"))
 if kind == "antenna":
  _add_cylinder(holder,Vector3(0,-length*0.35,0),radius*0.08,radius*0.08,length*0.55,Color("#aeb7b7"),8)
  var dish := MeshInstance3D.new()
  var dish_mesh := CylinderMesh.new()
  dish_mesh.top_radius = radius*0.84
  dish_mesh.bottom_radius = radius*0.15
  dish_mesh.height = length*0.22
  dish_mesh.radial_segments = 12
  dish.mesh = dish_mesh
  dish.position.y = length*0.12
  dish.rotation.x = PI*0.5
  dish.material_override = _material(Color("#e2e5e1"),0.45,0.42)
  holder.add_child(dish)
 if kind == "boom":
  for x in [-1.0,1.0]:
   _add_cylinder(holder,Vector3(x*radius*0.45,0,0),0.025,0.025,length,Color("#d3a449"),6)
  for y in [-0.35,0.0,0.35]: _add_box(holder,Vector3(0,length*y,0),Vector3(radius*1.5,0.035,0.1),Color("#697d83"))
 if kind == "crossfeed":
  _add_cylinder(holder,Vector3(0,0,0),radius*0.64,radius*0.64,length*0.78,Color("#66757c"),12)
  for y_fraction in [-0.34,0.34]:
   _add_cylinder(holder,Vector3(0,length*y_fraction,0),radius*1.18,radius*1.18,0.1,Color("#d6ad59"),12)
  _add_fastener_ring(holder,length*0.34,radius*1.2,8,Color("#dfe2df"))

static func _material(color: Color, metal: float = 0.35, rough: float = 0.4) -> StandardMaterial3D:
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.metallic = metal
 material.roughness = rough
 return material

static func _add_box(holder: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
 var detail := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 detail.mesh = mesh
 detail.position = pos
 detail.material_override = _material(color)
 holder.add_child(detail)

static func _add_sphere(holder: Node3D, pos: Vector3, scale: Vector3, color: Color) -> void:
 var detail := MeshInstance3D.new()
 var mesh := SphereMesh.new()
 mesh.radius = 0.5
 mesh.height = 1.0
 detail.mesh = mesh
 detail.position = pos
 detail.scale = scale*2.0
 detail.material_override = _material(color,0.45,0.34)
 holder.add_child(detail)

static func _add_cylinder(holder: Node3D, pos: Vector3, top: float, bottom: float, height: float, color: Color, segments: int = 12) -> void:
 var detail := MeshInstance3D.new()
 var mesh := CylinderMesh.new()
 mesh.top_radius = top
 mesh.bottom_radius = bottom
 mesh.height = height
 mesh.radial_segments = segments
 detail.mesh = mesh
 detail.position = pos
 detail.material_override = _material(color,0.55,0.34)
 holder.add_child(detail)

static func _add_fastener_ring(holder: Node3D, y: float, radius: float, count: int, color: Color) -> void:
 var fasteners := MultiMesh.new()
 fasteners.transform_format = MultiMesh.TRANSFORM_3D
 var head := SphereMesh.new()
 head.radius = 0.025
 head.height = 0.05
 head.radial_segments = 8
 head.rings = 4
 fasteners.mesh = head
 fasteners.instance_count = count
 for i in range(count):
  var angle := TAU*float(i)/float(count)
  var position := Vector3(sin(angle)*radius,y,cos(angle)*radius)
  fasteners.set_instance_transform(i,Transform3D(Basis.IDENTITY,position))
 var instance := MultiMeshInstance3D.new()
 instance.multimesh = fasteners
 instance.material_override = _material(color,0.72,0.3)
 holder.add_child(instance)
