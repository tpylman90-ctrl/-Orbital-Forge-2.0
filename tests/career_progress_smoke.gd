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
	if career.campaign_step() != 0 or career.orbit_reached or career.is_part_unlocked("engine_ion") or not career.is_part_unlocked("parachute"):
		push_error("Career should begin with a small recovery-ready inventory and deep-space parts locked")
		quit(1)
		return
	if career.mark_orbit_reached() or not career.complete_space_return() or career.complete_space_return() or not career.is_part_unlocked("capsule"):
		push_error("Safe return should unlock mission two exactly once")
		quit(1)
		return
	if not career.mark_orbit_reached() or career.mark_orbit_reached() or not career.is_part_unlocked("probe_core"):
		push_error("Orbit should unlock orbital payload hardware only after the return milestone")
		quit(1)
		return
	career.record_satellite_delivery()
	career.record_heavy_payload_delivery()
	career.record_heavy_payload_delivery()
	if career.campaign_step() != 4 or not career.is_part_unlocked("ring") or not career.complete_station() or career.campaign_step() != 5 or career.is_part_unlocked("engine_ion") or not career.is_part_unlocked("engine_ion",true):
		push_error("Payload delivery and station assembly milestones should unlock in order")
		quit(1)
		return
	career.set_tips_enabled(false)
	var reloaded = CareerProgress.new()
	reloaded.load_state(save_path)
	if not reloaded.station_constructed or reloaded.campaign_step() != 5 or reloaded.flight_tips_enabled:
		push_error("Career progress and guidance preference must persist")
		quit(1)
		return
	DirAccess.remove_absolute(absolute_path)
	print("CAREER_PROGRESS_SMOKE_PASS: mission ladder, unlocks, station, and optional guidance persist")
	quit(0)
