# Qaxlok's Village: Godot vertical slice

The village level from the browser prototype, rebuilt in **Godot 4.3+**. Your map is in
`data/village.json`, exported straight from the prototype, so it has the same terrain, river,
houses, villagers, sheep, herbs, chests and shrines.

## Running it
1. Install Godot 4.3 or newer (the standard build, not .NET) on a Mac or PC.
2. In the Project Manager choose **Import**, pick this folder's `project.godot`, then press **Run** (F5).
3. Controls: WASD or arrows to walk, Space to press A, Q/E to turn the camera, mouse wheel to zoom.
   With a mouse, click-drag on the left side works as the joystick and on the right side to look around.

## Playing on the iPad (via itch.io)
The zip of this folder is the *source*. itch.io needs the *exported* game:
1. In Godot: Editor → Manage Export Templates → Download and Install (one time only).
2. Project → Export… → the **Web** preset is already set up (threads off, so it works in Safari) → **Export Project**
   into an empty folder. You get `index.html` plus `.js`, `.wasm` and `.pck` files.
3. Zip **the contents of that folder** (so `index.html` is at the top of the zip, not inside a subfolder).
4. On itch.io: Edit game → Kind of project: **HTML** → upload that zip → tick **This file will be played in the browser**.
   Set the viewport to 1280 × 720 and tick **Fullscreen button**. Leave "SharedArrayBuffer support" off.
5. Save, then open the draft's secret URL in Safari on the iPad.

The project uses the "Compatibility" renderer, which is the one that runs in browsers and on older iPads.
* **As an app:** Project → Export → **iOS** needs a Mac with Xcode and an Apple developer account.

## What's in the slice
* Terrain, river and ground colours built from your map. Every building, wall, fence, tree and prop is placed from it.
* Flat cel shading with soft light bands and an ink outline (`shaders/toon.gdshader`, `scripts/toon.gd`).
* Qaxlok with an on-screen joystick, drag-to-look and pinch-to-zoom, a follow camera that swings behind
  him, and the big A button.
* Talk to all 15 villagers (their prototype lines), Mend the broken pots and barrels, open chests,
  mend and light the two shrines, and pick up gems and herbs.
* Sheep and Winkle wander about. Villagers potter around their spots.
* Progress saves automatically (`user://save.json`).

Everything is a placeholder made from simple shapes until real models replace it.

## Your models (Nomad Sculpt → Godot)
Export from Nomad as **glTF (.glb)** with vertex colours, name it after the character
(`qaxlok.glb`, `chipper.glb`…), and drop it in `art/`. The game picks it up instead of the placeholder
and applies the toon shader, keeping your paint. See `art/PUT_MODELS_HERE.txt`.

## Files
| File | What it does |
|---|---|
| `scripts/main.gd` | Sets the scene up; pressing A; quests |
| `scripts/world.gd` | Builds terrain, water and all objects from the map |
| `scripts/props.gd` | Placeholder buildings and props |
| `scripts/gnome.gd` | Gnome bodies (placeholder or your .glb) with a walk bob |
| `scripts/player.gd` | Qaxlok's movement |
| `scripts/camera_rig.gd` | Follow camera |
| `scripts/ui.gd` | Joystick, A button, dialogue, toasts, quest list |
| `scripts/save.gd` | Input map and save file |
| `scripts/dialogue.gd` | What the villagers say |
