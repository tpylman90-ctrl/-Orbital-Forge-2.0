extends RefCounted
class_name OFLaunchPhysics
# SI units, 2D local vertical/horizontal trajectory with spherical Earth gravity.
const R := 6371000.0
const MU := 3.986004418e14
const RHO0 := 1.225
const SCALE_HEIGHT := 8500.0
const G0 := 9.80665
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
var horizontal_speed := 0.0
var fuel_kg := 0.0
var dry_kg := 0.0
var thrust_n := 0.0
var isp_s := 300.0
var area_m2 := 1.0
var cd := 0.5
var time_s := 0.0
var throttle := 1.0
var launched := false
var status := "READY"

func configure(craft: Dictionary, catalog: Dictionary) -> void:
 dry_kg = 0.0
 fuel_kg = 0.0
 thrust_n = 0.0
 area_m2 = 0.4
 var weighted_isp := 0.0
 for part in craft.get("parts",[]):
  var spec: Dictionary = catalog.get(str(part.get("type","")),{})
  var kind: String = str(spec.get("kind",""))
  var scale_factor: float = float(part.get("scale",1.0))
  var volume: float = scale_factor*scale_factor*scale_factor
  var radius: float = float(spec.get("radius",0.5))*scale_factor
  area_m2 = maxf(area_m2,PI*radius*radius)
  var ratings: Array = RATINGS.get(str(part.get("type","")),[95.0,0.0,0.0,0.0])
  dry_kg += float(ratings[0])*volume
  fuel_kg += float(ratings[1])*volume
  if float(ratings[2]) > 0.0:
   var thrust: float = float(ratings[2])*volume
   var isp: float = float(ratings[3])
   thrust_n += thrust
   weighted_isp += thrust*isp
 if thrust_n > 0.0: isp_s = weighted_isp/thrust_n
 status = "READY" if thrust_n > 0.0 and fuel_kg > 0.0 else "NEEDS ENGINE AND FUEL"

func mass_kg() -> float:
 return dry_kg+fuel_kg

func gravity() -> float:
 return MU/pow(R+maxf(altitude,0.0),2.0)

func density() -> float:
 return RHO0*exp(-maxf(altitude,0.0)/SCALE_HEIGHT)

func twr() -> float:
 return thrust_n*throttle/maxf(mass_kg()*gravity(),0.001)

func step(dt: float) -> void:
 if not launched or status in ["LANDED","NEEDS ENGINE AND FUEL"]: return
 # Substeps prevent unstable mass and drag integration under mobile frame spikes.
 var count: int = maxi(1,int(ceil(dt/0.02)))
 var h: float = dt/float(count)
 for n in range(count):
  var burn: float = 0.0
  if fuel_kg > 0.0 and throttle > 0.0 and thrust_n > 0.0:
   burn = minf(fuel_kg,thrust_n*throttle/(isp_s*G0)*h)
  var active_thrust: float = thrust_n*throttle if burn > 0.0 else 0.0
  fuel_kg -= burn
  var mass: float = maxf(dry_kg+fuel_kg,1.0)
  var speed: float = sqrt(vertical_speed*vertical_speed+horizontal_speed*horizontal_speed)
  var drag: float = 0.5*density()*speed*speed*cd*area_m2
  var drag_vertical: float = drag*vertical_speed/maxf(speed,0.001)
  var drag_horizontal: float = drag*horizontal_speed/maxf(speed,0.001)
  var ay: float = (active_thrust-drag_vertical)/mass-gravity()
  var ax: float = -drag_horizontal/mass
  vertical_speed += ay*h
  horizontal_speed += ax*h
  altitude += vertical_speed*h
  downrange += horizontal_speed*h
  time_s += h
  if altitude <= 0.0:
   altitude = 0.0
   if vertical_speed < 0.0:
    status = "LANDED" if absf(vertical_speed) < 8.0 else "IMPACT"
    if status == "IMPACT": launched = false
    vertical_speed = 0.0
    if status == "LANDED": launched = false
    break
 if launched: status = "COASTING" if fuel_kg <= 0.0 or throttle <= 0.0 else "POWERED ASCENT"

func ignite() -> void:
 if thrust_n <= 0.0 or fuel_kg <= 0.0: return
 launched = true
 status = "POWERED ASCENT"
