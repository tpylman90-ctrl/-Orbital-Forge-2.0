extends Control
class_name OFPartCatalogIcon

var part: Dictionary = {}

func configure(spec: Dictionary) -> void:
	part = spec.duplicate()
	queue_redraw()

func _draw() -> void:
	if part.is_empty(): return
	var scale_factor := minf(size.x,size.y)/64.0
	var offset := (size-Vector2.ONE*64.0*scale_factor)*0.5
	draw_set_transform(offset,0.0,Vector2.ONE*scale_factor)
	var shell := Color(str(part.get("color","#b9c9d2")))
	var light := shell.lightened(0.32)
	var dark := shell.darkened(0.42)
	var kind := str(part.get("kind","misc"))
	var shape := str(part.get("shape",""))
	draw_circle(Vector2.ZERO,28.0,Color("#14283a"))
	draw_arc(Vector2.ZERO,27.5,0.0,TAU,48,Color("#294357"),1.2,true)

	if kind == "ring":
		var radius := 20.0 if float(part.get("radius",1.0)) > 1.15 else 17.0
		draw_circle(Vector2.ZERO,radius,shell)
		draw_circle(Vector2.ZERO,radius*0.57,Color("#14283a"))
		draw_arc(Vector2.ZERO,radius*0.78,PI*1.05,PI*1.88,24,light,2.0,true)
		draw_circle(Vector2(0,-radius-1.0),2.0,Color("#d8b86e"))
	elif kind in ["wing","tail_fin","panel","radiator","plate"]:
		_draw_flat_part(kind,shape,shell,light,dark)
	elif kind in ["truss","boom","antenna","decoupler_radial","crossfeed","rcs","landing_legs"]:
		_draw_frame_part(kind,shell,light,dark)
	elif kind in ["engine","ion","booster_engine"]:
		_draw_engine(kind,shell,light,dark)
	elif kind == "tank" and shape == "spherical":
		draw_circle(Vector2.ZERO,18.0,shell)
		draw_arc(Vector2.ZERO,18.0,PI*1.06,PI*1.92,20,dark,2.0,true)
		draw_arc(Vector2(-3,-3),12.0,PI*1.08,PI*1.88,18,light,2.0,true)
		draw_circle(Vector2(10,0),2.0,Color("#d8b86e"))
	elif kind == "tank" and shape == "rectangular":
		_draw_box_hull(shell,light,dark)
	else:
		_draw_axial_part(kind,shape,shell,light,dark)

	# A small mount notch gives these thumbnails a consistent inventory silhouette.
	draw_rect(Rect2(-5.0,23.0,10.0,3.0),Color("#d0a454"))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_axial_part(kind: String, shape: String, shell: Color, light: Color, dark: Color) -> void:
	var left := -11.0
	var right := 11.0
	var top := -22.0
	var bottom := 22.0
	if kind == "cockpit":
		_draw_poly([Vector2(-14,7),Vector2(-13,-8),Vector2(-8,-17),Vector2(0,-21),Vector2(9,-17),Vector2(14,-8),Vector2(14,7),Vector2(9,16),Vector2(-9,16)],shell,light)
		_draw_ellipse(Vector2(0,-3),Vector2(9,9),Color("#15384c"))
		draw_arc(Vector2(0,-3),9.0,PI*1.08,PI*1.88,18,Color("#79c9d7"),1.6,true)
		draw_line(Vector2(0,-11),Vector2(0,5),Color("#8daeba"),1.4,true)
		return
	if kind in ["core","crew_capsule"] or kind == "nose":
		_draw_poly([Vector2(left,10),Vector2(left,0),Vector2(-8,-11),Vector2(-4,-19),Vector2(0,-24),Vector2(4,-19),Vector2(8,-11),Vector2(right,0),Vector2(right,10),Vector2(8,18),Vector2(-8,18)],shell,light)
		draw_rect(Rect2(-12,9,24,4),dark)
		draw_rect(Rect2(-4,17,8,4),Color("#d0a454"))
		if kind == "core":
			_draw_ellipse(Vector2(0,1),Vector2(4.6,6.0),Color("#15364b"))
			draw_arc(Vector2(0,1),5.4,PI*1.1,PI*1.9,12,Color("#a9dbe4"),1.0,true)
		elif kind == "nose" and shape == "needle":
			draw_line(Vector2(0,-23),Vector2(0,-10),light,1.2,true)
		return
	if kind in ["sphere","spire"]:
		if kind == "sphere":
			draw_circle(Vector2.ZERO,18.0,shell)
			draw_arc(Vector2.ZERO,18.0,PI*1.05,PI*1.9,18,dark,2.0,true)
			draw_circle(Vector2(5,-5),4.0,Color("#15364b"))
			draw_circle(Vector2(4,-6),1.4,Color("#81d7e6"))
		else:
			_draw_poly([Vector2(-10,20),Vector2(-8,-12),Vector2(-3,-18),Vector2(0,-27),Vector2(4,-18),Vector2(8,-12),Vector2(10,20)],shell,light)
			draw_line(Vector2(-7,10),Vector2(7,10),Color("#52d9e5"),2.0,true)
			draw_line(Vector2(-6,15),Vector2(6,15),Color("#6f53a8"),1.6,true)
		return
	if kind in ["heat_shield","lander"]:
		_draw_poly([Vector2(-20,5),Vector2(-15,-5),Vector2(-8,-8),Vector2(8,-8),Vector2(15,-5),Vector2(20,5),Vector2(15,12),Vector2(-15,12)],shell,light)
		draw_line(Vector2(-16,7),Vector2(16,7),Color("#d4aa5b"),2.0,true)
		if kind == "lander":
			draw_line(Vector2(-11,13),Vector2(-19,22),light,2.0,true)
			draw_line(Vector2(11,13),Vector2(19,22),light,2.0,true)
		return
	# Standard pressure tank, adapter, fairing, fuselage or payload body.
	if kind == "adapter":
		_draw_poly([Vector2(-18,-18),Vector2(18,-18),Vector2(11,18),Vector2(-11,18)],shell,light)
	elif kind in ["fairing","separator_tube"]:
		_draw_poly([Vector2(-16,19),Vector2(-14,-9),Vector2(-8,-18),Vector2(0,-23),Vector2(8,-18),Vector2(14,-9),Vector2(16,19)],shell,light)
		if kind == "fairing": draw_line(Vector2(0,-20),Vector2(0,19),dark,1.4,true)
	else:
		left = -12.0 if kind != "fuselage" else -16.0
		right = -left
		_draw_poly([Vector2(left,-18),Vector2(right,-18),Vector2(right,18),Vector2(left,18)],shell,light)
		draw_rect(Rect2(left-2,-16,3,32),dark)
		draw_rect(Rect2(right-1,-16,3,32),dark)
		draw_rect(Rect2(left-3,-18,right-left+6,4),light)
		draw_rect(Rect2(left-3,14,right-left+6,4),dark)
		draw_rect(Rect2(-5,-6,10,8),Color("#263e4d"))
		draw_rect(Rect2(-3,-5,6,2),Color("#e4b45f"))
		for y in [-13.0,13.0]:
			draw_circle(Vector2(-8,y),1.2,Color("#d8dddb"))
			draw_circle(Vector2(8,y),1.2,Color("#d8dddb"))
	if kind == "cargo_pod":
		draw_rect(Rect2(-7,-8,14,14),Color("#273f51"))
		draw_line(Vector2(0,-7),Vector2(0,4),Color("#70bac4"),1.2,true)

func _draw_flat_part(kind: String, shape: String, shell: Color, light: Color, dark: Color) -> void:
	if kind == "wing" or kind == "tail_fin":
		var points := PackedVector2Array([Vector2(-24,-5),Vector2(-5,-10),Vector2(20,-19),Vector2(14,1),Vector2(-4,10),Vector2(-24,6)])
		if shape == "delta": points = PackedVector2Array([Vector2(-24,-5),Vector2(22,-19),Vector2(11,0),Vector2(22,19),Vector2(-24,5)])
		elif shape == "forward_swept": points = PackedVector2Array([Vector2(-24,-5),Vector2(-5,-10),Vector2(22,15),Vector2(12,1),Vector2(-4,10),Vector2(-24,6)])
		elif shape == "stub": points = PackedVector2Array([Vector2(-22,-7),Vector2(12,-12),Vector2(19,0),Vector2(12,12),Vector2(-22,7)])
		_draw_poly(points,shell,light)
		draw_line(Vector2(-18,0),Vector2(16,0),dark,1.2,true)
		draw_line(Vector2(-6,-7),Vector2(-6,7),Color("#d0a454"),1.0,true)
		return
	if kind == "panel" or kind == "radiator":
		draw_rect(Rect2(-21,-15,42,30),dark)
		draw_rect(Rect2(-19,-13,38,26),shell)
		for x in [-12.0,-4.0,4.0,12.0]: draw_line(Vector2(x,-12),Vector2(x,12),Color("#99d2df"),1.0,true)
		for y in [-5.0,5.0]: draw_line(Vector2(-18,y),Vector2(18,y),Color("#89b9ce"),0.8,true)
		draw_line(Vector2(-24,0),Vector2(24,0),Color("#d6ae5b"),1.5,true)
		return
	if kind == "plate":
		_draw_poly([Vector2(-17,-19),Vector2(17,-19),Vector2(21,-13),Vector2(21,13),Vector2(17,19),Vector2(-17,19),Vector2(-21,13),Vector2(-21,-13)],shell,light)
		draw_circle(Vector2(-13,-12),1.5,Color("#f1c16a"))
		draw_circle(Vector2(13,-12),1.5,Color("#f1c16a"))
		draw_circle(Vector2(-13,12),1.5,Color("#f1c16a"))
		draw_circle(Vector2(13,12),1.5,Color("#f1c16a"))
		draw_circle(Vector2.ZERO,7.0,dark)

func _draw_frame_part(kind: String, shell: Color, light: Color, dark: Color) -> void:
	if kind == "antenna":
		draw_line(Vector2(0,20),Vector2(0,-9),light,2.0,true)
		draw_arc(Vector2(0,-8),17.0,PI*1.18,PI*1.82,20,shell,3.0,true)
		draw_circle(Vector2(0,-9),2.5,Color("#e4bd68"))
		draw_line(Vector2(0,20),Vector2(-9,22),dark,1.5,true)
		draw_line(Vector2(0,20),Vector2(9,22),dark,1.5,true)
		return
	if kind == "boom":
		draw_line(Vector2(-20,14),Vector2(17,-13),shell,3.0,true)
		draw_line(Vector2(-20,14),Vector2(-24,21),Color("#d6ad59"),2.0,true)
		draw_rect(Rect2(12,-20,12,12),light)
		draw_circle(Vector2(18,-14),3.0,Color("#47cada"))
		return
	if kind == "truss":
		draw_line(Vector2(-18,-18),Vector2(-18,18),light,2.4,true)
		draw_line(Vector2(18,-18),Vector2(18,18),light,2.4,true)
		for y in [-15.0,0.0,15.0]: draw_line(Vector2(-18,y),Vector2(18,y),shell,1.6,true)
		draw_line(Vector2(-18,-15),Vector2(18,0),dark,1.4,true)
		draw_line(Vector2(18,-15),Vector2(-18,0),dark,1.4,true)
		draw_line(Vector2(-18,0),Vector2(18,15),dark,1.4,true)
		draw_line(Vector2(18,0),Vector2(-18,15),dark,1.4,true)
		return
	if kind == "decoupler_radial":
		draw_rect(Rect2(-17,-16,24,32),shell)
		draw_rect(Rect2(-20,-11,7,22),Color("#d5a452"))
		draw_line(Vector2(-13,-8),Vector2(8,8),light,2.0,true)
		draw_line(Vector2(-13,8),Vector2(8,-8),light,2.0,true)
		draw_circle(Vector2(12,0),4.0,Color("#ea9c4b"))
		return
	if kind == "crossfeed":
		draw_rect(Rect2(-18,-8,36,16),shell)
		draw_rect(Rect2(-4,-16,8,32),light)
		draw_circle(Vector2(-17,0),4.0,dark)
		draw_circle(Vector2(17,0),4.0,dark)
		draw_line(Vector2(-13,0),Vector2(13,0),Color("#d4a84f"),1.6,true)
		return
	if kind == "landing_legs":
		draw_rect(Rect2(-5,-7,10,17),shell)
		draw_line(Vector2(-4,5),Vector2(-19,20),light,3.0,true)
		draw_line(Vector2(4,5),Vector2(19,20),light,3.0,true)
		draw_line(Vector2(-22,20),Vector2(-14,20),Color("#d7b55f"),2.0,true)
		draw_line(Vector2(14,20),Vector2(22,20),Color("#d7b55f"),2.0,true)
		return
	# A compact four-way thruster cluster.
	_draw_poly([Vector2(-11,-19),Vector2(11,-19),Vector2(15,-14),Vector2(15,14),Vector2(11,19),Vector2(-11,19),Vector2(-15,14),Vector2(-15,-14)],shell,light)
	for p in [Vector2(-8,-13),Vector2(8,-13),Vector2(-8,13),Vector2(8,13)]:
		draw_circle(p,3.5,dark)
		draw_circle(p,1.8,Color("#67d5e6"))

func _draw_engine(kind: String, shell: Color, light: Color, dark: Color) -> void:
	var top_width := 9.0 if kind != "booster_engine" else 12.0
	var nozzle_width := 18.0 if kind != "booster_engine" else 21.0
	_draw_poly([Vector2(-top_width,-19),Vector2(top_width,-19),Vector2(top_width*0.82,2),Vector2(-top_width*0.82,2)],shell,light)
	_draw_poly([Vector2(-top_width*0.8,0),Vector2(top_width*0.8,0),Vector2(nozzle_width,19),Vector2(-nozzle_width,19)],dark,light)
	draw_arc(Vector2(0,17),nozzle_width-2.0,0.0,PI,24,Color("#cf8b51"),1.5,true)
	draw_line(Vector2(-top_width,-12),Vector2(top_width,-12),Color("#d9b366"),1.5,true)
	if kind == "ion":
		draw_circle(Vector2(0,9),4.5,Color("#14283a"))
		draw_circle(Vector2(0,9),2.0,Color("#57dce9"))
	else:
		draw_circle(Vector2(0,-5),2.0,Color("#162d3b"))

func _draw_box_hull(shell: Color, light: Color, dark: Color) -> void:
	_draw_poly([Vector2(-15,-20),Vector2(13,-20),Vector2(19,-14),Vector2(19,15),Vector2(13,21),Vector2(-15,21),Vector2(-20,15),Vector2(-20,-14)],shell,light)
	draw_line(Vector2(-14,-14),Vector2(14,-14),light,1.5,true)
	draw_line(Vector2(-14,14),Vector2(14,14),dark,1.5,true)
	draw_rect(Rect2(-7,-6,14,12),Color("#2a4654"))
	draw_line(Vector2(0,-5),Vector2(0,5),Color("#d4a957"),1.2,true)
	for p in [Vector2(-15,-16),Vector2(15,-16),Vector2(-15,16),Vector2(15,16)]: draw_circle(p,1.2,Color("#e7c272"))

func _draw_poly(points: PackedVector2Array, fill: Color, edge: Color) -> void:
	draw_colored_polygon(points,fill)
	for index in range(points.size()):
		draw_line(points[index],points[(index+1)%points.size()],edge,1.2,true)

func _draw_ellipse(center: Vector2, radii: Vector2, fill: Color) -> void:
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points,fill)
