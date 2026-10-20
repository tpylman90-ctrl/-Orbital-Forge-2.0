extends RefCounted
class_name OFCareerProgress

const DEFAULT_SAVE_PATH := "user://orbital_forge_progress.json"

var save_path := DEFAULT_SAVE_PATH
var orbit_reached := false
var flight_tips_enabled := true

func load_state(path_override: String = "") -> void:
	if not path_override.is_empty(): save_path = path_override
	if not FileAccess.file_exists(save_path): return
	var file := FileAccess.open(save_path,FileAccess.READ)
	if file == null: return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		orbit_reached = bool(parsed.get("orbit_reached",false))
		flight_tips_enabled = bool(parsed.get("flight_tips_enabled",true))

func save_state() -> bool:
	var file := FileAccess.open(save_path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"version":1,"orbit_reached":orbit_reached,"flight_tips_enabled":flight_tips_enabled},"  "))
	return true

func mark_orbit_reached() -> bool:
	if orbit_reached: return false
	orbit_reached = true
	save_state()
	return true

func set_tips_enabled(enabled: bool) -> void:
	flight_tips_enabled = enabled
	save_state()

func flight_tip(flight) -> String:
	if not flight_tips_enabled or flight == null or not flight.launched: return ""
	if flight.is_in_orbit(): return "ORBIT ACHIEVED · station and shipyard unlocked"
	if flight.altitude < 10000.0: return "Climb steadily through thick air; ease into the turn after clearing the pad."
	if flight.altitude < 80000.0: return "Turn gradually east to build sideways speed for orbit."
	return "Altitude alone is not orbit; build horizontal speed toward circular velocity."
