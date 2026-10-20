extends Control
class_name OFTrajectoryMap

const Flight = preload("res://scripts/core/launch_physics.gd")
const EARTH_RADIUS := Flight.R

var flight: OFLaunchPhysics
var forecast := PackedVector2Array()
var history := PackedVector2Array()
var last_forecast_ms := 0
var last_history_time := -INF
var detail_rng := RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_rng.seed = 279113

func observe_flight(current_flight: OFLaunchPhysics) -> void:
	flight = current_flight
	if flight == null:
		return
	if history.is_empty() or flight.time_s-last_history_time >= 1.0:
		history.append(Vector2(flight.downrange,flight.altitude))
		last_history_time = flight.time_s
		if history.size() > 1800:
			history.remove_at(0)
	if visible and Time.get_ticks_msec()-last_forecast_ms >= 900:
		_rebuild_forecast()
	queue_redraw()

func set_flight(current_flight: OFLaunchPhysics) -> void:
	flight = current_flight
	if flight == null:
		forecast.clear()
		history.clear()
		last_history_time = -INF
	else:
		if history.is_empty():
			history.append(Vector2(flight.downrange,flight.altitude))
		_rebuild_forecast()
	queue_redraw()

func _rebuild_forecast() -> void:
	if flight == null:
		forecast.clear()
		return
	forecast = flight.preview_trajectory(300.0,3.0)
	last_forecast_ms = Time.get_ticks_msec()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO,size)
	draw_rect(bounds,Color("#050b14"))
	_draw_starfield()
	if flight == null:
		_draw_title("FLIGHT MAP  /  WAITING FOR TELEMETRY")
		return
	var extent := _max_extent()
	var frame_radius := minf(size.x*0.42,size.y*0.36)
	var scale_px := frame_radius/maxf(extent,EARTH_RADIUS)
	var center := Vector2(size.x*0.5,size.y*0.55)
	_draw_planet(center,scale_px)
	_draw_path(history,center,scale_px,Color("#4d9db8"),2.2)
	_draw_path(forecast,center,scale_px,Color("#5ce2ff"),2.4)
	_draw_current_marker(center,scale_px)
	_draw_title("LIVE TRAJECTORY  /  EARTH FRAME")
	_draw_telemetry()

func _draw_starfield() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91107
	for i in range(112):
		var p := Vector2(rng.randf()*size.x,rng.randf()*size.y)
		var radius := rng.randf_range(0.55,1.5)
		var alpha := rng.randf_range(0.18,0.7)
		draw_circle(p,radius,Color(0.58,0.76,0.92,alpha))

func _max_extent() -> float:
	var value := EARTH_RADIUS*1.04
	for point in forecast:
		value = maxf(value,EARTH_RADIUS+maxf(point.y,0.0))
	for point in history:
		value = maxf(value,EARTH_RADIUS+maxf(point.y,0.0))
	return value

func _project(point: Vector2, center: Vector2, scale_px: float) -> Vector2:
	var angle := point.x/EARTH_RADIUS
	var radius := EARTH_RADIUS+maxf(point.y,-EARTH_RADIUS+1000.0)
	return center+Vector2(sin(angle),-cos(angle))*radius*scale_px

func _draw_planet(center: Vector2, scale_px: float) -> void:
	var radius := EARTH_RADIUS*scale_px
	if radius < 1.0:
		return
	draw_circle(center,radius*1.15,Color(0.12,0.47,0.79,0.08))
	draw_circle(center,radius*1.08,Color(0.12,0.48,0.82,0.12))
	draw_circle(center,radius*1.025,Color("#35a9e7"))
	draw_circle(center,radius,Color("#164b77"))
	# Stylized continent plates make the globe read clearly without obscuring orbit lines.
	var land := Color("#397b68")
	var light_land := Color("#5c9b78")
	_draw_landmass(center,scale_px,land,[Vector2(-0.55,-0.48),Vector2(-0.25,-0.62),Vector2(-0.08,-0.45),Vector2(-0.18,-0.18),Vector2(-0.42,-0.12),Vector2(-0.62,-0.28)])
	_draw_landmass(center,scale_px,light_land,[Vector2(0.06,-0.62),Vector2(0.36,-0.55),Vector2(0.62,-0.37),Vector2(0.53,-0.08),Vector2(0.28,0.02),Vector2(0.16,-0.17),Vector2(-0.02,-0.32)])
	_draw_landmass(center,scale_px,land,[Vector2(-0.22,0.05),Vector2(-0.02,0.12),Vector2(0.08,0.42),Vector2(-0.12,0.68),Vector2(-0.32,0.4),Vector2(-0.38,0.18)])
	_draw_landmass(center,scale_px,light_land,[Vector2(0.54,0.16),Vector2(0.72,0.23),Vector2(0.68,0.45),Vector2(0.47,0.39)])
	# Thin latitude/longitude marks give the globe a navigational, instrument-panel feel.
	for fraction in [-0.62,-0.32,0.32,0.62]:
		var chord := sqrt(maxf(0.0,1.0-fraction*fraction))*radius
		draw_arc(center+Vector2(0,fraction*radius),chord,PI,TAU,48,Color(0.56,0.77,0.86,0.15),1.0,true)
	for longitude in [-0.55,0.55]:
		var points := PackedVector2Array()
		for i in range(25):
			var t := -PI*0.5+PI*float(i)/24.0
			points.append(center+Vector2(sin(t)*radius*absf(longitude),cos(t)*radius))
		draw_polyline(points,Color(0.56,0.77,0.86,0.12),1.0,true)
	draw_arc(center,radius,0.0,TAU,96,Color("#69c9f0"),1.2,true)
	if radius > 13.0:
		var label_pos := center+Vector2(-radius*0.34,-radius*0.12)
		draw_string(get_theme_default_font(),label_pos,"EARTH",HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10,roundi(radius*0.17)),Color(0.82,0.93,0.96,0.84))

func _draw_landmass(center: Vector2, scale_px: float, tint: Color, shape: Array) -> void:
	var radius := EARTH_RADIUS*scale_px
	var polygon := PackedVector2Array()
	for point in shape:
		polygon.append(center+Vector2(point.x,point.y)*radius)
	draw_colored_polygon(polygon,tint)

func _draw_path(points: PackedVector2Array, center: Vector2, scale_px: float, tint: Color, width: float) -> void:
	if points.size() < 2:
		return
	var projected := PackedVector2Array()
	for point in points:
		projected.append(_project(point,center,scale_px))
	draw_polyline(projected,tint,width,true)
	for index in range(0,projected.size(),maxi(1,int(projected.size()/24))):
		draw_circle(projected[index],2.0,tint.lightened(0.18))

func _draw_current_marker(center: Vector2, scale_px: float) -> void:
	var point := _project(Vector2(flight.downrange,flight.altitude),center,scale_px)
	draw_circle(point,10.0,Color(1.0,0.68,0.22,0.12))
	draw_circle(point,5.2,Color("#ffd36a"))
	draw_arc(point,9.0,0.0,TAU,24,Color("#fff1c3"),1.5,true)
	draw_line(point+Vector2(-16,0),point+Vector2(-7,0),Color("#fff1c3"),1.2,true)
	draw_line(point+Vector2(7,0),point+Vector2(16,0),Color("#fff1c3"),1.2,true)
	draw_line(point+Vector2(0,-16),point+Vector2(0,-7),Color("#fff1c3"),1.2,true)
	draw_line(point+Vector2(0,7),point+Vector2(0,16),Color("#fff1c3"),1.2,true)

func _draw_title(title: String) -> void:
	var font := get_theme_default_font()
	draw_string(font,Vector2(18,30),title,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#c3dfec"))
	var line_y := 43.0
	draw_line(Vector2(18,line_y),Vector2(size.x-18,line_y),Color(0.23,0.53,0.66,0.42),1.0,true)

func _draw_telemetry() -> void:
	var font := get_theme_default_font()
	var size_px := 13
	var speed := Vector2(flight.vertical_speed,flight.horizontal_speed).length()
	var lines := [
		"CRAFT  %.1f km ALT  /  %.0f m/s" % [flight.altitude/1000.0,speed],
		"RANGE  %.1f km  /  PITCH  %+.0f°" % [flight.downrange/1000.0,flight.pitch_degrees],
		"FUEL  %.0f%%  /  %s" % [100.0*flight.fuel_kg/maxf(flight.initial_fuel_kg,1.0),flight.status],
		"CYAN  PREDICTED  ·  BLUE  FLIGHT PATH"
	]
	var x := 18.0
	var y := size.y-66.0
	for index in range(lines.size()):
		var tint := Color("#6de3ff") if index == 3 else Color("#d1e7f0")
		draw_string(font,Vector2(x,y+float(index)*17.0),lines[index],HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,tint)

