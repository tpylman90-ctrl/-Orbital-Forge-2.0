extends SceneTree

const MissionControl = preload("res://scripts/ui/mission_control.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen = MissionControl.new()
	root.add_child(screen)
	await process_frame
	screen.configure(true,false)
	if not screen.mission_status.text.contains("unlocked") or screen.tips_toggle.button_pressed:
		push_error("Mission Control should show persistent orbit rewards and the stored tips preference")
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
