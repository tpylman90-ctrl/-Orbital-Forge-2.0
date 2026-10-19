"""Generate procedural, Godot-ready test assets for Orbital Forge 2.0.

Execute:
    blender --background --factory-startup --python tools/blender/generate_parts.py -- --out-dir build/blender
"""
import argparse
import json
import os
import sys
import bpy
from math import cos, sin, radians

PARTS = ("command_pod", "fuel_tank", "rocket_engine", "station_ring")

def mat(name, color, metallic=0.0):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = 0.45
    return material

def finish(obj, name, material, bevel=0):
    obj.name = name
    obj.data.materials.append(material)
    if bevel:
        modifier = obj.modifiers.new("Soft machined edges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        # Bevel provides the intended edge finish; weighted normals need extra setup in Blender 4.0.
    return obj

def cylinder(name, bottom_radius, top_radius, depth, z, material, vertices=32):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=bottom_radius,
                                    radius2=top_radius, depth=depth, location=(0, 0, z))
    return finish(bpy.context.object, name, material, 0.016)

def ring(name, radius, tube, z, material):
    bpy.ops.mesh.primitive_torus_add(major_segments=48, minor_segments=12,
                                     location=(0, 0, z), major_radius=radius,
                                     minor_radius=tube)
    return finish(bpy.context.object, name, material)

def box(name, xyz, location, material, rotation=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.dimensions = xyz
    obj.rotation_euler[2] = rotation
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material, 0.015)

def build(part, hull, dark, accent, glass):
    if part == "command_pod":
        cylinder("Pressurized cabin", 0.72, 0.64, 1.08, 0.0, hull)
        cylinder("Conical nose", 0.64, 0.16, 0.72, 0.90, hull)
        cylinder("Docking fitting", 0.23, 0.23, 0.15, 1.33, dark)
        cylinder("Bottom equipment plate", 0.76, 0.76, 0.13, -0.55, dark)
        ring("Cabin perimeter seam", 0.65, 0.025, 0.51, accent)
        cylinder("Forward glazing", 0.36, 0.23, 0.035, 1.27, glass)
    elif part == "fuel_tank":
        cylinder("Tank shell", 0.73, 0.73, 1.80, 0, hull)
        for z in (-0.81, 0.81):
            cylinder("Reinforced cap", 0.78, 0.78, 0.15, z, dark)
        for z in (-0.55, 0.0, 0.55):
            ring("Tank strengthening rib", 0.74, 0.025, z, accent)
        cylinder("Upper plumbing port", 0.35, 0.35, 0.15, 0.96, dark)
        cylinder("Lower plumbing port", 0.35, 0.35, 0.15, -0.96, dark)
    elif part == "rocket_engine":
        cylinder("Upper mounting flange", 0.45, 0.45, 0.20, 0.57, dark)
        cylinder("Combustion chamber", 0.38, 0.34, 0.56, 0.16, hull)
        cylinder("Expansion bell", 0.30, 0.73, 0.88, -0.54, dark, 48)
        ring("Bell exhaust rim", 0.73, 0.035, -0.97, accent)
        ring("Injector collar", 0.40, 0.035, 0.40, accent)
        for angle in range(0, 360, 90):
            a = radians(angle)
            box("External fuel feed", (0.09, 0.10, 0.54),
                (0.43*cos(a), 0.43*sin(a), 0.07), accent, a)
    elif part == "station_ring":
        ring("Orbital habitat torus", 1.20, 0.24, 0, hull)
        for angle in range(0, 360, 45):
            a = radians(angle)
            box("Radial spoke", (0.13, 1.08, 0.18),
                (0.62*cos(a), 0.62*sin(a), 0), dark, a-radians(90))
        cylinder("Central docking hub", 0.39, 0.39, 0.48, 0, dark)
        ring("Hub alignment stripe", 0.39, 0.025, 0.22, accent)
    else:
        raise ValueError(part)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-dir", default="build/blender")
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    out_dir = os.path.abspath(args.out_dir)
    os.makedirs(out_dir, exist_ok=True)
    manifest = {"generator": "Blender headless", "units": "meters",
                "format": "glb", "parts": []}
    for part in PARTS:
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete(use_global=False)
        hull = mat("Ceramic white", (0.72, 0.79, 0.84), 0.45)
        dark = mat("Graphite", (0.085, 0.105, 0.15), 0.55)
        accent = mat("Signal orange", (0.98, 0.32, 0.06), 0.25)
        glass = mat("Viewport cyan", (0.05, 0.50, 0.66), 0.18)
        build(part, hull, dark, accent, glass)
        path = os.path.join(out_dir, part + ".glb")
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB",
                                   export_apply=True, export_yup=True)
        if not os.path.isfile(path) or os.path.getsize(path) < 100:
            raise RuntimeError("Invalid or missing asset: " + path)
        manifest["parts"].append({"name": part, "file": os.path.basename(path),
                                   "bytes": os.path.getsize(path)})
        print("EXPORTED", path)
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print("GENERATED", len(manifest["parts"]), "assets")

if __name__ == "__main__":
    main()
