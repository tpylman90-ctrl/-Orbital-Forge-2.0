extends Control
class_name OFMissionControl

signal close_requested
signal launch_requested
signal space_dock_requested
signal guidance_changed(enabled: bool)

var career: OFCareerProgress
var mission_status: Label
var mission_objective: Label
var mission_heading: Label
var ladder: Label
var tips_toggle: CheckButton
var dock_button: Button

func _ready() -> void:
	_build()

func configure(progress: OFCareerProgress) -> void:
	career = progress
	if is_node_ready(): _refresh()

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.04,0.07,0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var card := PanelContainer.new()
	card.anchor_left = 0.08
	card.anchor_top = 0.08
	card.anchor_right = 0.92
	card.anchor_bottom = 0.92
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0d1e2d")
	style.border_color = Color("#39637a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel",style)
	add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	card.add_child(content)
	var top := HBoxContainer.new()
	content.add_child(top)
	var heading := Label.new()
	heading.text = "MISSION CONTROL  /  SPACE FLIGHT SCHOOL"
	heading.add_theme_font_size_override("font_size",20)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	var close := Button.new()
	close.text = "CLOSE"
	close.pressed.connect(func(): close_requested.emit())
	top.add_child(close)
	var sandbox := Label.new()
	sandbox.text = "Campaign parts unlock as your program grows. SANDBOX remains open with the full catalog at any time."
	sandbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sandbox.add_theme_color_override("font_color",Color("#9fc2d4"))
	content.add_child(sandbox)
	var mission_title := Label.new()
	mission_title.text = "MISSION 01  /  SPACE & RETURN"
	mission_title.add_theme_font_size_override("font_size",17)
	mission_title.add_theme_color_override("font_color",Color("#f0c879"))
	content.add_child(mission_title)
	var objective := Label.new()
	objective.text = "Build a starter vehicle, reach 100 km, return through the atmosphere, and land safely. Once mastered, progress to orbit, satellites, heavy payloads, and a station."
	mission_heading = mission_title
	mission_objective = objective
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(objective)
	mission_status = Label.new()
	mission_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_status.add_theme_color_override("font_color",Color("#8fe0b0"))
	content.add_child(mission_status)
	ladder = Label.new()
	ladder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ladder.add_theme_color_override("font_color",Color("#b4c7d2"))
	content.add_child(ladder)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	tips_toggle = CheckButton.new()
	tips_toggle.text = "Show brief flight tips"
	tips_toggle.toggled.connect(func(enabled: bool):
		guidance_changed.emit(enabled)
	)
	content.add_child(tips_toggle)
	var bottom := HBoxContainer.new()
	content.add_child(bottom)
	var launch := Button.new()
	launch.text = "OPEN LAUNCH PAD"
	launch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	launch.custom_minimum_size.y = 44
	launch.pressed.connect(func(): launch_requested.emit())
	bottom.add_child(launch)
	dock_button = Button.new()
	dock_button.text = "OPEN SPACE DOCK"
	dock_button.visible = false
	dock_button.pressed.connect(func(): space_dock_requested.emit())
	bottom.add_child(dock_button)
	_refresh()

func _refresh() -> void:
	if mission_status == null: return
	if career == null: return
	mission_heading.text = career.mission_title()
	mission_objective.text = career.mission_objective()
	mission_status.text = career.mission_status()
	ladder.text = career.mission_board_text()
	if tips_toggle != null: tips_toggle.set_pressed_no_signal(career.flight_tips_enabled)
	if dock_button != null: dock_button.visible = career.station_constructed
