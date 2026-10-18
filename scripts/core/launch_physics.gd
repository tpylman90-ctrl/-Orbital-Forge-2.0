extends RefCounted
class_name OFLaunchPhysics
# SI units, 2D local vertical/horizontal trajectory with spherical Earth gravity.
const R := 6371000.0
const MU := 3.986004418e14
const RHO0 := 1.225
const SCALE_HEIGHT := 8500.0
const G0 := 9.80665

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
  dry_kg += float(spec.get("dry_mass",95.0))*volume
  if kind == "tank":
   fuel_kg += float(spec.get("fuel_mass",700.0))*volume
  if kind in ["engine","ion"]:
   var thrust: float = float(spec.get("thrust",120000.0 if kind == "engine" else 2000.0))*volume
   var isp: float = float(spec.get("isp",310.0 if kind == "engine" else 1800.0))
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
  var mass_before: float = mass_kg()
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
