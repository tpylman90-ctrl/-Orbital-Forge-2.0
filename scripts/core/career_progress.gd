extends RefCounted
class_name OFCareerProgress

const DEFAULT_SAVE_PATH := "user://orbital_forge_progress.json"
const STARTER_PARTS := ["command_pod","engine","fuel_tank","tank_short","nose_cone","heat_shield","parachute","service_module"]
const RETURN_UNLOCKS := ["capsule","crew_capsule_mk2","tank_long","engine_heavy","engine_vac","decoupler","landing_legs","fairing","rcs_block"]
const ORBIT_UNLOCKS := ["probe_core","solar_panel","payload_bay","docking_port","tank_wide","cryo_tank","fuel_crossfeed","comms_dish","deployable_boom"]
const HEAVY_UNLOCKS := ["cargo_pod","lander_stage","spherical_tank","conformal_tank","rectangular_tank","truss","truss_short","plate","radiator_panel"]
const STATION_UNLOCKS := ["ring","gravity_ring","engine_plate","radial_decoupler","separator_tube","crew_capsule_mk2"]
const DEEP_SPACE_PARTS := ["command_pod","capsule","crew_capsule_mk2","probe_core","cockpit_canopy","cockpit_bubble","orbital_fuselage","cargo_fuselage","service_module","cargo_pod","tank_long","tank_wide","cryo_tank","spherical_tank","conformal_tank","rectangular_tank","engine_vac","engine_ion","engine_plasma","thruster","solar_panel","radiator_panel","comms_dish","deployable_boom","rcs_block","truss","truss_short","plate","ring","gravity_ring","docking_port","payload_bay","fuel_crossfeed"]

var save_path := DEFAULT_SAVE_PATH
var space_return_complete := false
var orbit_reached := false
var satellites_delivered := 0
var heavy_payloads_delivered := 0
var station_constructed := false
var sandbox_mode := false
var flight_tips_enabled := true

func load_state(path_override: String = "") -> void:
	if not path_override.is_empty(): save_path = path_override
	if not FileAccess.file_exists(save_path): return
	var file := FileAccess.open(save_path,FileAccess.READ)
	if file == null: return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return
	space_return_complete = bool(parsed.get("space_return_complete",bool(parsed.get("orbit_reached",false))))
	# Migrate the previous prototype's orbit flag to its closest new milestone.
	orbit_reached = bool(parsed.get("orbit_reached",false))
	satellites_delivered = maxi(0,int(parsed.get("satellites_delivered",0)))
	heavy_payloads_delivered = maxi(0,int(parsed.get("heavy_payloads_delivered",0)))
	station_constructed = bool(parsed.get("station_constructed",false))
	sandbox_mode = bool(parsed.get("sandbox_mode",false))
	flight_tips_enabled = bool(parsed.get("flight_tips_enabled",true))

func save_state() -> bool:
	var file := FileAccess.open(save_path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({
		"version":2,
		"space_return_complete":space_return_complete,
		"orbit_reached":orbit_reached,
		"satellites_delivered":satellites_delivered,
		"heavy_payloads_delivered":heavy_payloads_delivered,
		"station_constructed":station_constructed,
		"sandbox_mode":sandbox_mode,
		"flight_tips_enabled":flight_tips_enabled
	},"  "))
	return true

func complete_space_return() -> bool:
	if space_return_complete: return false
	space_return_complete = true
	save_state()
	return true

func mark_orbit_reached() -> bool:
	if not space_return_complete or orbit_reached: return false
	orbit_reached = true
	save_state()
	return true

func record_satellite_delivery() -> void:
	if not orbit_reached: return
	satellites_delivered += 1
	save_state()

func record_heavy_payload_delivery() -> void:
	if satellites_delivered < 1: return
	heavy_payloads_delivered += 1
	save_state()

func complete_station() -> bool:
	if heavy_payloads_delivered < 2 or station_constructed: return false
	station_constructed = true
	save_state()
	return true

func set_sandbox_mode(enabled: bool) -> void:
	sandbox_mode = enabled
	save_state()

func set_tips_enabled(enabled: bool) -> void:
	flight_tips_enabled = enabled
	save_state()

func campaign_step() -> int:
	if not space_return_complete: return 0
	if not orbit_reached: return 1
	if satellites_delivered < 1: return 2
	if heavy_payloads_delivered < 2: return 3
	if not station_constructed: return 4
	return 5

func is_part_unlocked(part_id: String, in_space_dock: bool = false) -> bool:
	if sandbox_mode: return true
	if in_space_dock: return station_constructed and DEEP_SPACE_PARTS.has(part_id)
	if STARTER_PARTS.has(part_id): return true
	if space_return_complete and RETURN_UNLOCKS.has(part_id): return true
	if orbit_reached and ORBIT_UNLOCKS.has(part_id): return true
	if satellites_delivered >= 1 and HEAVY_UNLOCKS.has(part_id): return true
	if heavy_payloads_delivered >= 2 and STATION_UNLOCKS.has(part_id): return true
	return false

func flight_tip(flight) -> String:
	if not flight_tips_enabled or flight == null or not flight.launched: return ""
	match campaign_step():
		0:
			if flight.altitude < 100000.0: return "First flight: climb above 100 km, then plan a controlled return."
			if flight.altitude > 15000.0: return "Space reached. Cut thrust, turn for descent, and manage speed before the lower atmosphere."
			return "Below 15 km: deploy the parachute when airspeed is under 500 m/s; aim for a soft touchdown."
		1:
			if flight.altitude < 10000.0: return "Build altitude first; begin a gentle eastward turn as the air thins."
			return "Orbit needs sideways speed. Ease toward 7.8 km/s instead of climbing straight up."
		2:
			return "Reach orbit, then release the staged probe and solar array to commission a satellite."
		3:
			return "Deliver two heavier payloads from orbit to prepare the station assembly."
		4:
			return "Assemble a station module with a truss, docking port, ring, and solar array before release."
		_:
			return "Space Dock unlocked. Long-range craft need efficient engines, power, and careful transfer burns."

func mission_board_text() -> String:
	var lines := [
		_mission_line(0,"SPACE & RETURN","Cross 100 km and recover safely",space_return_complete),
		_mission_line(1,"ESTABLISH ORBIT","Build sideways speed and reach low orbit",orbit_reached),
		_mission_line(2,"FIRST SATELLITE","Deploy a probe core with a solar array",satellites_delivered >= 1),
		_mission_line(3,"HEAVY PAYLOADS","Deliver two larger payloads from orbit",heavy_payloads_delivered >= 2),
		_mission_line(4,"BUILD THE STATION","Deploy a truss, ring, docking port, and array",station_constructed),
		("▶ SPACE DOCK · Long-range ship construction unlocked" if station_constructed else "🔒 SPACE DOCK · Unlocks after station assembly")
	]
	return "\n".join(lines)

func mission_title() -> String:
	return ["MISSION 01  /  SPACE & RETURN","MISSION 02  /  ESTABLISH ORBIT","MISSION 03  /  FIRST SATELLITE","MISSION 04  /  HEAVY PAYLOADS","MISSION 05  /  BUILD THE STATION","SPACE DOCK  /  LONG-RANGE MISSIONS"][campaign_step()]

func mission_objective() -> String:
	return [
		"Build with the starter inventory. Pass 100 km altitude, return through the atmosphere, and land safely to complete the first flight.",
		"Now reach low orbit: build horizontal velocity until the craft can keep circling instead of falling back to Earth.",
		"Fit a probe core and solar array above a staged payload bay. Reach orbit and activate the stage to deploy your first satellite.",
		"Deliver two heavy orbital payloads. Use cargo, lander, or service modules and plan the launch vehicle around their mass.",
		"Build a station assembly from a truss, orbital ring, docking port, and solar array. Deploy the connected module in orbit.",
		"Build long-range spacecraft in the Space Dock. Plan efficient propulsion, power, and payload capacity for deep-space transfers."
	][campaign_step()]

func mission_status() -> String:
	return "RECOVERIES · %s   ORBIT · %s\nSATELLITES · %d / 1   HEAVY PAYLOADS · %d / 2" % ["COMPLETE" if space_return_complete else "PENDING","COMPLETE" if orbit_reached else "PENDING",satellites_delivered,mini(heavy_payloads_delivered,2)]

func _mission_line(index: int, title: String, detail: String, complete: bool) -> String:
	var marker := "✓" if complete else "▶" if campaign_step() == index else "🔒"
	return "%s  %s · %s" % [marker,title,detail]
