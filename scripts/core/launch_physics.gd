extends RefCounted
class_name OFLaunchPhysics
# SI units, 2D local vertical/horizontal trajectory with spherical Earth gravity.
const R := 6371000.0
const MU := 3.986004418e14
const RHO0 := 1.225
const SCALE_HEIGHT := 8500.0
const G0 := 9.80665
const EARTH_ROTATION_RAD_S := 7.2921159e-5
const LAUNCH_LATITUDE_DEG := 28.5
const ATMOSPHERE_FADE_ALTITUDE := 180000.0
# Gameplay-scaled dry masses, propellant loads and engine ratings in SI units.
# Fictional drives are intentionally low-thrust at sea level and optimized for space.
const RATINGS := {
 "command_pod":[850.0,0.0,0.0,0.0], "capsule":[1200.0,0.0,0.0,0.0],
 "fuel_tank":[170.0,1100.0,0.0,0.0], "tank_short":[100.0,540.0,0.0,0.0],
 "tank_long":[240.0,1650.0,0.0,0.0], "tank_wide":[420.0,2800.0,0.0,0.0],
 "cryo_tank":[230.0,1400.0,0.0,0.0],
 "spherical_tank":[190.0,1050.0,0.0,0.0], "conformal_tank":[155.0,780.0,0.0,0.0],
 "rectangular_tank":[220.0,1250.0,0.0,0.0],
 "engine":[330.0,0.0,90000.0,285.0], "engine_heavy":[770.0,0.0,320000.0,290.0],
 "engine_vac":[250.0,0.0,60000.0,355.0], "thruster":[80.0,0.0,8500.0,315.0],
 "engine_ion":[140.0,0.0,250.0,2400.0], "engine_plasma":[420.0,0.0,16000.0,800.0],
 "solid_booster":[520.0,3600.0,0.0,0.0], "booster_nozzle":[310.0,0.0,480000.0,270.0],
 "nose_cone":[85.0,0.0,0.0,0.0], "crew_capsule_mk2":[1320.0,0.0,0.0,0.0],
 "lander_stage":[380.0,1250.0,0.0,0.0], "landing_legs":[95.0,0.0,0.0,0.0],
 "rcs_block":[28.0,0.0,0.0,0.0], "service_module":[190.0,620.0,0.0,0.0],
 "heat_shield":[145.0,0.0,0.0,0.0], "cargo_pod":[260.0,0.0,0.0,0.0],
 "radiator_panel":[36.0,0.0,0.0,0.0], "comms_dish":[22.0,0.0,0.0,0.0],
 "deployable_boom":[18.0,0.0,0.0,0.0], "fuel_crossfeed":[42.0,0.0,0.0,0.0]
}

var altitude := 0.0
var downrange := 0.0
var vertical_speed := 0.0
var pitch_degrees := 0.0
var steering_input := 0.0
var horizontal_speed := 0.0
var fuel_kg := 0.0
var initial_fuel_kg := 0.0
var dry_kg := 0.0
var thrust_n := 0.0
var isp_s := 300.0
var area_m2 := 1.0
var wing_area_m2 := 0.0
var cd := 0.5
var dynamic_pressure_pa := 0.0
var max_q_pa := 0.0
var max_q_altitude_m := 0.0
var g_load := 0.0
var actual_thrust_n := 0.0
var lift_n := 0.0
var time_s := 0.0
var throttle := 1.0
var launched := false
var status := "READY"
var tank_fuel: Dictionary = {}
var engine_specs: Array[Dictionary] = []
var strict_fuel_routes := false

func configure(craft: Dictionary, catalog: Dictionary) -> void:
 altitude = 0.0
 downrange = 0.0
 vertical_speed = 0.0
 horizontal_speed = 0.0
 pitch_degrees = 0.0
 steering_input = 0.0
 time_s = 0.0
 launched = false
 dry_kg = 0.0
 fuel_kg = 0.0
 initial_fuel_kg = 0.0
 thrust_n = 0.0
 actual_thrust_n = 0.0
 lift_n = 0.0
 wing_area_m2 = 0.0
 dynamic_pressure_pa = 0.0
 max_q_pa = 0.0
 max_q_altitude_m = 0.0
 g_load = 0.0
 tank_fuel.clear()
 engine_specs.clear()
 area_m2 = 0.4
 var routes: Dictionary = craft.get("fuel_routes",{})
 strict_fuel_routes = bool(craft.get("fuel_routing_enabled",not routes.is_empty()))
 for part in craft.get("parts",[]):
  var uid := str(part.get("uid",""))
  var spec: Dictionary = catalog.get(str(part.get("type","")),{})
  var kind: String = str(spec.get("kind",""))
  var scale_factor: float = float(part.get("scale",1.0))
  var volume: float = scale_factor*scale_factor*scale_factor
  var radius: float = float(spec.get("radius",0.5))*scale_factor
  area_m2 = maxf(area_m2,PI*radius*radius)
  if kind == "wing":
   # Catalog wings model a left/right pair; the mesh span is twice radius.
   wing_area_m2 += 2.0*radius*float(spec.get("length",1.0))*scale_factor
  var ratings: Array = RATINGS.get(str(part.get("type","")),[95.0,0.0,0.0,0.0])
  dry_kg += float(ratings[0])*volume
  if float(ratings[1]) > 0.0:
   tank_fuel[uid] = float(ratings[1])*volume
  if float(ratings[2]) > 0.0:
   var engine_type := str(part.get("type",""))
   engine_specs.append({"uid":uid,"thrust":float(ratings[2])*volume,"isp":float(ratings[3]),"tanks":[],"spool":0.0,"vacuum_optimized":engine_type in ["engine_vac","engine_ion","engine_plasma"]})
 var all_tanks: Array = tank_fuel.keys()
 var accessible_tanks: Dictionary = {}
 var weighted_isp := 0.0
 for engine in engine_specs:
  var assigned: Array = []
  if strict_fuel_routes:
   for tank_uid in routes.get(str(engine["uid"]),[]):
    if tank_fuel.has(str(tank_uid)) and not assigned.has(str(tank_uid)):
     assigned.append(str(tank_uid))
  else:
   assigned = all_tanks.duplicate()
  engine["tanks"] = assigned
  if not assigned.is_empty():
   engine["enabled"] = true
   thrust_n += float(engine["thrust"])
   weighted_isp += float(engine["thrust"])*float(engine["isp"])
   for tank_uid in assigned: accessible_tanks[str(tank_uid)] = true
  else:
   engine["enabled"] = false
 for tank_uid in tank_fuel:
  if accessible_tanks.has(tank_uid): fuel_kg += float(tank_fuel[tank_uid])
  else: dry_kg += float(tank_fuel[tank_uid])
 initial_fuel_kg = fuel_kg
 if thrust_n > 0.0: isp_s = weighted_isp/thrust_n
 if thrust_n > 0.0 and fuel_kg > 0.0:
  status = "READY"
 elif strict_fuel_routes and not engine_specs.is_empty() and not tank_fuel.is_empty():
  status = "NEEDS FUEL CONNECTION"
 else:
  status = "NEEDS ENGINE AND FUEL"

func mass_kg() -> float:
 return dry_kg+fuel_kg

func gravity() -> float:
 return MU/pow(R+maxf(altitude,0.0),2.0)

func circular_orbit_speed() -> float:
 return sqrt(MU/(R+maxf(altitude,0.0)))

func is_in_orbit() -> bool:
 return altitude > 80000.0 and horizontal_speed >= circular_orbit_speed()*0.94

func density() -> float:
 if altitude >= ATMOSPHERE_FADE_ALTITUDE: return 0.0
 return RHO0*exp(-maxf(altitude,0.0)/SCALE_HEIGHT)

func atmospheric_tangential_speed() -> float:
 var fade := 1.0-clampf(maxf(altitude,0.0)/ATMOSPHERE_FADE_ALTITUDE,0.0,1.0)
 return EARTH_ROTATION_RAD_S*(R+maxf(altitude,0.0))*cos(deg_to_rad(LAUNCH_LATITUDE_DEG))*fade

func air_relative_speed() -> float:
 return Vector2(vertical_speed,horizontal_speed-atmospheric_tangential_speed()).length()

func twr() -> float:
 return actual_thrust_n/maxf(mass_kg()*gravity(),0.001) if launched else thrust_n*throttle/maxf(mass_kg()*gravity(),0.001)

func delta_v_estimate() -> float:
 if fuel_kg <= 0.0 or thrust_n <= 0.0 or dry_kg <= 0.0: return 0.0
 return isp_s*G0*log(maxf(mass_kg()/dry_kg,1.0))

func step(dt: float, max_substep_seconds: float = 0.02) -> void:
 if not launched or status in ["LANDED","IMPACT","NEEDS ENGINE AND FUEL"] or dt <= 0.0: return
 # Substeps prevent unstable mass and drag integration under mobile frame spikes.
 var count: int = maxi(1,int(ceil(dt/maxf(max_substep_seconds,0.005))))
 var h: float = dt/float(count)
 for n in range(count):
  pitch_degrees = clampf(pitch_degrees+steering_input*28.0*h,-82.0,82.0)
  var burn := 0.0
  var active_thrust := 0.0
  var q := 0.5*density()*air_relative_speed()*air_relative_speed()
  dynamic_pressure_pa = q
  if q > max_q_pa:
   max_q_pa = q
   max_q_altitude_m = altitude
  var pressure_ratio := clampf(exp(-maxf(altitude,0.0)/7200.0),0.0,1.0)
  if throttle >= 0.0:
   for engine in engine_specs:
    if not bool(engine.get("enabled",false)): continue
    var target_spool := clampf(throttle,0.0,1.0)
    var spool_tau := 0.42 if target_spool > float(engine.get("spool",0.0)) else 0.24
    engine["spool"] = lerpf(float(engine.get("spool",0.0)),target_spool,1.0-exp(-h/spool_tau))
    var pressure_factor := 1.0-pressure_ratio*(0.28 if bool(engine.get("vacuum_optimized",false)) else 0.22)
    var engine_thrust: float = float(engine["thrust"])*float(engine["spool"])*pressure_factor
    var requested: float = engine_thrust/(float(engine["isp"])*G0)*h
    var remaining := requested
    for tank_uid in engine["tanks"]:
     var available: float = float(tank_fuel.get(str(tank_uid),0.0))
     var used: float = minf(available,remaining)
     tank_fuel[str(tank_uid)] = available-used
     remaining -= used
     burn += used
     if remaining <= 0.000001: break
    if requested > 0.0:
     active_thrust += engine_thrust*clampf((requested-remaining)/requested,0.0,1.0)
  fuel_kg = 0.0
  for tank_uid in tank_fuel: fuel_kg += float(tank_fuel[tank_uid])
  var mass: float = maxf(dry_kg+fuel_kg,1.0)
  var air_vertical := vertical_speed
  var air_horizontal := horizontal_speed-atmospheric_tangential_speed()
  var speed := Vector2(air_vertical,air_horizontal).length()
  var drag: float = q*cd*area_m2
  var drag_vertical: float = drag*air_vertical/maxf(speed,0.001)
  var drag_horizontal: float = drag*air_horizontal/maxf(speed,0.001)
  var radius: float = R+maxf(altitude,0.0)
  var pitch := deg_to_rad(pitch_degrees)
  # Resolve thrust along the local radial and orbital directions, then integrate
  # central-gravity motion in polar coordinates (including curvature terms).
  var radial_thrust := active_thrust*cos(pitch)
  var tangential_thrust := active_thrust*sin(pitch)
  var flight_path_angle := atan2(air_horizontal,air_vertical)
  var angle_of_attack := wrapf(pitch-flight_path_angle,-PI,PI)
  var lift_coefficient := clampf(angle_of_attack*4.2,-1.15,1.15)
  var lift: float = q*wing_area_m2*lift_coefficient
  lift_n = lift
  var lift_vertical := -lift*sin(flight_path_angle)
  var lift_horizontal := lift*cos(flight_path_angle)
  actual_thrust_n = active_thrust
  g_load = (active_thrust+absf(lift)+drag)/mass/G0
  var ay: float = (radial_thrust+lift_vertical-drag_vertical)/mass-gravity()+horizontal_speed*horizontal_speed/radius
  var ax: float = (tangential_thrust+lift_horizontal-drag_horizontal)/mass-vertical_speed*horizontal_speed/radius
  # Keep a vehicle resting on the pad until thrust actually overcomes gravity.
  # Without this contact constraint, spool-up would integrate it below ground.
  if altitude <= 0.0 and vertical_speed <= 0.0 and ay < 0.0:
   vertical_speed = 0.0
  else:
   vertical_speed += ay*h
  horizontal_speed += ax*h
  altitude += vertical_speed*h
  downrange += horizontal_speed/radius*R*h
  time_s += h
  if altitude <= 0.0:
   altitude = 0.0
   if vertical_speed < 0.0:
    status = "LANDED" if absf(vertical_speed) < 8.0 else "IMPACT"
    if status == "IMPACT": launched = false
    vertical_speed = 0.0
    if status == "LANDED": launched = false
    break
 if launched:
  if is_in_orbit(): status = "ORBITAL COAST" if fuel_kg <= 0.0 or throttle <= 0.0 else "ORBITAL INSERTION"
  elif fuel_kg <= 0.0: status = "FUEL DEPLETED / COASTING"
  elif throttle <= 0.0: status = "COASTING"
  else: status = "POWERED ASCENT"

func preview_trajectory(horizon_seconds: float = 240.0, sample_seconds: float = 3.0) -> PackedVector2Array:
 # Simulate a private copy so map prediction never consumes live propellant or
 # changes the real vehicle's steering, engine spool, or telemetry.
 var sim := OFLaunchPhysics.new()
 sim.altitude = altitude
 sim.downrange = downrange
 sim.vertical_speed = vertical_speed
 sim.pitch_degrees = pitch_degrees
 sim.steering_input = steering_input
 sim.horizontal_speed = horizontal_speed
 sim.fuel_kg = fuel_kg
 sim.initial_fuel_kg = initial_fuel_kg
 sim.dry_kg = dry_kg
 sim.thrust_n = thrust_n
 sim.isp_s = isp_s
 sim.area_m2 = area_m2
 sim.wing_area_m2 = wing_area_m2
 sim.cd = cd
 sim.dynamic_pressure_pa = dynamic_pressure_pa
 sim.max_q_pa = max_q_pa
 sim.max_q_altitude_m = max_q_altitude_m
 sim.g_load = g_load
 sim.actual_thrust_n = actual_thrust_n
 sim.lift_n = lift_n
 sim.time_s = time_s
 sim.throttle = throttle
 sim.launched = launched
 sim.status = status
 sim.tank_fuel = tank_fuel.duplicate(true)
 sim.strict_fuel_routes = strict_fuel_routes
 for engine in engine_specs:
  sim.engine_specs.append(engine.duplicate(true))
 var points := PackedVector2Array([Vector2(downrange,altitude)])
 var interval := maxf(sample_seconds,0.25)
 var elapsed := 0.0
 while elapsed < horizon_seconds and sim.launched:
  var step_seconds := minf(interval,horizon_seconds-elapsed)
  sim.step(step_seconds,0.15)
  elapsed += step_seconds
  points.append(Vector2(sim.downrange,sim.altitude))
 return points

func ignite() -> void:
 if thrust_n <= 0.0 or fuel_kg <= 0.0: return
 # Launch from a rotating Earth: eastward ground speed is already orbital speed.
 horizontal_speed = EARTH_ROTATION_RAD_S*R*cos(deg_to_rad(LAUNCH_LATITUDE_DEG))
 launched = true
 status = "POWERED ASCENT"
