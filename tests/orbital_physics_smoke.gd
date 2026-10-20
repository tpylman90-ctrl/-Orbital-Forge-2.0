extends SceneTree

const OrbitalPhysics = preload("res://scripts/core/orbital_physics.gd")

func _initialize() -> void:
	var physics = OrbitalPhysics.new()
	var sun_mass := 1.98847e30
	var earth_mass := 5.97237e24
	var earth_orbit := OrbitalPhysics.kepler_state(sun_mass,earth_mass,OrbitalPhysics.AU_M,0.0167,1.0,0.0)
	physics.add_body("Sun",sun_mass,Vector3.ZERO,Vector3.ZERO)
	physics.add_body("Earth",earth_mass,earth_orbit["position_m"],earth_orbit["velocity_m_s"])
	physics.recenter_barycenter()
	var period_days := OrbitalPhysics.orbital_period_seconds(sun_mass,OrbitalPhysics.AU_M,earth_mass)/OrbitalPhysics.DAY_S
	if absf(period_days-365.256) > 0.1:
		push_error("Kepler period did not match Earth's sidereal orbital period")
		quit(1)
		return
	var initial_energy := physics.total_energy_j()
	physics.step(30.0*OrbitalPhysics.DAY_S,1800.0)
	var relative_energy_error := absf((physics.total_energy_j()-initial_energy)/initial_energy)
	if relative_energy_error > 0.00002:
		push_error("Velocity-Verlet integration did not conserve orbital energy over a month")
		quit(1)
		return
	var orbital_radius := physics.body_position("Earth").distance_to(physics.body_position("Sun"))
	if orbital_radius < 0.98*OrbitalPhysics.AU_M or orbital_radius > 1.02*OrbitalPhysics.AU_M:
		push_error("Earth escaped its initialized solar orbit")
		quit(1)
		return
	var earth_g := OrbitalPhysics.surface_gravity(earth_mass,6371000.0)
	var earth_escape := OrbitalPhysics.escape_velocity(earth_mass,6371000.0)
	if absf(earth_g-9.82) > 0.05 or absf(earth_escape-11186.0) > 30.0:
		push_error("Surface gravity or escape velocity is inconsistent with Earth")
		quit(1)
		return
	print("ORBITAL_PHYSICS_SMOKE_PASS: SI gravity, Kepler initialization, energy-stable N-body integration, Earth gravity and escape speed")
	quit(0)
