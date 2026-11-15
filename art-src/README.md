# art-src

Sources for the pixel art in `assets/art/`. Shapes are drawn as round-brush canvas paths, then rendered at native pixel size with a fixed palette (`pixel/pixelate.js`). Floors are drawn directly in Python.

- `pixel/character_sprite.png` — the crewmate: a 34×49 hand-cleaned pixel sprite facing left, lit suit `#E42624`, suit shadow `#9C1730`. `pixel/character_key.py` mirrors it, swaps those two tones for the recolour keys and writes `assets/art/character/character.png` at 2×. The game animates it with a hop.
- `pixel/brand_art.py` — app icon, boot splash, HUD crew icon and `docs/og-image.png`, built from the sprite and the menu art.
- `character.html` — the old vector character, kept for reference; no longer exported.
- `props/<name>.js` — one prop each (some register several, e.g. wall pieces), sharing `props/prop.js`. Preview with `props/view.html?crate,bench`. Every prop file is exported automatically.
- `workstation.html` — the workstation sprite, exported by `pixel/export_workstation.sh`.
- `pixel/floor.py`, `pixel/room_floors.py`, `pixel/floor_decals.py` — the cafeteria floor tile, the other room floors, and the scattered floor details.
- `pixel/export_godot.sh` — regenerates the character, the floors, the props and the workstation into `assets/art/`.
- `map_preview.py` — renders the layout in `scripts/map/station_map.gd` to a PNG without running the game.

Setup: `python3 -m venv .venv && .venv/bin/pip install pillow numpy`. Run the Python scripts with `.venv/bin/python -I`.
