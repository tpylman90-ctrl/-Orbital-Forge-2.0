extends SceneTree

const CareerProgress = preload("res://scripts/core/career_progress.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var save_path := "user://career_progress_smoke.json"
	var absolute_path := ProjectSettings.globalize_path(save_path)
	DirAccess.remove_absolute(absolute_path)
	var career = CareerProgress.new()
	career.load_state(save_path)
	if career.orbit_reached or not career.flight_tips_enabled:
		push_error("Career must start with the first orbit locked and guidance enabled")
		quit(1)
		return
	if not career.mark_orbit_reached() or career.mark_orbit_reached():
		push_error("Orbit reward must unlock exactly once")
		quit(1)
		return
	career.set_tips_enabled(false)
	var reloaded = CareerProgress.new()
	reloaded.load_state(save_path)
	if not reloaded.orbit_reached or reloaded.flight_tips_enabled:
		push_error("Career progress and guidance preference must persist")
		quit(1)
		return
	DirAccess.remove_absolute(absolute_path)
	print("CAREER_PROGRESS_SMOKE_PASS: orbit reward and optional guidance persist")
	quit(0)
