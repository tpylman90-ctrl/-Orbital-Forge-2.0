extends SceneTree

const MissionControl = preload("res://scripts/ui/mission_control.gd")
const CareerProgress = preload("res://scripts/core/career_progress.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = MissionControl.new()
	root.add_child(screen)
	await process_frame
	var career = CareerProgress.new()
	career.save_path = "user://mission_control_smoke.json"
	career.set_tips_enabled(false)
	screen.configure(career)
	if not screen.mission_heading.text.contains("SPACE & RETURN") or not screen.mission_status.text.contains("PENDING") or screen.tips_toggle.button_pressed or screen.dock_button.visible:
		push_error("Mission Control should clearly show the first recovery mission and keep Space Dock locked")
		quit(1)
		return
	var launches := [false]
	screen.launch_requested.connect(func(): launches[0] = true)
	for node in screen.find_children("*","Button",true,false):
		if node is Button and node.text == "OPEN LAUNCH PAD": node.pressed.emit()
	if not launches[0]:
		push_error("Mission Control launch action must open the launch pad without igniting engines")
		quit(1)
		return
	print("MISSION_CONTROL_SMOKE_PASS: mission status, guidance toggle and pad action")
	quit(0)
