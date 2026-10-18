# Orbital Forge 2.0

A clean Godot 4.3 foundation for a discover-by-building Android spaceflight game.

## Vision
Build freely shaped spacecraft, learn spaceflight through optional bite-sized guidance, reach orbit, earn a permanent space station/deep-space shipyard unlock, and explore planetary systems through actual orbital mechanics.

## Engineering rules
- One persistent **craft document** is the source of truth for parts, transformations, connections, fuel links and staging.
- Parts have stable IDs rather than relying on list indices.
- The Earth VAB and orbital shipyard use the same editor, but distinct craft files and construction permissions.
- The orbital station is a **permanent unlock**, with no upkeep or repeated material taxes.
- Simulation, rendering, save logic and UI must be separate modules.
- Procedural, distinctive, lightweight 3D assets suited to Android.
- Brief optional teaching; experimentation always allowed.

## State
Initial foundation only. The editor, physics, orbital dock, missions and production APK are **not yet implemented** in this new repository. The original `tpylman90-ctrl/orbital-forge` stays intact as reference.

## Local development
Open `project.godot` in Godot 4.3. For a smoke test run:
```sh
godot --headless --script res://tests/craft_document_smoke.gd
```
