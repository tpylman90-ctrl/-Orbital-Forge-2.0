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

PARTS = ("command_pod", "fuel_tank", "rocket_engine", "station_ring")


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
