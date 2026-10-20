"""Build compact, detailed Blender models for Orbital Forge's core parts.

Run with:
    blender --background --factory-startup --python tools/blender/generate_parts.py -- --out-dir assets/blender
"""
import argparse
import json
import os
import sys
from math import cos, sin, radians, pi
import bpy
from mathutils import Vector

PARTS = (
    "command_pod", "fuel_tank", "rocket_engine", "station_ring",
    "heavy_booster_tank", "cryo_tank", "spherical_tank", "heavy_engine",
    "vacuum_engine", "ion_drive", "plasma_drive", "panoramic_cockpit",
    "bubble_cockpit", "spaceplane_wing", "delta_wing", "nose_cone", "needle_tip",
    "orbital_fuselage", "cargo_fuselage",
)


def material(name, color, metallic=0.0, roughness=0.42):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return m


def finish(obj, name, mat, bevel=0.0):
    obj.name = name
    obj.data.materials.append(mat)
    if bevel:
        modifier = obj.modifiers.new("Machined edge radius", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return obj


def cylinder(name, bottom, top, depth, location, mat, vertices=48, bevel=0.012):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices, radius1=bottom, radius2=top, depth=depth, location=location
    )
    return finish(bpy.context.object, name, mat, bevel)


def torus(name, radius, tube, z, mat, major=48, minor=12):
    bpy.ops.mesh.primitive_torus_add(
        major_segments=major, minor_segments=minor, major_radius=radius,
        minor_radius=tube, location=(0, 0, z)
    )
    return finish(bpy.context.object, name, mat)


def box(name, dimensions, location, mat, rotation=0.0, bevel=0.012):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.dimensions = dimensions
    obj.rotation_euler[2] = rotation
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, bevel)


def sphere(name, radius, location, mat, scale=(1.0, 1.0, 1.0), rotation=None):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=24, ring_count=12, radius=radius, location=location
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    if rotation is not None:
        obj.rotation_euler = rotation
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat)


def pipe_between(name, start, end, radius, mat, vertices=12):
    start, end = Vector(start), Vector(end)
    direction = end - start
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=direction.length,
        location=(start + end) * 0.5
    )
    obj = bpy.context.object
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return finish(obj, name, mat, radius * 0.22)


def fastener_ring(name, radius, z, count, mat, size=0.027):
    for i in range(count):
        a = 2 * pi * i / count
        sphere(name, size, (radius * cos(a), radius * sin(a), z), mat,
               scale=(1.0, 1.0, 0.68))


def build_command_pod(hull, graphite, titanium, gold, glass):
    cylinder("Crew pressure cabin", 0.70, 0.66, 1.08, (0, 0, -0.02), hull)
    cylinder("Continuous pointed nose shell", 0.66, 0.018, 0.78, (0, 0, 0.91), hull,
             vertices=48, bevel=0.004)
    # Tiny rounded ceramic point: no flat cap or disk on the nose.
    sphere("Ceramic nose point", 0.035, (0, 0, 1.305), hull, scale=(1, 1, 1.2))
    cylinder("Heat shield backing", 0.72, 0.66, 0.16, (0, 0, -0.57), graphite)
    cylinder("Crew access collar", 0.71, 0.71, 0.08, (0, 0, -0.43), titanium)
    torus("Cabin shoulder seam", 0.675, 0.026, 0.48, gold)
    torus("Heat-shield retaining band", 0.708, 0.035, -0.47, gold)
    fastener_ring("Heat shield bolts", 0.70, -0.47, 16, titanium, 0.024)
    # Four individually seated viewports around the cabin wall.
    for i in range(4):
        a = 2 * pi * i / 4
        normal = Vector((cos(a), sin(a), 0))
        center = (0.665 * cos(a), 0.665 * sin(a), 0.04)
        bezel = sphere("Viewport metal bezel", 0.12, center, titanium,
                       scale=(1, 1, 0.24))
        bezel.rotation_euler = normal.to_track_quat("Z", "Y").to_euler()
        pane_center = Vector(center) + normal * 0.019
        pane = sphere("Smoked pressure viewport", 0.095, pane_center, glass,
                      scale=(1, 1, 0.24))
        pane.rotation_euler = normal.to_track_quat("Z", "Y").to_euler()
    # A flush avionics hatch and two small antenna stubs add scale cues.
    box("Avionics hatch", (0.24, 0.34, 0.035), (0.28, -0.30, 0.08), graphite, bevel=0.025)
    box("Hatch safety stripe", (0.16, 0.026, 0.014), (0.28, -0.319, 0.12), gold, bevel=0.004)
    for x in (-0.30, 0.30):
        pipe_between("Low profile antenna", (x, 0, 0.44), (x, 0, 0.58), 0.018, titanium, 8)


def build_fuel_tank(hull, graphite, titanium, gold, glass):
    cylinder("Main propellant barrel", 0.70, 0.70, 1.58, (0, 0, 0), hull, bevel=0.025)
    # Shallow domed end caps give the pressure vessel a manufactured profile.
    sphere("Upper domed endcap", 0.70, (0, 0, 0.76), hull, scale=(1, 1, 0.31))
    sphere("Lower domed endcap", 0.70, (0, 0, -0.76), hull, scale=(1, 1, 0.31))
    for z in (-0.80, 0.80):
        cylinder("Structural end flange", 0.75, 0.75, 0.105, (0, 0, z), graphite)
        torus("Flange edge bead", 0.75, 0.018, z + (0.06 if z > 0 else -0.06), gold)
        fastener_ring("Flange locking bolts", 0.73, z, 16, titanium, 0.022)
    for z in (-0.53, 0.0, 0.53):
        torus("Tank circumferential stiffener", 0.704, 0.026, z, titanium)
    # Service panel, paired feed lines, and capped ports.
    box("Tank service panel", (0.34, 0.50, 0.055), (0.49, -0.02, 0.10), graphite, bevel=0.028)
    box("Panel warning stripe", (0.25, 0.035, 0.018), (0.505, 0.12, 0.13), gold, bevel=0.004)
    for x in (-0.43, 0.43):
        pipe_between("External feed line", (x, 0, -0.67), (x, 0, 0.67), 0.027, titanium)
        for z in (-0.67, 0.67):
            cylinder("Feed-line coupling", 0.065, 0.065, 0.075, (x, 0, z), gold, vertices=12, bevel=0.006)
    for z in (-0.91, 0.91):
        cylinder("Axial plumbing port", 0.25, 0.25, 0.13, (0, 0, z), graphite)
        cylinder("Port protective cap", 0.15, 0.15, 0.035, (0, 0, z + (0.08 if z > 0 else -0.08)), gold, vertices=24, bevel=0.005)


def build_engine(hull, graphite, titanium, gold, glass):
    cylinder("Engine thrust frame", 0.43, 0.43, 0.18, (0, 0, 0.57), graphite)
    cylinder("Combustion chamber", 0.37, 0.33, 0.54, (0, 0, 0.18), hull)
    cylinder("Turbopump housing", 0.40, 0.36, 0.18, (0, 0, 0.42), titanium)
    torus("Chamber injector band", 0.37, 0.027, 0.39, gold)
    cylinder("Expansion nozzle bell", 0.30, 0.73, 0.90, (0, 0, -0.53), graphite,
             vertices=56, bevel=0.008)
    cylinder("Nozzle throat liner", 0.255, 0.61, 0.73, (0, 0, -0.51), titanium,
             vertices=48, bevel=0.003)
    torus("Nozzle exit bead", 0.73, 0.035, -0.98, gold)
    torus("Nozzle reinforcement ring", 0.49, 0.025, -0.74, titanium)
    cylinder("Exhaust aperture", 0.56, 0.56, 0.025, (0, 0, -0.985), glass,
             vertices=48, bevel=0.003)
    for i in range(8):
        a = 2 * pi * i / 8
        x, y = cos(a), sin(a)
        pipe_between("Fuel line hardpipe", (0.36*x, 0.36*y, 0.29),
                     (0.46*x, 0.46*y, -0.27), 0.035, gold)
        sphere("Pump union", 0.055, (0.39*x, 0.39*y, 0.30), titanium,
               scale=(1, 1, 0.8))
    fastener_ring("Mounting flange bolts", 0.405, 0.67, 12, gold, 0.022)
    fastener_ring("Lower injector bolts", 0.38, 0.38, 12, titanium, 0.018)


def build_station_ring(hull, graphite, titanium, gold, glass, array):
    torus("Habitat pressure ring", 1.16, 0.20, 0, hull, major=64, minor=16)
    torus("Ring exterior truss", 1.18, 0.045, 0, titanium, major=64, minor=10)
    cylinder("Central docking hub", 0.37, 0.37, 0.48, (0, 0, 0), graphite)
    torus("Docking hub alignment collar", 0.39, 0.035, 0.24, gold)
    cylinder("Axial docking interface", 0.23, 0.16, 0.18, (0, 0, 0.32), titanium)
    for i in range(8):
        a = 2 * pi * i / 8
        x, y = cos(a), sin(a)
        pipe_between("Radial habitat spoke", (0.32*x, 0.32*y, 0), (1.13*x, 1.13*y, 0), 0.065, titanium)
        sphere("Spoke pressure coupling", 0.105, (0.38*x, 0.38*y, 0), gold, scale=(1, 1, 0.85))
    # Four visible lab modules make this read as a usable station, not just a torus.
    for i in range(4):
        a = 2 * pi * i / 4 + pi / 4
        x, y = cos(a), sin(a)
        module = box("Orbital research module", (0.58, 0.30, 0.25),
                     (0.88*x, 0.88*y, 0.0), hull, rotation=a, bevel=0.045)
        module.rotation_euler[2] = a
        sphere("Module viewport", 0.075, (1.01*x, 1.01*y, 0.12), glass, scale=(1.0, 0.55, 0.5))
    # Two compact blue photovoltaic wings attach to opposite sides.
    for sign in (-1.0, 1.0):
        box("Solar array panel", (0.72, 0.29, 0.035), (sign*1.48, 0, 0), array, bevel=0.018)
        for i in range(4):
            box("Solar cell busbar", (0.018, 0.27, 0.014),
                (sign*(1.22 + 0.17*i), 0, 0.026), titanium, bevel=0.002)


def build_heavy_booster_tank(hull, graphite, titanium, gold, glass):
    cylinder("Booster propellant barrel", 0.84, 0.84, 2.05, (0, 0, 0), hull, bevel=0.035)
    sphere("Forward pressure dome", 0.84, (0, 0, 1.00), hull, scale=(1, 1, 0.25))
    sphere("Aft pressure dome", 0.84, (0, 0, -1.00), hull, scale=(1, 1, 0.25))
    for z in (-1.02, -0.52, 0.52, 1.02):
        torus("Booster tank rolled seam", 0.84 if abs(z) > 0.8 else 0.845,
              0.025 if abs(z) > 0.8 else 0.018, z, gold if abs(z) > 0.8 else titanium)
    for z in (-1.07, 1.07):
        cylinder("Heavy interstage flange", 0.91, 0.91, 0.13, (0, 0, z), graphite)
        fastener_ring("Flange tie-down bolts", 0.89, z, 20, gold, 0.025)
    # Four reinforced strap-on attachment rails make its booster role obvious.
    for i in range(4):
        a = 2*pi*i/4 + pi/4
        x, y = cos(a), sin(a)
        pipe_between("Booster load rail", (0.87*x, 0.87*y, -0.76),
                     (0.87*x, 0.87*y, 0.76), 0.045, graphite, 10)
        for z in (-0.68, 0.68):
            box("Radial booster lug", (0.22, 0.20, 0.18),
                (0.90*x, 0.90*y, z), titanium, rotation=a, bevel=0.025)
    # Paired external feed lines terminate in visible capped couplings.
    for x in (-0.39, 0.39):
        pipe_between("Cryo feed line", (x, -0.55, -0.82), (x, -0.55, 0.82), 0.035, titanium)
        for z in (-0.84, 0.84):
            cylinder("Feed line disconnect", 0.075, 0.075, 0.09,
                     (x, -0.55, z), gold, vertices=16, bevel=0.006)
    box("Booster serial plaque", (0.32, 0.035, 0.24), (0, -0.854, 0.12), graphite, bevel=0.018)
    box("Plaque safety bar", (0.23, 0.018, 0.025), (0, -0.877, 0.17), gold, bevel=0.004)


def build_cryo_tank(hull, graphite, titanium, gold, glass):
    cryo = material("Cryogenic insulation jacket", (0.20, 0.43, 0.54), 0.36, 0.30)
    cylinder("Vacuum jacket vessel", 0.64, 0.64, 1.55, (0, 0, 0), cryo, bevel=0.025)
    sphere("Upper domed head", 0.64, (0, 0, 0.75), cryo, scale=(1, 1, 0.34))
    sphere("Lower domed head", 0.64, (0, 0, -0.75), cryo, scale=(1, 1, 0.34))
    for z in (-0.83, 0.83):
        cylinder("Cryo end ring", 0.69, 0.69, 0.12, (0, 0, z), graphite)
        torus("Thermal break lip", 0.68, 0.025, z + (0.07 if z > 0 else -0.07), gold)
        fastener_ring("Cryo flange fasteners", 0.67, z, 16, titanium, 0.018)
    for z in (-0.46, 0.0, 0.46):
        torus("Insulation panel boundary", 0.65, 0.016, z, titanium)
    # Shielded helium bottles and a paired transfer manifold sit outside the jacket.
    for a in (0, pi):
        x, y = cos(a), sin(a)
        cylinder("Helium pressurant bottle", 0.105, 0.105, 1.05,
                 (0.49*x, 0.49*y, 0), titanium, vertices=20, bevel=0.025)
        cylinder("Bottle retaining hoop", 0.13, 0.13, 0.035,
                 (0.49*x, 0.49*y, 0.0), gold, vertices=24, bevel=0.006)
    for x in (-0.30, 0.30):
        pipe_between("Cryogenic transfer pipe", (x, -0.53, -0.65),
                     (x, -0.53, 0.62), 0.027, gold, 10)
    box("Cryogenic service panel", (0.34, 0.045, 0.38), (0, -0.65, 0.10), graphite, bevel=0.025)
    box("Cryo warning stripe", (0.25, 0.018, 0.045), (0, -0.679, 0.20), gold, bevel=0.004)
    for x in (-0.11, 0.0, 0.11):
        sphere("Panel indicator", 0.026, (x, -0.681, 0.015), glass)


def build_spherical_tank(hull, graphite, titanium, gold, glass):
    vessel = material("Spherical pressure-vessel ceramic", (0.47, 0.66, 0.71), 0.45, 0.28)
    sphere("Spherical propellant vessel", 0.68, (0, 0, 0), vessel)
    torus("Equatorial retaining collar", 0.69, 0.038, 0, graphite)
    torus("Gold equator witness line", 0.70, 0.012, 0.07, gold)
    # Four meridian straps and a pair of machined poles form a real support cage.
    for angle in (0, pi/2, pi, 3*pi/2):
        x, y = cos(angle), sin(angle)
        pipe_between("Meridian support strap", (0.59*x, 0.59*y, -0.35),
                     (0.59*x, 0.59*y, 0.35), 0.032, titanium, 10)
        sphere("Cage anchor", 0.055, (0.59*x, 0.59*y, 0), gold)
    for z in (-0.68, 0.68):
        cylinder("Pole clamp", 0.20, 0.20, 0.10, (0, 0, z), graphite)
    cylinder("Upper coupling neck", 0.16, 0.13, 0.20, (0, 0, 0.78), titanium)
    cylinder("Lower coupling neck", 0.16, 0.13, 0.20, (0, 0, -0.78), titanium)
    torus("Upper port seal", 0.14, 0.018, 0.89, gold, major=24, minor=8)
    torus("Lower port seal", 0.14, 0.018, -0.89, gold, major=24, minor=8)
    pipe_between("Feed manifold", (0.48, -0.48, -0.55), (0.48, -0.48, 0.52), 0.025, graphite, 10)


def build_heavy_engine(hull, graphite, titanium, gold, glass):
    cylinder("Titan thrust frame", 0.64, 0.64, 0.20, (0, 0, 0.73), graphite)
    fastener_ring("Thrust frame bolts", 0.62, 0.73, 16, gold, 0.025)
    cylinder("Combustion chamber jacket", 0.48, 0.42, 0.58, (0, 0, 0.34), hull)
    cylinder("Twin turbopump housing", 0.20, 0.26, 0.30, (0.46, 0, 0.39), titanium)
    cylinder("Twin turbopump housing", 0.20, 0.26, 0.30, (-0.46, 0, 0.39), titanium)
    torus("Injector manifold", 0.46, 0.035, 0.60, gold)
    cylinder("Large expansion bell", 0.31, 0.78, 1.02, (0, 0, -0.48), graphite,
             vertices=64, bevel=0.009)
    cylinder("Bell inner liner", 0.27, 0.69, 0.91, (0, 0, -0.48), titanium,
             vertices=56, bevel=0.004)
    torus("Nozzle exit bead", 0.78, 0.04, -0.99, gold, major=56, minor=12)
    torus("Nozzle stiffening hoop", 0.56, 0.026, -0.72, titanium)
    for i in range(12):
        a = 2*pi*i/12
        x, y = cos(a), sin(a)
        pipe_between("Titan feed hardline", (0.44*x, 0.44*y, 0.56),
                     (0.58*x, 0.58*y, -0.10), 0.031, gold, 10)
        sphere("Actuator union", 0.05, (0.44*x, 0.44*y, 0.55), titanium)
    for i in range(4):
        a = 2*pi*i/4 + pi/4
        x, y = cos(a), sin(a)
        pipe_between("Gimbal hydraulic ram", (0.49*x, 0.49*y, 0.17),
                     (0.68*x, 0.68*y, -0.30), 0.045, titanium, 10)


def build_vacuum_engine(hull, graphite, titanium, gold, glass):
    cylinder("Vacuum engine mounting plate", 0.48, 0.48, 0.16, (0, 0, 0.79), graphite)
    cylinder("Regenerative chamber", 0.32, 0.28, 0.38, (0, 0, 0.51), hull)
    cylinder("Gimbal bearing", 0.34, 0.34, 0.12, (0, 0, 0.28), titanium)
    torus("Gimbal race", 0.35, 0.025, 0.28, gold)
    cylinder("Extended vacuum bell", 0.20, 0.72, 1.48, (0, 0, -0.50), graphite,
             vertices=64, bevel=0.006)
    cylinder("Vacuum throat liner", 0.17, 0.63, 1.32, (0, 0, -0.50), titanium,
             vertices=56, bevel=0.003)
    torus("Bell lip", 0.72, 0.032, -1.24, gold, major=56, minor=12)
    for i in range(8):
        a = 2*pi*i/8
        x, y = cos(a), sin(a)
        pipe_between("Vacuum bell cooling line", (0.31*x, 0.31*y, 0.61),
                     (0.49*x, 0.49*y, -0.31), 0.026, titanium, 8)
        box("Bell ceramic isolator", (0.10, 0.10, 0.16),
            (0.43*x, 0.43*y, -0.02), gold, rotation=a, bevel=0.012)


def build_ion_drive(hull, graphite, titanium, gold, glass, plasma=False):
    accent = material("Plasma violet ceramic" if plasma else "Ion drive ceramic",
                      (0.34, 0.20, 0.52) if plasma else (0.22, 0.43, 0.60), 0.42, 0.27)
    cylinder("Electric propulsion spine", 0.34, 0.31, 0.62, (0, 0, 0.16), graphite)
    cylinder("Magnetic field cage", 0.43, 0.43, 0.12, (0, 0, 0.47), titanium)
    cylinder("Rear magnetic collar", 0.48, 0.48, 0.11, (0, 0, -0.20), gold)
    torus("Field coil ring", 0.43, 0.045, 0.45, accent, major=40, minor=10)
    torus("Accelerator grid", 0.35, 0.035, -0.19, titanium, major=40, minor=10)
    torus("Emitter ring", 0.28, 0.022, -0.30, gold, major=40, minor=10)
    for i in range(8):
        a = 2*pi*i/8
        x, y = cos(a), sin(a)
        pipe_between("Radial magnetic strut", (0.30*x, 0.30*y, 0.46),
                     (0.52*x, 0.52*y, -0.25), 0.035, titanium, 8)
        box("Insulated coil feed", (0.10, 0.08, 0.24),
            (0.43*x, 0.43*y, 0.14), accent, rotation=a, bevel=0.012)
    if plasma:
        torus("Plasma containment halo", 0.62, 0.07, 0.10, accent, major=48, minor=12)
        torus("Vortex field marker", 0.67, 0.025, -0.02, gold, major=48, minor=10)
    else:
        cylinder("Ionizer cap", 0.20, 0.18, 0.16, (0, 0, 0.55), hull)
        for i in range(6):
            a = 2*pi*i/6
            x, y = cos(a), sin(a)
            box("Thermal fin", (0.16, 0.06, 0.50),
                (0.52*x, 0.52*y, 0.12), graphite, rotation=a, bevel=0.009)


def build_panoramic_cockpit(hull, graphite, titanium, gold, glass):
    cabin = material("Cockpit ceramic", (0.56, 0.68, 0.72), 0.48, 0.31)
    cylinder("Flight deck pressure shell", 0.68, 0.64, 0.92, (0, 0, -0.18), cabin)
    sphere("Flight deck crown", 0.64, (0, 0, 0.25), cabin, scale=(1, 1, 0.68))
    # Broad smoked glass and paired frames create a clear ship-like canopy.
    canopy = sphere("Panoramic smoked canopy", 0.53, (0, -0.34, 0.28), glass,
                    scale=(1.08, 0.54, 0.92))
    canopy.rotation_euler[0] = radians(-20)
    for x in (-0.29, 0.0, 0.29):
        pipe_between("Canopy structural bow", (x, -0.63, -0.02),
                     (x*0.82, -0.39, 0.70), 0.028, titanium, 10)
    torus("Canopy pressure seal", 0.65, 0.028, 0.03, gold)
    cylinder("Docking interface collar", 0.69, 0.69, 0.13, (0, 0, -0.67), graphite)
    fastener_ring("Cockpit collar fasteners", 0.68, -0.67, 16, titanium, 0.018)
    box("Pilot access hatch", (0.26, 0.06, 0.34), (0.38, 0.18, -0.12), graphite, bevel=0.025)
    box("Hatch marking", (0.17, 0.025, 0.035), (0.38, 0.145, -0.02), gold, bevel=0.004)


def build_bubble_cockpit(hull, graphite, titanium, gold, glass):
    shell = material("Bubble cockpit ceramic", (0.24, 0.42, 0.54), 0.47, 0.29)
    sphere("Compact pressure capsule", 0.61, (0, 0, 0.05), shell, scale=(1.0, 0.92, 1.14))
    # Forward viewport is deliberately large and faceted into armored panes.
    glass_center = (0, -0.48, 0.20)
    glass_dome = sphere("Bubble panoramic glazing", 0.43, glass_center, glass,
                        scale=(1.0, 0.48, 0.82))
    glass_dome.rotation_euler[0] = radians(-12)
    for x in (-0.23, 0.0, 0.23):
        pipe_between("Bubble canopy mullion", (x, -0.68, -0.02),
                     (x*0.72, -0.51, 0.54), 0.024, titanium, 8)
    torus("Bubble docking collar", 0.57, 0.042, -0.52, graphite)
    torus("Collar witness stripe", 0.58, 0.014, -0.48, gold)
    fastener_ring("Bubble collar bolts", 0.57, -0.52, 12, titanium, 0.018)
    for x in (-0.40, 0.40):
        box("RCS fairing", (0.13, 0.16, 0.24), (x, 0, -0.12), titanium, bevel=0.03)


def build_wing(hull, graphite, titanium, gold, glass, delta=False):
    # Extruded aircraft-style planform in Blender X/Z so it lies in Godot's X/Y craft plane.
    if delta:
        outline = [(-0.68, -0.72), (0.68, -0.72), (1.55, 0.76), (0.0, 0.48), (-1.55, 0.76)]
    else:
        outline = [(-0.72, -0.72), (0.72, -0.72), (1.42, 0.68), (0.58, 0.44), (-1.42, 0.68)]
    thickness = 0.11
    vertices = [(x, y, z) for y in (-thickness/2, thickness/2) for x, z in outline]
    n = len(outline)
    faces = []
    faces.append(tuple(range(n-1, -1, -1)))
    faces.append(tuple(range(n, n*2)))
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n+j, n+i))
    mesh = bpy.data.meshes.new("Delta wing airfoil" if delta else "Spaceplane airfoil")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(hull)
    wing = bpy.data.objects.new("Swept aerospace lifting surface", mesh)
    bpy.context.collection.objects.link(wing)
    bevel = wing.modifiers.new("Machined leading and trailing edges", "BEVEL")
    bevel.width = 0.045
    bevel.segments = 3
    wing.modifiers.new("Weighted airfoil normals", "WEIGHTED_NORMAL")
    # Titanium spar and gold service markings stay visible at small on-screen scale.
    box("Wing root spar", (0.16, 0.15, 1.00), (0, 0, -0.02), titanium, bevel=0.025)
    for sign in (-1.0, 1.0):
        pipe_between("Raked wing actuator", (sign*0.18, 0, -0.38),
                     (sign*1.13, 0, 0.49), 0.035, graphite, 8)
        box("Wingtip safety panel", (0.15, 0.13, 0.28),
            (sign*1.39, 0, 0.61), gold, bevel=0.018)
        for z in (-0.38, 0.02, 0.40):
            box("Thermal tile access seam", (0.52, 0.012, 0.018),
                (sign*0.82, -0.064, z), titanium, bevel=0.003)
    box("Control surface hinge line", (2.35, 0.018, 0.025),
        (0, -0.064, 0.34), graphite, bevel=0.003)


def build_nose(hull, graphite, titanium, gold, glass, needle=False):
    base_radius = 0.42 if needle else 0.68
    height = 1.48 if needle else 1.30
    cylinder("Forged aerodynamic nose shell", base_radius, 0.008 if needle else 0.012,
             height, (0, 0, height/2 - 0.48), hull, vertices=56, bevel=0.006)
    sphere("Ceramic impact point", 0.035 if needle else 0.045,
           (0, 0, height - 0.48), titanium, scale=(1, 1, 1.2))
    torus("Base attachment collar", base_radius*1.015, 0.035, -0.44, graphite)
    torus("Separation witness stripe", base_radius*1.025, 0.014, -0.35, gold)
    fastener_ring("Nose interface bolts", base_radius*1.02, -0.44, 12, titanium, 0.019)
    for z in (-0.18, -0.02, 0.14):
        seam_radius = base_radius * (1 - (z + 0.44)/height) * 0.97
        torus("Nose shell precision seam", seam_radius, 0.009, z, titanium)


def build_orbital_fuselage(hull, graphite, titanium, gold, glass):
    cylinder("Orbital pressure hull", 0.73, 0.73, 2.56, (0, 0, 0), hull, bevel=0.03)
    for z in (-1.31, 1.31):
        cylinder("Modular docking flange", 0.80, 0.80, 0.13, (0, 0, z), graphite)
        torus("Flange alignment bead", 0.79, 0.028, z + (0.07 if z > 0 else -0.07), gold)
        fastener_ring("Fuselage flange bolts", 0.77, z, 20, titanium, 0.019)
    for z in (-0.78, -0.25, 0.25, 0.78):
        torus("Pressure shell circumferential seam", 0.735, 0.014, z, titanium)
    # Two rows of recessed viewports and flush access panels.
    for z in (-0.48, 0.48):
        for a in (0, pi/2, pi, 3*pi/2):
            x, y = cos(a), sin(a)
            normal = Vector((x, y, 0))
            center = Vector((0.735*x, 0.735*y, z))
            bezel = sphere("Viewport bezel", 0.10, center, titanium, scale=(1, 1, 0.25))
            bezel.rotation_euler = normal.to_track_quat("Z", "Y").to_euler()
            pane = sphere("Smoked viewport", 0.074, center + normal*0.015, glass,
                          scale=(1, 1, 0.24))
            pane.rotation_euler = normal.to_track_quat("Z", "Y").to_euler()
    for x in (-0.37, 0.37):
        pipe_between("External service conduit", (x, -0.60, -1.02),
                     (x, -0.60, 1.02), 0.026, gold, 10)
        for z in (-0.96, 0.96):
            sphere("Conduit socket", 0.055, (x, -0.60, z), titanium)
    box("Fuselage equipment hatch", (0.31, 0.045, 0.48), (0, -0.735, 0.14), graphite, bevel=0.025)
    box("Hatch status marking", (0.22, 0.018, 0.035), (0, -0.762, 0.28), gold, bevel=0.004)
    for x in (-0.10, 0.0, 0.10):
        sphere("Hatch pressure latch", 0.025, (x, -0.765, -0.04), titanium)


def build_cargo_fuselage(hull, graphite, titanium, gold, glass):
    cargo = material("Cargo hull enamel", (0.39, 0.51, 0.56), 0.5, 0.34)
    box("Pressurized cargo shell", (1.68, 1.38, 2.20), (0, 0, 0), cargo, bevel=0.11)
    # Broad door with a machined perimeter, hinges and load locks.
    box("Cargo access door", (1.18, 0.055, 1.28), (0, -0.704, 0.05), graphite, bevel=0.07)
    box("Door inset panel", (0.98, 0.022, 1.08), (0, -0.742, 0.05), hull, bevel=0.045)
    for x in (-0.66, 0.66):
        box("Longitudinal titanium rail", (0.14, 1.50, 2.08), (x, 0, 0), titanium, bevel=0.035)
    for z in (-0.84, 0.84):
        box("End frame crossbeam", (1.66, 1.40, 0.16), (0, 0, z), graphite, bevel=0.03)
        box("Frame safety stripe", (1.38, 0.018, 0.045), (0, -0.718, z), gold, bevel=0.004)
    for x in (-0.45, 0.45):
        for z in (-0.48, 0.58):
            box("Cargo door locking dog", (0.12, 0.09, 0.18), (x, -0.76, z), gold, bevel=0.02)
    for z in (-0.65, -0.20, 0.25, 0.68):
        box("Cargo shell panel seam", (1.42, 0.018, 0.025), (0, -0.701, z), titanium, bevel=0.006)
    box("Cargo docking interface", (1.34, 1.10, 0.20), (0, 0, -1.20), graphite, bevel=0.06)
    box("Upper adapter plate", (1.20, 1.00, 0.18), (0, 0, 1.18), titanium, bevel=0.05)
    for x in (-0.58, 0.58):
        for y in (-0.46, 0.46):
            cylinder("Docking hardpoint", 0.11, 0.11, 0.18, (x, y, -1.22), gold, vertices=16, bevel=0.012)


def optimize_runtime_mesh(part):
    # Bake bevels and combine the detailed subassemblies into one multi-material
    # mesh per part. This keeps high detail while limiting Android draw calls and
    # making each inventory part behave as one predictable selectable object.
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in mesh_objects:
        obj.select_set(True)
    if mesh_objects:
        bpy.context.view_layer.objects.active = mesh_objects[0]
        bpy.ops.object.convert(target="MESH")
        baked = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
        bpy.ops.object.select_all(action="DESELECT")
        for obj in baked:
            obj.select_set(True)
        active = baked[0]
        bpy.context.view_layer.objects.active = active
        if len(baked) > 1:
            bpy.ops.object.join()
        active.name = "OrbitalForge_" + part
        active.data.name = "OrbitalForgeMesh_" + part
        active.data.validate(clean_customdata=False)
        active.data.update()


def build(part, materials):
    hull, graphite, titanium, gold, glass, array = materials
    if part == "command_pod":
        build_command_pod(hull, graphite, titanium, gold, glass)
    elif part == "fuel_tank":
        build_fuel_tank(hull, graphite, titanium, gold, glass)
    elif part == "rocket_engine":
        build_engine(hull, graphite, titanium, gold, glass)
    elif part == "station_ring":
        build_station_ring(hull, graphite, titanium, gold, glass, array)
    elif part == "heavy_booster_tank":
        build_heavy_booster_tank(hull, graphite, titanium, gold, glass)
    elif part == "cryo_tank":
        build_cryo_tank(hull, graphite, titanium, gold, glass)
    elif part == "spherical_tank":
        build_spherical_tank(hull, graphite, titanium, gold, glass)
    elif part == "heavy_engine":
        build_heavy_engine(hull, graphite, titanium, gold, glass)
    elif part == "vacuum_engine":
        build_vacuum_engine(hull, graphite, titanium, gold, glass)
    elif part == "ion_drive":
        build_ion_drive(hull, graphite, titanium, gold, glass)
    elif part == "plasma_drive":
        build_ion_drive(hull, graphite, titanium, gold, glass, plasma=True)
    elif part == "panoramic_cockpit":
        build_panoramic_cockpit(hull, graphite, titanium, gold, glass)
    elif part == "bubble_cockpit":
        build_bubble_cockpit(hull, graphite, titanium, gold, glass)
    elif part == "spaceplane_wing":
        build_wing(hull, graphite, titanium, gold, glass)
    elif part == "delta_wing":
        build_wing(hull, graphite, titanium, gold, glass, delta=True)
    elif part == "nose_cone":
        build_nose(hull, graphite, titanium, gold, glass)
    elif part == "needle_tip":
        build_nose(hull, graphite, titanium, gold, glass, needle=True)
    elif part == "orbital_fuselage":
        build_orbital_fuselage(hull, graphite, titanium, gold, glass)
    elif part == "cargo_fuselage":
        build_cargo_fuselage(hull, graphite, titanium, gold, glass)
    else:
        raise ValueError(part)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-dir", default="assets/blender")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    out_dir = os.path.abspath(args.out_dir)
    os.makedirs(out_dir, exist_ok=True)
    palette = [
        material("Orbital ceramic", (0.68, 0.77, 0.82), 0.42, 0.34),
        material("Graphite thermal coating", (0.075, 0.105, 0.14), 0.58, 0.31),
        material("Brushed titanium", (0.42, 0.52, 0.56), 0.78, 0.27),
        material("Safety gold", (0.93, 0.49, 0.12), 0.48, 0.32),
        material("Pressure glass", (0.035, 0.20, 0.30), 0.64, 0.16),
        material("Solar photovoltaic blue", (0.025, 0.10, 0.22), 0.28, 0.24),
    ]
    manifest = {"generator": "Blender procedural authored geometry", "units": "meters",
                "format": "glb", "parts": []}
    for part in PARTS:
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        build(part, palette)
        optimize_runtime_mesh(part)
        path = os.path.join(out_dir, part + ".glb")
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB",
                                   export_apply=True, export_yup=True)
        if not os.path.isfile(path) or os.path.getsize(path) < 1000:
            raise RuntimeError("Invalid or missing asset: " + path)
        manifest["parts"].append({"name": part, "file": os.path.basename(path),
                                  "bytes": os.path.getsize(path)})
        print("EXPORTED", path)
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print("GENERATED", len(manifest["parts"]), "detailed assets")


if __name__ == "__main__":
    main()
