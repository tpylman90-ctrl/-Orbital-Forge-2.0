extends Control
class_name OFFlightSteeringPad
signal steering_changed(value: float)

var active := false
var axis := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(156,156)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active = true
			_update_axis(event.position)
			accept_event()
		else:
			active = false
			_set_axis(0.0)
			accept_event()
	elif event is InputEventScreenDrag and active:
		_update_axis(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		active = event.pressed
		_update_axis(event.position if active else size * 0.5)
		accept_event()
	elif event is InputEventMouseMotion and active:
		_update_axis(event.position)
		accept_event()

func _update_axis(pointer: Vector2) -> void:
	var center := size * 0.5
	var radius := minf(size.x,size.y)*0.36
	_set_axis(clampf((pointer.x-center.x)/maxf(radius,1.0),-1.0,1.0))

func _set_axis(value: float) -> void:
	axis = value
	steering_changed.emit(axis)
	queue_redraw()

func _draw() -> void:
	var center := size*0.5
	var radius := minf(size.x,size.y)*0.38
	draw_circle(center, radius+18.0, Color(0.025,0.055,0.085,0.78))
	draw_circle(center, radius+4.0, Color(0.19,0.34,0.43,0.9),false,2.0)
	draw_circle(center, radius*0.64, Color(0.14,0.24,0.31,0.85),false,1.5)
	draw_line(Vector2(center.x-radius,center.y),Vector2(center.x+radius,center.y),Color(0.34,0.52,0.59,0.75),1.5)
	var knob := center+Vector2(axis*radius*0.8,0)
	draw_circle(knob,19.0,Color(0.12,0.58,0.78,0.96))
	draw_circle(knob,19.0,Color(0.55,0.83,0.91,0.95),false,2.0)
	draw_string(ThemeDB.fallback_font,Vector2(center.x-34, size.y-4),"STEER",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#d4e8f0"))
