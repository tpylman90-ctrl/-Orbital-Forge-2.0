extends RefCounted
class_name OFOrbitalPhysics

## SI-unit Newtonian N-body simulator using the velocity-Verlet integrator.
## Physical state is kept separate from the solar-system display compression.
const G := 6.67430e-11
const AU_M := 149597870700.0
const DAY_S := 86400.0

var bodies: Array[Dictionary] = []
var elapsed_seconds := 0.0

func add_body(id: String, mass_kg: float, position_m: Vector3, velocity_m_s: Vector3) -> void:
	if id.is_empty() or mass_kg <= 0.0: return
	bodies.append({
		"id":id,
		"mass_kg":mass_kg,
		"position_m":position_m,
		"velocity_m_s":velocity_m_s
	})

func recenter_barycenter() -> void:
	var total_mass := 0.0
	var weighted_position := Vector3.ZERO
	var weighted_velocity := Vector3.ZERO
	for body in bodies:
		var mass := float(body["mass_kg"])
		total_mass += mass
		weighted_position += body["position_m"]*mass
		weighted_velocity += body["velocity_m_s"]*mass
	if total_mass <= 0.0: return
	var center := weighted_position/total_mass
	var velocity := weighted_velocity/total_mass
	for body in bodies:
		body["position_m"] = body["position_m"]-center
		body["velocity_m_s"] = body["velocity_m_s"]-velocity

func step(delta_seconds: float, max_step_seconds: float = 21600.0) -> void:
	if delta_seconds <= 0.0 or bodies.size() < 2: return
	var step_limit := maxf(max_step_seconds,1.0)
	var count := maxi(1,int(ceil(delta_seconds/step_limit)))
	var h := delta_seconds/float(count)
	for _index in range(count):
		_step_verlet(h)
		elapsed_seconds += h

func _step_verlet(dt: float) -> void:
	var positions: Array[Vector3] = []
	var velocities: Array[Vector3] = []
	var masses: Array[float] = []
	for body in bodies:
		positions.append(body["position_m"])
		velocities.append(body["velocity_m_s"])
		masses.append(float(body["mass_kg"]))
	var acceleration := _accelerations(positions,masses)
	var half_dt_sq := 0.5*dt*dt
	for i in range(bodies.size()):
		positions[i] += velocities[i]*dt+acceleration[i]*half_dt_sq
	var next_acceleration := _accelerations(positions,masses)
	for i in range(bodies.size()):
		velocities[i] += (acceleration[i]+next_acceleration[i])*(0.5*dt)
		bodies[i]["position_m"] = positions[i]
		bodies[i]["velocity_m_s"] = velocities[i]

func _accelerations(positions: Array[Vector3], masses: Array[float]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	result.resize(positions.size())
	result.fill(Vector3.ZERO)
	for i in range(positions.size()):
		for j in range(positions.size()):
			if i == j: continue
			var offset := positions[j]-positions[i]
			var distance_sq := maxf(offset.length_squared(),1.0)
			result[i] += offset*(G*masses[j]/(distance_sq*sqrt(distance_sq)))
	return result

func body_index(id: String) -> int:
	for i in range(bodies.size()):
		if str(bodies[i]["id"]) == id: return i
	return -1

func body_position(id: String) -> Vector3:
	var index := body_index(id)
	return bodies[index]["position_m"] if index >= 0 else Vector3.ZERO

func body_velocity(id: String) -> Vector3:
	var index := body_index(id)
	return bodies[index]["velocity_m_s"] if index >= 0 else Vector3.ZERO

func gravitational_acceleration_at(position_m: Vector3, exclude_id: String = "") -> Vector3:
	var acceleration := Vector3.ZERO
	for body in bodies:
		if str(body["id"]) == exclude_id: continue
		var offset: Vector3 = body["position_m"]-position_m
		var distance_sq := maxf(offset.length_squared(),1.0)
		acceleration += offset*(G*float(body["mass_kg"])/(distance_sq*sqrt(distance_sq)))
	return acceleration

static func orbital_period_seconds(central_mass_kg: float, semi_major_axis_m: float, orbiting_mass_kg: float = 0.0) -> float:
	if central_mass_kg <= 0.0 or semi_major_axis_m <= 0.0: return 0.0
	return TAU*sqrt(pow(semi_major_axis_m,3.0)/(G*(central_mass_kg+maxf(orbiting_mass_kg,0.0))))

static func solve_eccentric_anomaly(mean_anomaly: float, eccentricity: float) -> float:
	var e := clampf(eccentricity,0.0,0.95)
	var mean := fposmod(mean_anomaly+PI,TAU)-PI
	var eccentric := mean if e < 0.8 else signf(mean)*PI
	for _iteration in range(10):
		var residual := eccentric-e*sin(eccentric)-mean
		var derivative := 1.0-e*cos(eccentric)
		if absf(derivative) < 0.000001: break
		var correction := residual/derivative
		eccentric -= correction
		if absf(correction) < 0.0000001: break
	return eccentric

static func kepler_state(central_mass_kg: float, orbiting_mass_kg: float, semi_major_axis_m: float, eccentricity: float, mean_anomaly: float, argument_of_periapsis: float = 0.0) -> Dictionary:
	var a := maxf(semi_major_axis_m,1.0)
	var e := clampf(eccentricity,0.0,0.95)
	var anomaly := solve_eccentric_anomaly(mean_anomaly,e)
	var root := sqrt(1.0-e*e)
	var mu := G*(central_mass_kg+orbiting_mass_kg)
	var denominator := maxf(1.0-e*cos(anomaly),0.000001)
	var local_position := Vector2(a*(cos(anomaly)-e),a*root*sin(anomaly))
	var mean_motion := sqrt(mu/(a*a*a))
	var local_velocity := Vector2(-a*mean_motion*sin(anomaly)/denominator,a*mean_motion*root*cos(anomaly)/denominator)
	return {
		"position_m":_rotate_orbit_plane(local_position,argument_of_periapsis),
		"velocity_m_s":_rotate_orbit_plane(local_velocity,argument_of_periapsis),
		"true_anomaly":atan2(root*sin(anomaly),cos(anomaly)-e)+argument_of_periapsis,
		"radius_m":a*denominator
	}

static func _rotate_orbit_plane(vector: Vector2, angle: float) -> Vector3:
	var c := cos(angle)
	var s := sin(angle)
	return Vector3(vector.x*c-vector.y*s,0.0,vector.x*s+vector.y*c)

static func surface_gravity(mass_kg: float, radius_m: float) -> float:
	if mass_kg <= 0.0 or radius_m <= 0.0: return 0.0
	return G*mass_kg/(radius_m*radius_m)

static func escape_velocity(mass_kg: float, radius_m: float) -> float:
	if mass_kg <= 0.0 or radius_m <= 0.0: return 0.0
	return sqrt(2.0*G*mass_kg/radius_m)

func total_energy_j() -> float:
	var energy := 0.0
	for i in range(bodies.size()):
		var body: Dictionary = bodies[i]
		var mass := float(body["mass_kg"])
		var velocity: Vector3 = body["velocity_m_s"]
		energy += 0.5*mass*velocity.length_squared()
		for j in range(i+1,bodies.size()):
			var other: Dictionary = bodies[j]
			var body_position: Vector3 = body["position_m"]
			var other_position: Vector3 = other["position_m"]
			var distance := body_position.distance_to(other_position)
			energy -= G*mass*float(other["mass_kg"])/maxf(distance,1.0)
	return energy
