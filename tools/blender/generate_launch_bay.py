"""Generate Orbital Forge's cinematic, engineered Earth launch complex.

Run with Blender:
    blender --background --factory-startup --python tools/blender/generate_launch_bay.py -- --out-dir assets/blender

Scene coordinates are authored in game space (X east, Y up, Z north) and
converted to Blender's Z-up coordinates in the helper functions below.
"""
import argparse
import json
import os
import sys
from math import cos, pi, sin
from mathutils import Vector
import bpy


def game_pos(x, y, z):
    return (x, -z, y)


def game_size(x, y, z):
    return (x, z, y)


def mat(name, color, metallic=0.0, roughness=0.5, emission=None, strength=0.0):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1.0)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    if emission:
        emission_input = shader.inputs.get("Emission Color") or shader.inputs.get("Emission")
        if emission_input:
            emission_input.default_value = (*emission, 1.0)
        shader.inputs["Emission Strength"].default_value = strength
    return material


def finish(obj, name, material, bevel=0.0):
    obj.name = name
    obj.data.materials.append(material)
    if bevel:
        modifier = obj.modifiers.new("Soft manufactured edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.affect = "EDGES"
        normal = obj.modifiers.new("Weighted edge normals", "WEIGHTED_NORMAL")
        normal.keep_sharp = True
    return obj


def box(name, position, size, material, bevel=0.035, rotation=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=game_pos(*position))
    obj = bpy.context.object
    obj.dimensions = game_size(*size)
    obj.rotation_euler[2] = -rotation
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material, min(bevel, min(size) * 0.22) if bevel else 0.0)


def cylinder(name, position, radius, height, material, vertices=32, bevel=0.018):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=height,
                                       location=game_pos(*position))
    return finish(bpy.context.object, name, material, bevel)


def sphere(name, position, scale, material, vertices=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=vertices, ring_count=rings, radius=1,
                                        location=game_pos(*position))
    obj = bpy.context.object
    obj.scale = (scale[0], scale[2], scale[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material)


def beam(name, start, end, radius, material, vertices=10):
    a = Vector(game_pos(*start))
    b = Vector(game_pos(*end))
    delta = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius,
                                       depth=delta.length, location=(a + b) * 0.5)
    obj = bpy.context.object
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    return finish(obj, name, material, min(radius * 0.18, 0.012))


def ring(name, x, y, z, major, minor, material, segments=48):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments, minor_segments=10,
                                     major_radius=major, minor_radius=minor,
                                     location=game_pos(x, y, z))
    return finish(bpy.context.object, name, material)


def lamp(position, material):
    sphere("Sealed LED work lamp", position, (0.13, 0.09, 0.13), material, 16, 8)


def silo(x, z, radius, height, hull, dark, steel, amber, cyan):
    y = height / 2 + 0.12
    cylinder("Cryogenic vessel | insulated shell", (x, y, z), radius, height, hull, 40, 0.025)
    # Distinct crown and skirt assemblies, annular stiffeners, and bolted seams.
    sphere("Dished upper pressure head", (x, y + height / 2 - 0.03, z),
           (radius * 0.98, radius * 0.32, radius * 0.98), hull, 32, 12)
    cylinder("Lower skirt flange", (x, 0.42, z), radius * 1.11, 0.22, dark, 32)
    for h in (-height * 0.39, 0.0, height * 0.39):
        ring("Vessel circumferential band", x, y + h, z, radius * 1.005, 0.045, steel)
    cylinder("Crown access collar", (x, y + height * 0.52, z), radius * 0.28, 0.17, dark, 24)
    cylinder("Crown vent cap", (x, y + height * 0.61, z), radius * 0.17, 0.08, steel, 20)
    # External ladder and maintenance cage on the outward-facing side.
    ladder_x = x + radius * 0.82
    for side in (-1, 1):
        beam("Caged access ladder rail", (ladder_x + side * 0.16, 0.45, z + radius * 0.9),
             (ladder_x + side * 0.16, height - 0.2, z + radius * 0.9), 0.035, steel, 8)
    for step in range(1, int(height / 0.42)):
        yy = 0.48 + step * 0.42
        beam("Ladder rung", (ladder_x - 0.15, yy, z + radius * 0.9),
             (ladder_x + 0.15, yy, z + radius * 0.9), 0.026, amber, 8)
    # Two saddles, anchor feet, and a service box make each tank feel installed.
    for side in (-1, 1):
        box("Vessel support saddle", (x + side * radius * 0.62, 0.45, z),
            (radius * 0.38, 0.62, radius * 0.50), dark, 0.05)
        box("Saddle footing", (x + side * radius * 0.62, 0.14, z),
            (radius * 0.56, 0.20, radius * 0.68), steel, 0.025)
    box("Vessel instrument enclosure", (x - radius * 0.77, y, z + radius * 0.82),
        (radius * 0.42, height * 0.34, 0.16), dark, 0.04)
    box("Coolant status strip", (x - radius * 0.77, y + height * 0.08, z + radius * 0.91),
        (radius * 0.12, height * 0.12, 0.025), cyan, 0.008)
    cylinder("Tank perimeter service pad", (x, 0.025, z), radius * 1.42, 0.08, dark, 32)


def build():
    navy = mat("Basalt | blue-black", (0.035, 0.064, 0.091), 0.28, 0.72)
    concrete = mat("Launch deck | smoked concrete", (0.14, 0.19, 0.22), 0.12, 0.82)
    concrete_edge = mat("Cut concrete edge", (0.22, 0.28, 0.31), 0.2, 0.68)
    steel = mat("Gantry | satin titanium", (0.35, 0.46, 0.52), 0.72, 0.32)
    dark = mat("Gantry | thermal graphite", (0.045, 0.075, 0.096), 0.58, 0.34)
    ivory = mat("Panel | warm ceramic", (0.63, 0.70, 0.68), 0.24, 0.4)
    amber = mat("Safety | amber anodized", (0.90, 0.38, 0.095), 0.46, 0.36)
    yellow = mat("Safety | worn ochre paint", (0.88, 0.63, 0.20), 0.18, 0.58)
    cyan = mat("Cyan instrument light", (0.055, 0.45, 0.64), 0.2, 0.25,
               (0.055, 0.48, 0.82), 1.8)
    red = mat("Obstruction beacon", (0.7, 0.045, 0.025), 0.12, 0.3,
              (1.0, 0.035, 0.012), 2.2)
    glass = mat("Control room polarized glass", (0.025, 0.105, 0.15), 0.65, 0.2,
                (0.025, 0.16, 0.23), 0.22)
    tank = mat("Cryogenic white | satin enamel", (0.58, 0.69, 0.71), 0.42, 0.32)
    hose = mat("Propellant lines | warm titanium", (0.72, 0.48, 0.22), 0.68, 0.28)

    # The complex sits on a broad, beveled foundation and a scored central deck.
    box("Foundation | beveled perimeter slab", (0, -0.48, 0), (48, 0.72, 45), navy, 0.16)
    box("Launch apron | poured steel concrete", (0, -0.09, 0), (25, 0.16, 25), concrete, 0.08)
    box("Central launch island", (0, 0.025, 0), (9.2, 0.18, 9.2), concrete_edge, 0.055)
    box("Deck service core", (0, 0.16, 0), (5.2, 0.12, 5.2), dark, 0.04)
    box("Vehicle support platform", (0, 0.28, 0), (3.8, 0.28, 3.8), steel, 0.045)
    box("Clamping plate", (0, 0.435, 0), (3.25, 0.09, 3.25), dark, 0.025)

    # Panel joints, drainage slots, inspection covers, and restraining fittings.
    for edge in (-10.5, -7.0, -3.5, 3.5, 7.0, 10.5):
        box("Deck expansion joint", (edge, 0.002, 0), (0.026, 0.015, 21), dark, 0.004)
        box("Deck expansion joint", (0, 0.002, edge), (21, 0.015, 0.026), dark, 0.004)
    for x in (-7.4, 7.4):
        box("Deck edge hazard stripe", (x, 0.016, 0), (0.12, 0.025, 17.0), yellow, 0.012)
    for z in (-7.4, 7.4):
        box("Deck edge hazard stripe", (0, 0.016, z), (17.0, 0.025, 0.12), yellow, 0.012)
    for x in (-5.5, 5.5):
        for z in (-5.4, 5.4):
            box("Flush access hatch", (x, 0.025, z), (1.0, 0.035, 0.72), navy, 0.025)
            box("Hatch pull recess", (x, 0.047, z), (0.30, 0.018, 0.07), hose, 0.006)
    for x in (-1.65, 1.65):
        for z in (-1.65, 1.65):
            box("Hold-down actuator base", (x, 0.59, z), (0.62, 0.40, 0.62), dark, 0.055)
            cylinder("Clamp pivot housing", (x, 0.89, z), 0.19, 0.16, steel, 16)
            beam("Retractable hold-down arm", (x, 0.94, z), (x * 0.63, 1.13, z * 0.63),
                 0.11, amber, 10)
            box("Clamp jaw", (x * 0.62, 1.12, z * 0.62), (0.42, 0.14, 0.34), yellow, 0.03)

    # Deep heat shielded exhaust trench and a wide deflector throat behind the vehicle.
    box("Flame trench | foundation", (0, -0.18, -14.0), (8.8, 0.7, 16.0), dark, 0.10)
    box("Flame trench | refractory channel", (0, 0.05, -14.0), (5.6, 0.25, 15.8), navy, 0.045)
    box("Flame deflector armor plate", (0, -0.20, -8.15), (6.2, 0.38, 2.4), steel, 0.10, rotation=0.16)
    for side in (-1, 1):
        box("Trench armored wall", (side * 3.28, 0.38, -14.0), (0.30, 0.85, 15.4), concrete_edge, 0.06)
        box("Trench amber edge rail", (side * 3.28, 0.83, -14.0), (0.20, 0.08, 15.4), yellow, 0.025)
        for z in (-19, -16, -13, -10):
            box("Deflector drain louver", (side * 3.08, 0.48, z), (0.10, 0.08, 1.0), dark, 0.014)
    # Deluge mains are visible beneath the launch deck around the nozzle corridor.
    for x in (-3.6, 3.6):
        beam("Water deluge main", (x, 0.64, -2.7), (x, 0.64, -18.5), 0.12, steel, 16)
        for z in (-4, -7, -10, -13, -16):
            beam("Deluge spray drop", (x, 0.64, z), (x * 0.62, 0.20, z), 0.055, cyan, 8)

    # Main service gantry: deep box-section legs, cross bracing, decks and railings.
    tx = -7.1
    tower_z = 0.0
    for x in (tx - 2.3, tx + 2.3):
        for z in (-2.0, 2.0):
            box("Gantry main box column", (x, 10.3, tower_z + z), (0.52, 20.6, 0.56), steel, 0.07)
            for y in (1.4, 4.0, 6.6, 9.2, 11.8, 14.4, 17.0, 19.4):
                box("Column splice collar", (x, y, tower_z + z), (0.64, 0.18, 0.68), dark, 0.035)
    for y in (0.9, 3.4, 5.9, 8.4, 10.9, 13.4, 15.9, 18.4, 20.5):
        box("Gantry crossbeam | front", (tx, y, -2.0), (5.1, 0.36, 0.42), dark, 0.055)
        box("Gantry crossbeam | rear", (tx, y, 2.0), (5.1, 0.36, 0.42), dark, 0.055)
        box("Gantry crossbeam | side", (tx - 2.3, y, 0), (0.42, 0.36, 4.2), steel, 0.045)
        box("Gantry crossbeam | side", (tx + 2.3, y, 0), (0.42, 0.36, 4.2), steel, 0.045)
    for level in (3.4, 7.0, 10.6, 14.2, 17.8, 20.7):
        for side in (-1, 1):
            beam("Gantry diagonal brace", (tx - 2.3, level - 1.65, side * 2),
                 (tx + 2.3, level + 1.65, side * 2), 0.105, amber if level in (7.0, 17.8) else steel)
            beam("Gantry diagonal brace", (tx + 2.3, level - 1.65, side * 2),
                 (tx - 2.3, level + 1.65, side * 2), 0.105, steel)
        box("Full-width service floor", (tx, level, 0), (5.35, 0.18, 4.65), concrete_edge, 0.045)
        for side in (-1, 1):
            box("Walkway toe plate", (tx, level + 0.30, side * 2.27), (5.3, 0.13, 0.12), yellow, 0.025)
            for x in (tx - 2.45, tx - 1.65, tx - 0.82, tx, tx + 0.82, tx + 1.65, tx + 2.45):
                beam("Safety railing stanchion", (x, level + 0.18, side * 2.27),
                     (x, level + 0.82, side * 2.27), 0.035, amber, 8)
            for h in (level + 0.44, level + 0.78):
                beam("Safety railing tube", (tx - 2.65, h, side * 2.27),
                     (tx + 2.65, h, side * 2.27), 0.035, steel, 8)
    # Elevator bay and ladder live on the tower's outer face.
    box("Crew elevator cage", (tx - 2.78, 9.3, 0), (1.15, 3.0, 1.45), dark, 0.09)
    for level in (1.2, 4.8, 8.4, 12.0, 15.6, 19.2):
        box("Elevator landing bridge", (tx - 1.95, level, 0), (1.45, 0.16, 3.0), steel, 0.035)
    for z in (-2.18, 2.18):
        for y in range(1, 20):
            beam("Maintenance ladder rung", (tx - 2.62, float(y), z),
                 (tx - 2.28, float(y), z), 0.028, yellow, 8)

    # Retractable umbilical arms reach just short of the vehicle, with hose loops.
    for y in (4.0, 8.4, 12.8, 17.2):
        pivot = (tx + 2.5, y, 0)
        end = (-2.2, y, 0)
        beam("Service arm | structural boom", pivot, end, 0.16, steel, 12)
        beam("Service arm | lower tie", (tx + 2.5, y - 0.45, -0.4), (-2.7, y - 0.45, -0.4),
             0.075, dark, 10)
        for z in (-0.38, 0.38):
            beam("Umbilical transfer line", (tx + 2.5, y + 0.18, z), (-2.15, y + 0.18, z),
                 0.035, hose, 8)
        box("Service arm head", (-2.16, y, 0), (0.38, 0.55, 0.92), amber, 0.07)
        lamp((-2.2, y + 0.35, 0), cyan)
    # Cable tray and paired risers climb the rear face of the gantry.
    for z in (-1.45, 1.45):
        box("Gantry cable ladder", (tx - 2.12, 10.4, z), (0.18, 19.5, 0.26), dark, 0.035)
        for y in range(1, 20):
            box("Cable tray rung", (tx - 2.12, float(y), z), (0.25, 0.055, 0.34), steel, 0.014)
    for y in (1.0, 20.9):
        for x in (tx - 2.3, tx + 2.3):
            lamp((x, y, 0), red)

    # Tower crane head and lightning protection mast anchor the skyline.
    box("Gantry crown platform", (tx, 21.1, 0), (6.0, 0.46, 5.3), dark, 0.08)
    box("Crane crosshead", (tx + 0.5, 22.0, 0), (9.6, 0.32, 0.42), amber, 0.06)
    for x in (tx - 2.3, tx + 3.3):
        beam("Crane mast leg", (x, 21.2, 0), (x, 23.8, 0), 0.14, steel, 10)
    beam("Lightning mast", (tx, 21.3, 0), (tx, 26.0, 0), 0.055, steel, 8)
    for y in (23.5, 25.2):
        lamp((tx, y, 0), red)

    # Propellant farm at the east edge: varied scale, real silhouettes, pipe rack.
    farm = ((16.0, -9.0, 2.1, 9.0), (21.8, -9.0, 1.65, 7.0),
            (16.0, -2.6, 1.35, 5.7), (21.8, -2.6, 1.15, 5.0))
    for x, z, radius, height in farm:
        silo(x, z, radius, height, tank, dark, steel, amber, cyan)
    # Pipe bridge has clear supports and distinct feed lines to the tower base.
    for x in (12.5, 15.5, 18.5, 21.5, 24.5):
        box("Pipe-rack portal column", (x, 2.4, -5.6), (0.24, 4.8, 0.24), steel, 0.035)
        box("Pipe-rack crosshead", (x, 4.8, -5.6), (0.30, 0.24, 5.2), dark, 0.035)
    for y, material in ((4.6, hose), (4.15, steel), (3.7, cyan)):
        beam("Cryogenic distribution main", (12.5, y, -5.6), (24.5, y, -5.6), 0.11, material, 16)
    beam("Main umbilical trunk", (12.5, 3.7, -5.6), (4.3, 3.7, -5.6), 0.14, hose, 16)
    beam("Main umbilical riser", (4.3, 3.7, -5.6), (4.3, 3.7, -2.8), 0.14, hose, 16)
    for x, z, radius, height in farm:
        beam("Vessel transfer hose", (x - radius * 0.55, 2.0, z + radius * 0.9),
             (x - radius * 0.55, 3.7, -5.6), 0.065, hose, 10)

    # Blockhouse and instrument hall: layered walls, glazed control room and louvers.
    box("Launch control blockhouse", (12.5, 1.55, 8.0), (10.5, 3.1, 7.2), dark, 0.12)
    box("Control building ceramic facade", (12.5, 1.35, 7.2), (10.0, 2.45, 0.25), ivory, 0.05)
    box("Observation gallery canopy", (12.5, 3.05, 5.95), (11.0, 0.35, 2.3), steel, 0.07)
    for x in (9.0, 10.7, 12.4, 14.1, 15.8):
        box("Panoramic control glazing", (x, 2.1, 5.99), (1.36, 1.08, 0.09), glass, 0.025)
        box("Glazing divider", (x, 2.1, 5.92), (0.045, 1.25, 0.06), steel, 0.008)
    box("Operations entry", (12.5, 0.85, 4.33), (1.1, 1.7, 0.12), steel, 0.03)
    for x in (9.1, 10.0, 15.0, 15.9):
        for y in (0.68, 0.86, 1.04, 1.22, 1.40):
            box("Ventilation blade", (x, y, 4.36), (0.65, 0.055, 0.04), dark, 0.012)
    box("Control-room roof plant deck", (12.5, 3.33, 8.0), (8.7, 0.28, 5.4), concrete_edge, 0.06)
    for x in (10.0, 11.0, 14.0, 15.0):
        box("HVAC condenser unit", (x, 3.78, 8.0), (0.8, 0.62, 1.5), steel, 0.06)
        for z in (7.45, 7.75, 8.05, 8.35, 8.65):
            box("Condenser grille", (x, 3.8, z), (0.62, 0.035, 0.025), dark, 0.008)
    # Secondary maintenance workshop and loading bay.
    box("Integration workshop", (-16.0, 1.55, 8.5), (8.4, 3.1, 7.3), concrete_edge, 0.12)
    box("Workshop roof fascia", (-16.0, 3.2, 8.5), (9.0, 0.32, 7.8), ivory, 0.055)
    box("Workshop bay shutter", (-16.0, 1.45, 4.82), (3.1, 2.45, 0.09), dark, 0.04)
    for x in (-17.0, -16.0, -15.0):
        box("Bay door rib", (x, 1.45, 4.75), (0.06, 2.15, 0.05), steel, 0.01)
    for x in (-18.6, -13.4):
        lamp((x, 3.0, 4.7), amber)

    # Perimeter roads and lit taxi lanes give the whole facility a grounded footprint.
    box("Service roadway", (0, -0.015, 20.1), (38.0, 0.13, 7.8), navy, 0.06)
    for x in (-17.0, 17.0):
        box("Road edge | amber paint", (x, 0.06, 20.1), (0.11, 0.025, 7.2), yellow, 0.01)
    for z in (18.2, 22.0):
        box("Road lane | amber paint", (0, 0.06, z), (36, 0.025, 0.09), yellow, 0.01)
    for x in range(-14, 15, 4):
        box("Taxi lane center dash", (float(x), 0.065, 20.1), (1.7, 0.035, 0.15), ivory, 0.01)
    for x in (-18.5, 18.5):
        for z in (-12, -5, 4, 13, 22):
            box("Low perimeter bollard", (x, 0.47, z), (0.30, 0.92, 0.30), dark, 0.05)
            box("Bollard illuminated collar", (x, 0.78, z), (0.32, 0.12, 0.32), amber, 0.03)
            lamp((x, 1.02, z), cyan)

    # Tall service floodlights, each with a cantilever head and twin luminous panels.
    for x, z in ((-15.5, -12.0), (5.2, -15.0), (17.0, 12.0), (-17.5, 16.0)):
        beam("Floodlight mast", (x, 0.4, z), (x, 13.5, z), 0.13, steel, 10)
        beam("Floodlight cantilever", (x, 13.2, z), (x + (1.4 if x < 0 else -1.4), 13.2, z), 0.08, dark, 8)
        for i in range(3):
            lamp((x + (0.4 + i * 0.42 if x < 0 else -0.4 - i * 0.42), 13.0, z), cyan)
        lamp((x, 13.9, z), red)

    # Small rooftop antenna array and telemetry dish.
    beam("Telemetry mast", (16.0, 3.55, 10.0), (16.0, 7.2, 10.0), 0.045, steel, 8)
    for y in (4.2, 5.2, 6.2):
        box("Telemetry antenna crossbar", (16.0, y, 10.0), (1.35, 0.07, 0.08), amber, 0.012)
        sphere("Antenna end cap", (15.33, y, 10.0), (0.07, 0.07, 0.07), cyan, 12, 6)
    cylinder("Telemetry dish mount", (16.0, 5.3, 10.0), 0.16, 0.7, dark, 12)
    sphere("Telemetry dish reflector", (16.0, 5.9, 10.0), (0.95, 0.16, 0.95), ivory, 24, 8)
    cylinder("Dish feed horn", (16.0, 5.9, 9.25), 0.08, 0.35, amber, 12)

    return len(bpy.data.objects)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-dir", default="assets/blender")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    out = os.path.abspath(args.out_dir)
    os.makedirs(out, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    object_count = build()
    bpy.ops.object.select_all(action="SELECT")
    path = os.path.join(out, "launch_bay.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True)
    if not os.path.isfile(path) or os.path.getsize(path) < 20000:
        raise RuntimeError("Launch bay GLB did not export correctly")
    manifest = {"name": "Orbital Forge Earth Launch Complex", "generator": "Blender procedural authored geometry",
                "units": "meters", "format": "glb", "file": "launch_bay.glb",
                "objects": object_count, "bytes": os.path.getsize(path)}
    with open(os.path.join(out, "launch_bay_manifest.json"), "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
    print("EXPORTED", path, "objects", object_count, "bytes", os.path.getsize(path))


if __name__ == "__main__":
    main()
